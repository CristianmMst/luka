"""Tests unitarios de `RecordCapturedTransaction` (spec 004 SS3/SS4, spec 006 SS4.3)."""

from dataclasses import replace
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from ledger.fakes import FixedClock, InMemoryTransactionRepo, build_ledger_repos
from luka.modules.ledger.application.dto import (
    CapturedTransactionCommand,
    Filters,
    SourceInput,
)
from luka.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from luka.modules.ledger.domain.entities import (
    Category,
    LinkedAccount,
    MerchantRule,
    Transaction,
)
from luka.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from luka.modules.ledger.domain.errors import CaptureAlreadyResolved
from luka.modules.ledger.domain.merchant import normalize_merchant
from luka.modules.ledger.domain.review import ReviewItem, ReviewReason, ReviewResolution
from luka.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID
from luka.modules.ledger.events import TransactionCaptured

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


def _cmd(  # noqa: PLR0913 - builder de comando con un default por campo
    *,
    bank: Bank = Bank.BANCOLOMBIA,
    amount: Decimal = Decimal("50000"),
    direction: Direction = Direction.DEBIT,
    occurred_at: datetime = NOW,
    last4: str | None = "1234",
    merchant: str | None = "EXITO BOGOTA",
    description: str | None = None,
    suggested_category_slug: str | None = None,
    parsed_by: str = "rule:bancolombia:debito",
    confidence: float | None = 0.9,
    source: SourceInput | None = None,
    merchant_is_person: bool = False,
) -> CapturedTransactionCommand:
    return CapturedTransactionCommand(
        user_id=USER,
        bank=bank,
        amount=amount,
        direction=direction,
        occurred_at=occurred_at,
        last4=last4,
        merchant=merchant,
        description=description,
        suggested_category_slug=suggested_category_slug,
        parsed_by=parsed_by,
        confidence=confidence,
        source=source or SourceInput(Channel.EMAIL, uuid4(), occurred_at),
        merchant_is_person=merchant_is_person,
    )


def _make_use_case(
    repos, *, transactions=None, clock: FixedClock | None = None
) -> RecordCapturedTransaction:
    return RecordCapturedTransaction(
        transactions=transactions or repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        merchant_rules=repos.merchant_rules,
        review_queue=repos.review_queue,
        owner_names=repos.owner_names,
        events=repos.events,
        clock=clock or FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )


class _RecordingTransactionRepo(InMemoryTransactionRepo):
    """Doble que registra `update` y `touch` (el touch no debe reescribir la fila)."""

    def __init__(self, sources) -> None:
        super().__init__(sources=sources)
        self.update_calls: list[Transaction] = []
        self.touch_calls: list[tuple[UUID, UUID, datetime]] = []

    async def update(self, tx: Transaction) -> None:
        self.update_calls.append(tx)
        await super().update(tx)

    async def touch(self, user_id: UUID, id: UUID, at: datetime) -> None:
        self.touch_calls.append((user_id, id, at))
        await super().touch(user_id, id, at)


@pytest.mark.unit
async def test_mismo_comando_dos_veces_produce_una_sola_transaccion_y_evento() -> None:
    """AC-5.2: reintentar exactamente el mismo comando no duplica nada."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    cmd = _cmd()

    first = await use_case.execute(cmd)
    second = await use_case.execute(cmd)

    assert first.created is True
    assert second.created is False
    assert second.transaction.id == first.transaction.id
    assert second.source_attached is False  # mismo raw_message_id: idempotente
    assert len(await repos.sources.list_for(first.transaction.id)) == 1
    assert len(repos.events.events) == 1
    assert isinstance(repos.events.events[0], TransactionCaptured)


@pytest.mark.unit
async def test_email_y_notificacion_de_la_misma_compra_agregan_una_segunda_fuente() -> None:
    """AC-5.1: mismos datos, +40s, `raw_message_id` distintos -> 1 tx, 2 fuentes."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    cmd_email = _cmd(source=SourceInput(Channel.EMAIL, uuid4(), NOW))
    later = NOW + timedelta(seconds=40)
    cmd_notification = _cmd(
        occurred_at=later, source=SourceInput(Channel.NOTIFICATION, uuid4(), later)
    )

    first = await use_case.execute(cmd_email)
    second = await use_case.execute(cmd_notification)

    assert first.created is True
    assert second.created is False
    assert second.transaction.id == first.transaction.id
    assert second.source_attached is True
    sources = await repos.sources.list_for(first.transaction.id)
    assert len(sources) == 2
    assert len(repos.events.events) == 1


