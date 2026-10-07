"""Tests de integracion del esquema de ledger: migracion 0002 (spec 004 SS2.4-2.9,
seed de categorias del sistema SS2.8.1, F1.5).

Sin repos de dominio todavia (ese trabajo llega en tareas futuras): estos tests
ejercitan directamente las tablas via SQL, igual que `test_migrations.py`.
"""

from uuid import UUID, uuid4

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.raw_messages import insert_raw_message

from luka.modules.ledger.domain.system_categories import (
    SIN_CATEGORIA_ID,
    SYSTEM_CATEGORIES,
)

pytestmark = pytest.mark.integration


async def _insert_user(session: AsyncSession, *, sub: str, email: str) -> UUID:
    result = await session.execute(
        text("INSERT INTO users (google_sub, email) VALUES (:sub, :email) RETURNING id"),
        {"sub": sub, "email": email},
    )
    return result.scalar_one()


async def _insert_transaction(
    session: AsyncSession, *, user_id: UUID, dedupe_key: str, **overrides: object
) -> UUID:
    """Inserta una transaccion minima valida; `overrides` pisa los defaults.

    Claves aceptadas en `overrides`: `category_id`, `account_id`, `amount`,
    `fiscal_tag` (todas opcionales, ver `params` abajo).
    """
    params: dict[str, object] = {
        "user_id": user_id,
        "dedupe_key": dedupe_key,
        "category_id": SIN_CATEGORIA_ID,
        "account_id": None,
        "amount": "10000.00",
        "fiscal_tag": "no_deducible",
    }
    params.update(overrides)

    result = await session.execute(
        text(
            "INSERT INTO transactions "
            "(user_id, amount, direction, kind, occurred_at, account_id, category_id, "
            " fiscal_tag, dedupe_key, parsed_by) "
            "VALUES "
            "(:user_id, :amount, 'debit', 'expense', now(), :account_id, :category_id, "
            " :fiscal_tag, :dedupe_key, 'manual') "
            "RETURNING id"
        ),
        params,
    )
    return result.scalar_one()


async def test_seed_veinticuatro_categorias_del_sistema(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        result = await session.execute(
            text("SELECT id, slug, fiscal_tag FROM categories WHERE user_id IS NULL ORDER BY name")
        )
        filas = {(row.id, row.slug, row.fiscal_tag) for row in result}

    assert len(filas) == 24
    esperadas = {
        (categoria.id, categoria.slug, categoria.fiscal_tag.value)
        for categoria in SYSTEM_CATEGORIES
    }
    assert filas == esperadas


async def test_categoria_de_sistema_duplicada_por_nombre_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO categories (user_id, slug, name, fiscal_tag) "
                    "VALUES (NULL, 'mercado_duplicado', 'Mercado y supermercado', "
                    "'no_deducible')"
                )
            )
            await session.commit()


async def test_categoria_de_usuario_con_slug_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-cat-slug", email="cat-slug@example.com")
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO categories (user_id, slug, name, fiscal_tag) "
                    "VALUES (:user_id, 'no_deberia_tener_slug', 'Categoria de usuario', "
                    "'no_deducible')"
                ),
                {"user_id": user_id},
            )
            await session.commit()


async def test_amount_no_positivo_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-amount", email="amount@example.com")
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await _insert_transaction(
                session, user_id=user_id, dedupe_key="dedupe-amount", amount="0.00"
            )
            await session.commit()


async def test_dedupe_key_duplicado_por_usuario_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-dedupe", email="dedupe@example.com")
        await session.commit()

    async with session_factory() as session:
        await _insert_transaction(session, user_id=user_id, dedupe_key="dedupe-repetida")
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await _insert_transaction(session, user_id=user_id, dedupe_key="dedupe-repetida")
            await session.commit()


async def test_fiscal_tag_invalido_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-fiscal", email="fiscal@example.com")
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await _insert_transaction(
                session,
                user_id=user_id,
                dedupe_key="dedupe-fiscal-invalido",
                fiscal_tag="no_existe",
            )
            await session.commit()


async def test_dos_cuentas_mismo_banco_sin_last4_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-cuentas", email="cuentas@example.com")
        await session.commit()

    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO linked_accounts (user_id, bank, kind, last4) "
                "VALUES (:user_id, 'nequi', 'wallet', NULL)"
            ),
            {"user_id": user_id},
        )
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO linked_accounts (user_id, bank, kind, last4) "
                    "VALUES (:user_id, 'nequi', 'wallet', NULL)"
                ),
                {"user_id": user_id},
            )
            await session.commit()


async def test_last4_no_numerico_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-last4", email="last4@example.com")
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO linked_accounts (user_id, bank, kind, last4) "
                    "VALUES (:user_id, 'nequi', 'wallet', '12a4')"
                ),
                {"user_id": user_id},
            )
            await session.commit()


