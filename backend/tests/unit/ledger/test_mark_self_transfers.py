"""Tests unitarios de `MarkSelfTransfers` (spec 004 SS4.1)."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from finanzia.modules.ledger.application.dto import CapturedTransactionCommand, SourceInput
from finanzia.modules.ledger.application.use_cases.mark_self_transfers import MarkSelfTransfers
from finanzia.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from finanzia.modules.ledger.domain.entities import Transaction
from finanzia.modules.ledger.domain.enums import Bank, Channel, Direction, FiscalTag, Kind
from ledger.fakes import FixedClock, LedgerRepos, build_ledger_repos

NOW = datetime(2026, 9, 28, 12, 0, tzinfo=UTC)
LATER = NOW + timedelta(days=1)
ANA = uuid4()
BEA = uuid4()
PERSON = frozenset({"rule:bancolombia:transferencia_llave:v1"})


async def _capture(
    repos: LedgerRepos,
    *,
    user_id: UUID = ANA,
    merchant: str = "ANA PEREZ",
    parsed_by: str = "rule:bancolombia:transferencia_llave:v1",
    amount: str = "128283",
) -> Transaction:
    """Una captura vieja: sin `merchant_is_person`, como antes de esta regla."""
    use_case = RecordCapturedTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        merchant_rules=repos.merchant_rules,
        review_queue=repos.review_queue,
        owner_names=repos.owner_names,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )
    result = await use_case.execute(
        CapturedTransactionCommand(
            user_id=user_id,
            bank=Bank.BANCOLOMBIA,
            amount=Decimal(amount),
            direction=Direction.DEBIT,
            occurred_at=NOW,
            last4=None,
            merchant=merchant,
            description=None,
            suggested_category_slug=None,
            parsed_by=parsed_by,
            confidence=None,
            source=SourceInput(Channel.EMAIL, uuid4(), NOW),
        )
    )
    return result.transaction


def _use_case(repos: LedgerRepos) -> MarkSelfTransfers:
    return MarkSelfTransfers(
        transactions=repos.transactions,
        owner_names=repos.owner_names,
        clock=FixedClock(LATER),
        uow=repos.uow,
    )


@pytest.mark.unit
class TestMarkSelfTransfers:
    async def test_marca_las_del_titular_y_deja_las_de_otras_personas(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[ANA] = "Ana Maria Perez Gomez"
        own = await _capture(repos)
        other = await _capture(repos, merchant="Alejandro Herrera Feria", amount="8000")

        summary = await _use_case(repos).execute(person_parsed_by=PERSON, user_id=None)

        assert (summary.marked, summary.skipped_edited) == (1, 0)
        marked = await repos.transactions.get(ANA, own.id)
        assert marked is not None
        assert marked.kind == Kind.TRANSFER
        assert marked.fiscal_tag == FiscalTag.TRANSFERENCIA
        assert marked.updated_at == LATER
        untouched = await repos.transactions.get(ANA, other.id)
        assert untouched is not None
        assert untouched.kind == Kind.EXPENSE

    async def test_respeta_las_editadas_a_mano(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[ANA] = "Ana Perez"
        tx = await _capture(repos)
        await repos.transactions.touch(ANA, tx.id, NOW + timedelta(hours=1))

        summary = await _use_case(repos).execute(person_parsed_by=PERSON, user_id=None)

        assert (summary.marked, summary.skipped_edited) == (0, 1)
        again = await repos.transactions.get(ANA, tx.id)
        assert again is not None
        assert again.kind == Kind.EXPENSE

    async def test_solo_plantillas_entre_personas(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[ANA] = "Ana Perez"
        await _capture(repos, parsed_by="rule:bancolombia:compra_tdeb:v1")

        summary = await _use_case(repos).execute(person_parsed_by=PERSON, user_id=None)

        assert summary.marked == 0

    async def test_cada_usuario_con_su_nombre_y_filtro_por_usuario(self) -> None:
        repos = await build_ledger_repos()
        repos.owner_names.names[ANA] = "Ana Perez"
        repos.owner_names.names[BEA] = "Beatriz Rojas"
        await _capture(repos, user_id=ANA)
        await _capture(repos, user_id=BEA, merchant="BEATRIZ ROJAS", amount="5000")
        # Bea le manda a Ana: para Bea no es propia.
        await _capture(repos, user_id=BEA, merchant="ANA PEREZ", amount="7000")

        only_bea = await _use_case(repos).execute(person_parsed_by=PERSON, user_id=BEA)
        assert only_bea.marked == 1

        rest = await _use_case(repos).execute(person_parsed_by=PERSON, user_id=None)
        assert rest.marked == 1

    async def test_sin_nombre_del_titular_no_marca_nada(self) -> None:
        repos = await build_ledger_repos()
        await _capture(repos)

        summary = await _use_case(repos).execute(person_parsed_by=PERSON, user_id=None)

        assert summary.marked == 0