@pytest.mark.unit
async def test_adjuntar_fuente_a_transaccion_existente_actualiza_updated_at() -> None:
    """Al adjuntar una segunda fuente a una tx existente, se toca `updated_at` (sync 005 SS9)."""
    repos = await build_ledger_repos()
    recording_repo = _RecordingTransactionRepo(repos.sources)
    clock = FixedClock(NOW)
    use_case = _make_use_case(repos, transactions=recording_repo, clock=clock)
    first = await use_case.execute(_cmd(source=SourceInput(Channel.EMAIL, uuid4(), NOW)))

    clock.advance(timedelta(seconds=40))
    later = NOW + timedelta(seconds=40)
    second = await use_case.execute(
        _cmd(occurred_at=later, source=SourceInput(Channel.NOTIFICATION, uuid4(), later))
    )

    assert second.source_attached is True
    # Solo `updated_at`: un `update` completo pisaria un PATCH concurrente.
    assert recording_repo.update_calls == []
    assert recording_repo.touch_calls == [(USER, first.transaction.id, clock.now())]
    assert second.transaction.updated_at == clock.now()
    stored = await recording_repo.get(USER, first.transaction.id)
    assert stored is not None
    assert stored.updated_at == clock.now()


@pytest.mark.unit
async def test_fuente_duplicada_en_transaccion_existente_no_toca_updated_at() -> None:
    """Reintentar el mismo `raw_message_id` no adjunta nada (`attached=False`): sin `update`."""
    repos = await build_ledger_repos()
    recording_repo = _RecordingTransactionRepo(repos.sources)
    clock = FixedClock(NOW)
    use_case = _make_use_case(repos, transactions=recording_repo, clock=clock)
    cmd = _cmd()

    await use_case.execute(cmd)
    clock.advance(timedelta(seconds=40))
    second = await use_case.execute(cmd)

    assert second.source_attached is False
    assert recording_repo.update_calls == []
    assert recording_repo.touch_calls == []