async def test_borrar_usuario_encascada_transacciones_cuentas_y_reglas(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-cascada-led", email="cascada-led@example.com"
        )
        account_id = (
            await session.execute(
                text(
                    "INSERT INTO linked_accounts (user_id, bank, kind, last4) "
                    "VALUES (:user_id, 'bancolombia', 'savings', '1234') RETURNING id"
                ),
                {"user_id": user_id},
            )
        ).scalar_one()
        await session.execute(
            text(
                "INSERT INTO merchant_rules (user_id, merchant_pattern, category_id) "
                "VALUES (:user_id, 'rappi', :category_id)"
            ),
            {"user_id": user_id, "category_id": SIN_CATEGORIA_ID},
        )
        # Categoria del sistema: nunca se borra al eliminar el usuario, evita el
        # conflicto de orden entre el CASCADE de `categories.user_id` y el
        # RESTRICT de `transactions.category_id`.
        await _insert_transaction(
            session,
            user_id=user_id,
            dedupe_key="dedupe-cascada",
            account_id=account_id,
        )
        await session.commit()

    async with session_factory() as session:
        await session.execute(text("DELETE FROM users WHERE id = :id"), {"id": user_id})
        await session.commit()

    async with session_factory() as session:
        cuentas = (
            await session.execute(
                text("SELECT count(*) FROM linked_accounts WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()
        transacciones = (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()
        reglas = (
            await session.execute(
                text("SELECT count(*) FROM merchant_rules WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()

    assert (cuentas, transacciones, reglas) == (0, 0, 0)


async def test_borrar_cuenta_vinculada_pone_null_en_transacciones(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-set-null", email="set-null@example.com")
        account_id = (
            await session.execute(
                text(
                    "INSERT INTO linked_accounts (user_id, bank, kind, last4) "
                    "VALUES (:user_id, 'davivienda', 'checking', '5678') RETURNING id"
                ),
                {"user_id": user_id},
            )
        ).scalar_one()
        transaction_id = await _insert_transaction(
            session,
            user_id=user_id,
            dedupe_key="dedupe-set-null",
            account_id=account_id,
        )
        await session.commit()

    async with session_factory() as session:
        await session.execute(
            text("DELETE FROM linked_accounts WHERE id = :id"), {"id": account_id}
        )
        await session.commit()

    async with session_factory() as session:
        cuenta_de_la_transaccion = (
            await session.execute(
                text("SELECT account_id FROM transactions WHERE id = :id"),
                {"id": transaction_id},
            )
        ).scalar_one()

    assert cuenta_de_la_transaccion is None


async def test_borrar_categoria_referenciada_por_transaccion_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-restrict", email="restrict@example.com")
        await _insert_transaction(
            session,
            user_id=user_id,
            dedupe_key="dedupe-restrict",
            category_id=SIN_CATEGORIA_ID,
        )
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text("DELETE FROM categories WHERE id = :id"), {"id": SIN_CATEGORIA_ID}
            )
            await session.commit()


async def test_dos_transaction_sources_mismo_raw_message_id_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-sources", email="sources@example.com")
        transaction_id = await _insert_transaction(
            session, user_id=user_id, dedupe_key="dedupe-sources"
        )
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user_id)
    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO transaction_sources "
                "(transaction_id, raw_message_id, channel, received_at) "
                "VALUES (:transaction_id, :raw_message_id, 'email', now())"
            ),
            {"transaction_id": transaction_id, "raw_message_id": raw_message_id},
        )
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO transaction_sources "
                    "(transaction_id, raw_message_id, channel, received_at) "
                    "VALUES (:transaction_id, :raw_message_id, 'email', now())"
                ),
                {"transaction_id": transaction_id, "raw_message_id": raw_message_id},
            )
            await session.commit()


async def test_dos_transaction_sources_con_raw_message_id_null_estan_permitidas(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-sources-null", email="sources-null@example.com"
        )
        transaction_id = await _insert_transaction(
            session, user_id=user_id, dedupe_key="dedupe-sources-null"
        )
        await session.commit()

    async with session_factory() as session:
        for channel in ("manual", "manual"):
            await session.execute(
                text(
                    "INSERT INTO transaction_sources "
                    "(transaction_id, raw_message_id, channel, received_at) "
                    "VALUES (:transaction_id, NULL, :channel, now())"
                ),
                {"transaction_id": transaction_id, "channel": channel},
            )
        await session.commit()

    async with session_factory() as session:
        cantidad = (
            await session.execute(
                text(
                    "SELECT count(*) FROM transaction_sources "
                    "WHERE transaction_id = :id AND raw_message_id IS NULL"
                ),
                {"id": transaction_id},
            )
        ).scalar_one()

    assert cantidad == 2


async def test_catalogo_de_indices_de_transactions(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        result = await session.execute(
            text("SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'transactions'")
        )
        indices = {row.indexname: row.indexdef for row in result}

    assert "uq_transactions_user_id_dedupe_key" in indices
    assert "UNIQUE" in indices["uq_transactions_user_id_dedupe_key"]
    assert "ix_transactions_user_id_occurred_at_id" in indices


async def test_transaction_sources_raw_message_id_inexistente_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-fk-raw", email="fk-raw@example.com")
        transaction_id = await _insert_transaction(
            session, user_id=user_id, dedupe_key="dedupe-fk-raw"
        )
        await session.commit()

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO transaction_sources "
                    "(transaction_id, raw_message_id, channel, received_at) "
                    "VALUES (:transaction_id, :raw_message_id, 'email', now())"
                ),
                {"transaction_id": transaction_id, "raw_message_id": uuid4()},
            )
            await session.commit()


async def test_borrar_raw_message_pone_null_en_transaction_sources_y_sobrevive_la_fuente(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-raw-set-null", email="raw-set-null@example.com"
        )
        transaction_id = await _insert_transaction(
            session, user_id=user_id, dedupe_key="dedupe-raw-set-null"
        )
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user_id)
    async with session_factory() as session:
        source_id = (
            await session.execute(
                text(
                    "INSERT INTO transaction_sources "
                    "(transaction_id, raw_message_id, channel, received_at) "
                    "VALUES (:transaction_id, :raw_message_id, 'email', now()) RETURNING id"
                ),
                {"transaction_id": transaction_id, "raw_message_id": raw_message_id},
            )
        ).scalar_one()
        await session.commit()

    async with session_factory() as session:
        await session.execute(
            text("DELETE FROM raw_messages WHERE id = :id"), {"id": raw_message_id}
        )
        await session.commit()

    async with session_factory() as session:
        fila = (
            await session.execute(
                text("SELECT raw_message_id FROM transaction_sources WHERE id = :id"),
                {"id": source_id},
            )
        ).one()

    assert fila.raw_message_id is None


async def test_review_queue_resolution_sin_resolved_at_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-review-consist", email="review-consist@example.com"
        )
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user_id)

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO review_queue "
                    "(raw_message_id, user_id, reason, resolution) "
                    "VALUES (:raw_message_id, :user_id, 'no_template', 'converted')"
                ),
                {"raw_message_id": raw_message_id, "user_id": user_id},
            )
            await session.commit()


async def test_review_queue_reason_invalido_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-review-reason", email="review-reason@example.com"
        )
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user_id)

    with pytest.raises(IntegrityError):
        async with session_factory() as session:
            await session.execute(
                text(
                    "INSERT INTO review_queue (raw_message_id, user_id, reason) "
                    "VALUES (:raw_message_id, :user_id, 'razon_inexistente')"
                ),
                {"raw_message_id": raw_message_id, "user_id": user_id},
            )
            await session.commit()


async def test_borrar_usuario_encascada_raw_messages_y_review_queue(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-cascada-review", email="cascada-review@example.com"
        )
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user_id)
    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO review_queue (raw_message_id, user_id, reason) "
                "VALUES (:raw_message_id, :user_id, 'no_template')"
            ),
            {"raw_message_id": raw_message_id, "user_id": user_id},
        )
        await session.commit()

    async with session_factory() as session:
        await session.execute(text("DELETE FROM users WHERE id = :id"), {"id": user_id})
        await session.commit()

    async with session_factory() as session:
        mensajes = (
            await session.execute(
                text("SELECT count(*) FROM raw_messages WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()
        cola = (
            await session.execute(
                text("SELECT count(*) FROM review_queue WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()

    assert (mensajes, cola) == (0, 0)


async def test_catalogo_de_constraints_e_indices_de_raw_messages_y_review_queue(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        constraints_transaction_sources = (
            await session.execute(
                text(
                    "SELECT conname FROM pg_constraint "
                    "WHERE conrelid = 'transaction_sources'::regclass"
                )
            )
        ).scalars()
        constraints_review_queue = (
            await session.execute(
                text("SELECT conname FROM pg_constraint WHERE conrelid = 'review_queue'::regclass")
            )
        ).scalars()
        result = await session.execute(
            text("SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'review_queue'")
        )
        indices_review_queue = {row.indexname: row.indexdef for row in result}

    assert "fk_transaction_sources_raw_message_id_raw_messages" in set(
        constraints_transaction_sources
    )
    assert {"pk_review_queue", "ck_review_queue_resolucion_consistente"} <= set(
        constraints_review_queue
    )
    assert "ix_review_queue_user_id_created_at_raw_message_id" in indices_review_queue
    assert (
        "WHERE (resolved_at IS NULL)"
        in indices_review_queue["ix_review_queue_user_id_created_at_raw_message_id"]
    )


async def test_db_clean_setup_inserta_una_fila_en_review_queue(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    """Precondicion del siguiente test: `db_clean` debe dejar `review_queue` vacia."""
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-db-clean-review", email="db-clean-review@example.com"
        )
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user_id)
    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO review_queue (raw_message_id, user_id, reason) "
                "VALUES (:raw_message_id, :user_id, 'no_template')"
            ),
            {"raw_message_id": raw_message_id, "user_id": user_id},
        )
        await session.commit()

        cantidad = (await session.execute(text("SELECT count(*) FROM review_queue"))).scalar_one()

    assert cantidad == 1


async def test_db_clean_dejo_review_queue_vacia(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    """`_tablas_y_redis_limpias` (autouse) corrio antes de este test (Task 1/F2.1)."""
    async with session_factory() as session:
        cantidad = (await session.execute(text("SELECT count(*) FROM review_queue"))).scalar_one()

    assert cantidad == 0