@pytest.mark.unit
async def test_mismo_monto_doce_minutos_despues_es_una_transaccion_distinta() -> None:
    """AC-5.3: fuera de la ventana de 10 min -> dos transacciones independientes."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    later = NOW + timedelta(minutes=12)
    cmd_first = _cmd(source=SourceInput(Channel.EMAIL, uuid4(), NOW))
    cmd_second = _cmd(occurred_at=later, source=SourceInput(Channel.EMAIL, uuid4(), later))

    first = await use_case.execute(cmd_first)
    second = await use_case.execute(cmd_second)

    assert first.created is True
    assert second.created is True
    assert first.transaction.id != second.transaction.id
    assert len(repos.events.events) == 2


@pytest.mark.unit
async def test_regla_de_comercio_aprendida_gana_sobre_la_sugerencia_del_parser() -> None:
    """AC-7.1 / spec 006 SS4.3: la regla aprendida tiene prioridad sobre el parser."""
    repos = await build_ledger_repos()
    custom_category = Category(
        id=uuid4(),
        user_id=USER,
        slug=None,
        name="Compras personales",
        icon=None,
        color=None,
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
    )
    await repos.categories.add(custom_category)
    await repos.merchant_rules.upsert(
        MerchantRule(
            id=uuid4(),
            user_id=USER,
            merchant_pattern=normalize_merchant("EXITO BOGOTA"),
            category_id=custom_category.id,
        )
    )
    use_case = _make_use_case(repos)
    cmd = _cmd(merchant="EXITO BOGOTA", suggested_category_slug="mercado")

    result = await use_case.execute(cmd)

    assert result.transaction.category_id == custom_category.id


@pytest.mark.unit
async def test_slug_sugerido_desconocido_cae_en_sin_categoria() -> None:
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    cmd = _cmd(merchant="COMERCIO NUEVO", suggested_category_slug="slug-inexistente")

    result = await use_case.execute(cmd)

    assert result.transaction.category_id == SIN_CATEGORIA_ID


async def _link_account(repos, *, bank: Bank, last4: str):
    account = LinkedAccount(
        id=uuid4(), user_id=USER, bank=bank, kind=AccountKind.SAVINGS, last4=last4, alias=None
    )
    await repos.accounts.add(account)
    return account


@pytest.mark.unit
async def test_debito_bancolombia_y_credito_nequi_del_mismo_monto_quedan_emparejados() -> None:
    """AC-6.1: dos capturas de cuentas propias, mismo monto y direccion opuesta -> pareja."""
    repos = await build_ledger_repos()
    await _link_account(repos, bank=Bank.BANCOLOMBIA, last4="1111")
    await _link_account(repos, bank=Bank.NEQUI, last4="2222")
    use_case = _make_use_case(repos)

    debit = await use_case.execute(
        _cmd(
            bank=Bank.BANCOLOMBIA,
            last4="1111",
            direction=Direction.DEBIT,
            merchant=None,
            description="Transferencia a Nequi",
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )
    credit = await use_case.execute(
        _cmd(
            bank=Bank.NEQUI,
            last4="2222",
            direction=Direction.CREDIT,
            merchant=None,
            description="Transferencia recibida",
            occurred_at=NOW + timedelta(minutes=5),
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW + timedelta(minutes=5)),
        )
    )

    refreshed_debit = await repos.transactions.get(USER, debit.transaction.id)
    assert refreshed_debit is not None
    assert refreshed_debit.kind == Kind.TRANSFER
    assert refreshed_debit.transfer_auto is True
    assert refreshed_debit.transfer_pair_id == credit.transaction.id

    assert credit.transaction.kind == Kind.TRANSFER
    assert credit.transaction.transfer_auto is True
    assert credit.transaction.transfer_pair_id == debit.transaction.id


@pytest.mark.unit
async def test_tercer_candidato_ambiguo_no_empareja_a_nadie() -> None:
    """AC-6.2: mas de un candidato posible -> nadie queda emparejado."""
    repos = await build_ledger_repos()
    await _link_account(repos, bank=Bank.BANCOLOMBIA, last4="1111")
    await _link_account(repos, bank=Bank.DAVIVIENDA, last4="3333")
    await _link_account(repos, bank=Bank.NEQUI, last4="2222")
    use_case = _make_use_case(repos)

    debit_a = await use_case.execute(
        _cmd(
            bank=Bank.BANCOLOMBIA,
            last4="1111",
            direction=Direction.DEBIT,
            merchant=None,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )
    debit_b = await use_case.execute(
        _cmd(
            bank=Bank.DAVIVIENDA,
            last4="3333",
            direction=Direction.DEBIT,
            merchant=None,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )
    credit = await use_case.execute(
        _cmd(
            bank=Bank.NEQUI,
            last4="2222",
            direction=Direction.CREDIT,
            merchant=None,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )

    assert credit.transaction.transfer_pair_id is None
    assert credit.transaction.kind != Kind.TRANSFER
    refreshed_a = await repos.transactions.get(USER, debit_a.transaction.id)
    refreshed_b = await repos.transactions.get(USER, debit_b.transaction.id)
    assert refreshed_a is not None
    assert refreshed_b is not None
    assert refreshed_a.transfer_pair_id is None
    assert refreshed_b.transfer_pair_id is None


class _RaceTransactionRepo(_RecordingTransactionRepo):
    """Simula una carrera: la primera insercion "gana" en otro proceso, no en este."""

    def __init__(self, sources) -> None:
        super().__init__(sources=sources)
        self._first_call = True

    async def insert_if_absent(self, tx) -> UUID | None:
        if self._first_call:
            self._first_call = False
            await super().insert_if_absent(tx)
            return None
        return await super().insert_if_absent(tx)


@pytest.mark.unit
async def test_carrera_de_insercion_adjunta_la_fuente_a_la_fila_existente() -> None:
    repos = await build_ledger_repos()
    race_repo = _RaceTransactionRepo(repos.sources)
    use_case = _make_use_case(repos, transactions=race_repo)

    result = await use_case.execute(_cmd())

    assert result.created is False
    assert result.source_attached is True
    assert len(repos.events.events) == 0
    assert race_repo.update_calls == []
    assert race_repo.touch_calls == [(USER, result.transaction.id, NOW)]


# --- Cierre de la revision al reparsear (spec 005 SS7) ----------------------------


def _open_review_item(raw_message_id: UUID) -> ReviewItem:
    return ReviewItem(
        raw_message_id=raw_message_id,
        user_id=USER,
        reason=ReviewReason.NO_TEMPLATE,
        partial_extract={},
        created_at=NOW - timedelta(days=2),
        resolved_at=None,
        resolution=None,
    )


@pytest.mark.unit
async def test_captura_de_un_mensaje_en_revision_cierra_el_item_como_reparsed() -> None:
    repos = await build_ledger_repos()
    raw_message_id = uuid4()
    await repos.review_queue.insert_if_absent(_open_review_item(raw_message_id))

    recorded = await _make_use_case(repos).execute(
        _cmd(source=SourceInput(Channel.EMAIL, raw_message_id, NOW))
    )

    assert recorded.created is True
    item = await repos.review_queue.get(USER, raw_message_id)
    assert item is not None
    assert item.resolution is ReviewResolution.REPARSED
    assert item.resolved_at == NOW
    assert await repos.review_queue.list_open(USER, None, 10) == []


@pytest.mark.unit
async def test_reparse_que_cae_en_dedupe_tambien_cierra_el_item() -> None:
    """La transaccion ya existia (p. ej. llego tambien por notificacion): se adjunta
    la fuente y el item de revision igual se cierra.
    """
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    await use_case.execute(_cmd(source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW)))
    raw_message_id = uuid4()
    await repos.review_queue.insert_if_absent(_open_review_item(raw_message_id))

    recorded = await use_case.execute(_cmd(source=SourceInput(Channel.EMAIL, raw_message_id, NOW)))

    assert recorded.created is False
    item = await repos.review_queue.get(USER, raw_message_id)
    assert item is not None
    assert item.resolution is ReviewResolution.REPARSED


@pytest.mark.parametrize("resolution", [ReviewResolution.CONVERTED, ReviewResolution.DISCARDED])
@pytest.mark.unit
async def test_item_ya_resuelto_por_el_usuario_no_registra_otra_transaccion(
    resolution: ReviewResolution,
) -> None:
    """Carrera reparse vs. convert/discard (spec 006 SS4.4): el usuario resolvio el
    item mientras el mensaje reprocesado seguia en el pipeline. La captura no crea
    una segunda transaccion (la convertida usa un `dedupe_key` manual aleatorio y el
    dedupe no la veria), no publica nada y el item conserva su resolucion.
    """
    repos = await build_ledger_repos()
    raw_message_id = uuid4()
    await repos.review_queue.insert_if_absent(_open_review_item(raw_message_id))
    await repos.review_queue.resolve(USER, raw_message_id, resolution, NOW - timedelta(days=1))

    with pytest.raises(CaptureAlreadyResolved):
        await _make_use_case(repos).execute(
            _cmd(source=SourceInput(Channel.EMAIL, raw_message_id, NOW))
        )

    assert await repos.transactions.list(USER, Filters(), None, 10) == []
    assert repos.events.events == []
    item = await repos.review_queue.get(USER, raw_message_id)
    assert item is not None
    assert item.resolution is resolution
    assert item.resolved_at == NOW - timedelta(days=1)


@pytest.mark.unit
async def test_item_ya_reparsed_no_bloquea_la_captura_repetida() -> None:
    """Una reentrega del mismo `TransactionParsed` tras cerrar el item como
    `reparsed` sigue el camino normal de dedupe (no es una resolucion del usuario).
    """
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    raw_message_id = uuid4()
    await repos.review_queue.insert_if_absent(_open_review_item(raw_message_id))
    cmd = _cmd(source=SourceInput(Channel.EMAIL, raw_message_id, NOW))

    first = await use_case.execute(cmd)
    second = await use_case.execute(cmd)

    assert first.created is True
    assert second.created is False
    assert second.transaction.id == first.transaction.id


@pytest.mark.unit
class TestSelfTransfer:
    """Transferencias propias por nombre del titular (spec 004 SS4.1)."""

    async def test_envio_a_nombre_del_titular_es_transferencia(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[USER] = "Cristian Steve Mora Moreno"
        result = await _make_use_case(repos).execute(
            _cmd(merchant="CRISTIAN MORA", merchant_is_person=True, last4=None)
        )

        tx = result.transaction
        assert tx.kind == Kind.TRANSFER
        assert tx.fiscal_tag == FiscalTag.TRANSFERENCIA
        assert tx.transfer_pair_id is None
        (event,) = [e for e in repos.events.events if isinstance(e, TransactionCaptured)]
        assert event.kind == Kind.TRANSFER

    async def test_recibo_del_titular_desde_otro_banco_es_transferencia(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[USER] = "Cristian Mora"
        result = await _make_use_case(repos).execute(
            _cmd(
                bank=Bank.NEQUI,
                direction=Direction.CREDIT,
                merchant="Cristian Steve Mora Moreno",
                merchant_is_person=True,
                last4=None,
            )
        )
        assert result.transaction.kind == Kind.TRANSFER

    async def test_envio_a_otra_persona_sigue_siendo_gasto(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[USER] = "Cristian Mora"
        result = await _make_use_case(repos).execute(
            _cmd(merchant="Alejandro Herrera Feria", merchant_is_person=True)
        )
        assert result.transaction.kind == Kind.EXPENSE

    async def test_comercio_con_el_nombre_del_titular_no_cuenta(self) -> None:
        # Una compra (merchant no es persona) nunca es transferencia propia.
        repos = await build_ledger_repos()
        repos.owner_names.names[USER] = "Cristian Mora"
        result = await _make_use_case(repos).execute(_cmd(merchant="CRISTIAN MORA"))
        assert result.transaction.kind == Kind.EXPENSE

    async def test_sin_nombre_del_titular_no_marca(self) -> None:
        repos = await build_ledger_repos()
        result = await _make_use_case(repos).execute(
            _cmd(merchant="CRISTIAN MORA", merchant_is_person=True)
        )
        assert result.transaction.kind == Kind.EXPENSE


def _transfer(
    name: str | None,
    *,
    minutes: int = 0,
    channel: Channel = Channel.EMAIL,
    raw_id: UUID | None = None,
) -> CapturedTransactionCommand:
    """Recibo Bre-B de $7.100 de `name` a la cuenta *8761, `minutes` despues de NOW."""
    at = NOW + timedelta(minutes=minutes)
    return _cmd(
        amount=Decimal("7100"),
        direction=Direction.CREDIT,
        occurred_at=at,
        last4="8761",
        merchant=name,
        parsed_by="rule:bancolombia:transferencia_llave_recibida:v1",
        confidence=None,
        source=SourceInput(channel, raw_id or uuid4(), at),
        merchant_is_person=True,
    )


@pytest.mark.unit
async def test_tres_amigos_que_envian_el_mismo_monto_a_la_vez_son_tres_movimientos() -> None:
    """Mismo monto, cuenta y ventana pero contrapartes distintas: no hay dedupe
    (spec 004 SS3). Antes se fusionaban en uno solo."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)

    results = [
        await use_case.execute(_transfer("MANUEL NIETO")),
        await use_case.execute(_transfer("TOMAS ALEJANDRO RODRIGUEZ COLMENARES", minutes=2)),
        await use_case.execute(_transfer("MARIANA GOMEZ ABRIL", minutes=2)),
    ]

    assert all(r.created for r in results)
    assert len({r.transaction.id for r in results}) == 3
    assert [r.transaction.merchant for r in results] == [
        "MANUEL NIETO",
        "TOMAS ALEJANDRO RODRIGUEZ COLMENARES",
        "MARIANA GOMEZ ABRIL",
    ]
    assert len({r.transaction.dedupe_key for r in results}) == 3


@pytest.mark.unit
async def test_notificacion_de_una_transferencia_se_une_a_su_correo_y_no_a_otra() -> None:
    """La notificacion de Mariana encuentra el movimiento de Mariana aunque
    Manuel haya llegado primero y tenga la clave base."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    await use_case.execute(_transfer("MANUEL NIETO"))
    mariana = await use_case.execute(_transfer("MARIANA GOMEZ ABRIL", minutes=1))

    notification = await use_case.execute(
        _transfer("MARIANA GOMEZ", minutes=1, channel=Channel.NOTIFICATION)
    )

    assert notification.created is False
    assert notification.transaction.id == mariana.transaction.id
    assert len(await repos.sources.list_for(mariana.transaction.id)) == 2


@pytest.mark.unit
async def test_captura_entre_personas_sin_nombre_se_une_como_antes() -> None:
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    first = await use_case.execute(_transfer("MANUEL NIETO"))

    second = await use_case.execute(_transfer(None, minutes=1, channel=Channel.NOTIFICATION))

    assert second.created is False
    assert second.transaction.id == first.transaction.id


@pytest.mark.unit
async def test_reentrega_del_mismo_mensaje_tras_editar_el_comercio_no_duplica() -> None:
    """Si el usuario renombro la contraparte, reprocesar el mismo `raw_message`
    devuelve su movimiento: la fuente ya adjunta manda sobre el nombre."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    raw_id = uuid4()
    first = await use_case.execute(_transfer("MANUEL NIETO", raw_id=raw_id))
    await repos.transactions.update(replace(first.transaction, merchant="Manuel Sua"))

    again = await use_case.execute(_transfer("MANUEL NIETO", raw_id=raw_id))

    assert again.created is False
    assert again.transaction.id == first.transaction.id
    assert again.source_attached is False


@pytest.mark.unit
async def test_compras_en_comercios_distintos_con_el_mismo_monto_siguen_uniendose() -> None:
    """La regla de contraparte es solo para capturas entre personas: una compra
    por correo y por notificacion puede traer el comercio escrito distinto."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    first = await use_case.execute(_cmd(merchant="KS*PAGSEGURO CO"))
    later = NOW + timedelta(seconds=30)
    second = await use_case.execute(
        _cmd(
            merchant="PAGSEGURO",
            occurred_at=later,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), later),
        )
    )

    assert second.created is False
    assert second.transaction.id == first.transaction.id
