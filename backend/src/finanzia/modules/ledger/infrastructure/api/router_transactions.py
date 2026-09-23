"""Router HTTP de ledger: `/transactions` (spec 005 SS6, controller ruling 4).

Delgado a proposito: cada endpoint arma el comando/filtro, llama al caso de uso
obtenido via `deps.py` y traduce el resultado con `presenters.py`.
"""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from finanzia.modules.ledger.application.dto import UNSET as DTO_UNSET
from finanzia.modules.ledger.application.dto import (
    Cursor,
    Filters,
    ManualTransactionCommand,
    TransactionDetail,
    TransactionPatch,
)
from finanzia.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from finanzia.modules.ledger.application.use_cases.delete_transaction import DeleteTransaction
from finanzia.modules.ledger.application.use_cases.get_transaction import GetTransaction
from finanzia.modules.ledger.application.use_cases.list_transactions import ListTransactions
from finanzia.modules.ledger.application.use_cases.set_transfer_pair import SetTransferPair
from finanzia.modules.ledger.application.use_cases.unset_transfer_pair import UnsetTransferPair
from finanzia.modules.ledger.application.use_cases.update_transaction import UpdateTransaction
from finanzia.modules.ledger.domain.entities import Transaction
from finanzia.modules.ledger.domain.enums import Bank, Channel, Kind
from finanzia.modules.ledger.infrastructure.api.deps import (
    get_create_manual_transaction_use_case,
    get_current_user_id,
    get_delete_transaction_use_case,
    get_get_transaction_use_case,
    get_list_transactions_use_case,
    get_set_transfer_pair_use_case,
    get_unset_transfer_pair_use_case,
    get_update_transaction_use_case,
)
from finanzia.modules.ledger.infrastructure.api.patch_utils import resolve_required_patch_field
from finanzia.modules.ledger.infrastructure.api.presenters import (
    transaction_list_item,
    transaction_response,
)
from finanzia.modules.ledger.infrastructure.api.schemas import (
    CreateTransactionRequest,
    PatchTransactionRequest,
    TransactionListItem,
    TransactionResponse,
    TransferPairRequest,
)
from finanzia.shared.http.pagination import (
    CursorKind,
    Page,
    PageParams,
    decode_cursor,
    encode_cursor,
    page_params,
)

router = APIRouter(tags=["ledger"], dependencies=[Depends(get_current_user_id)])


async def _build_response(
    tx: Transaction, get_transaction: GetTransaction, user_id: UUID
) -> TransactionResponse:
    """Recarga `tx` con sus fuentes y pareja para devolver el recurso completo (spec 005 SS9.3)."""
    detail = await get_transaction.execute(user_id, tx.id)
    return transaction_response(detail)


@router.get("/transactions")
async def list_transactions(  # noqa: PLR0913, PLR0917 - un parametro por filtro de query (spec 005 SS6)
    page: PageParams = Depends(page_params),
    from_: datetime | None = Query(None, alias="from"),
    to: datetime | None = Query(None),
    kind: Kind | None = Query(None),
    category_id: UUID | None = Query(None),
    bank: Bank | None = Query(None),
    account_id: UUID | None = Query(None),
    channel: Channel | None = Query(None),
    q: str | None = Query(None, max_length=100),
    updated_since: datetime | None = Query(None),
    user_id: UUID = Depends(get_current_user_id),
    use_case: ListTransactions = Depends(get_list_transactions_use_case),
) -> Page[TransactionListItem]:
    """Lista transacciones propias, paginadas por cursor (spec 005 SS1/SS6).

    Los items NO incluyen `sources`/`pair` (esos solo se exponen en
    `GET /transactions/{id}`): una unica consulta al repositorio arma toda la
    pagina, sin el N+1 de recargar cada fila (RNF-3, p95 < 300 ms).
    """
    expected_kind: CursorKind = "updated" if updated_since is not None else "occurred"
    cursor: Cursor | None = None
    if page.cursor is not None:
        sort_key, cursor_id = decode_cursor(page.cursor, expected_kind)
        cursor = Cursor(sort_key=sort_key, id=cursor_id)

    filters = Filters(
        from_=from_,
        to=to,
        kind=kind,
        category_id=category_id,
        bank=bank,
        account_id=account_id,
        channel=channel,
        q=q,
        updated_since=updated_since,
    )
    result = await use_case.execute(user_id, filters, cursor, page.limit)
    items = [transaction_list_item(tx, result.channels.get(tx.id, [])) for tx in result.items]
    next_cursor = None
    if result.next_cursor is not None:
        next_cursor = encode_cursor(
            result.next_cursor.sort_key, result.next_cursor.id, expected_kind
        )
    return Page[TransactionListItem](items=items, next_cursor=next_cursor)


@router.post("/transactions", status_code=status.HTTP_201_CREATED)
async def create_transaction(
    body: CreateTransactionRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: CreateManualTransaction = Depends(get_create_manual_transaction_use_case),
    get_transaction: GetTransaction = Depends(get_get_transaction_use_case),
) -> TransactionResponse:
    """Registra una transaccion manual (spec 005 SS6)."""
    channel = Channel.NFC if body.nfc_tag_id else Channel.MANUAL
    cmd = ManualTransactionCommand(
        user_id=user_id,
        amount=Decimal(body.amount),
        direction=body.direction,
        occurred_at=body.occurred_at,
        category_id=body.category_id,
        merchant=body.merchant,
        description=body.description,
        account_id=body.account_id,
        notes=body.notes,
        channel=channel,
        kind=body.kind,
    )
    tx = await use_case.execute(cmd)
    return await _build_response(tx, get_transaction, user_id)


@router.get("/transactions/{id}")
async def get_transaction_endpoint(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: GetTransaction = Depends(get_get_transaction_use_case),
) -> TransactionResponse:
    """Detalle de una transaccion propia, con sus fuentes y pareja (spec 005 SS6)."""
    detail: TransactionDetail = await use_case.execute(user_id, id)
    return transaction_response(detail)


@router.patch("/transactions/{id}")
async def patch_transaction(
    id: UUID,
    body: PatchTransactionRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: UpdateTransaction = Depends(get_update_transaction_use_case),
    get_transaction: GetTransaction = Depends(get_get_transaction_use_case),
) -> TransactionResponse:
    """Aplica un PATCH parcial (spec 005 SS6; `learn_merchant_rule` por defecto true)."""
    fields = body.model_fields_set
    patch = TransactionPatch(
        category_id=resolve_required_patch_field(
            body.category_id, present="category_id" in fields, field="category_id"
        ),
        notes=body.notes if "notes" in fields else DTO_UNSET,
        merchant=body.merchant if "merchant" in fields else DTO_UNSET,
        kind=resolve_required_patch_field(body.kind, present="kind" in fields, field="kind"),
        learn_merchant_rule=body.learn_merchant_rule,
    )
    tx = await use_case.execute(user_id, id, patch)
    return await _build_response(tx, get_transaction, user_id)


@router.delete("/transactions/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: DeleteTransaction = Depends(get_delete_transaction_use_case),
) -> None:
    """Borra una transaccion manual propia (spec 005 SS6; 403 si no es manual)."""
    await use_case.execute(user_id, id)


@router.post("/transactions/{id}/transfer-pair")
async def set_transfer_pair(
    id: UUID,
    body: TransferPairRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: SetTransferPair = Depends(get_set_transfer_pair_use_case),
) -> TransactionResponse:
    """Empareja manualmente `id` con `body.pair_id` como transferencia (spec 005 SS6)."""
    detail = await use_case.execute(user_id, id, body.pair_id)
    return transaction_response(detail)


@router.delete("/transactions/{id}/transfer-pair")
async def unset_transfer_pair(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: UnsetTransferPair = Depends(get_unset_transfer_pair_use_case),
) -> TransactionResponse:
    """Deshace el emparejamiento de `id` (spec 005 SS6, AC-6.3)."""
    detail = await use_case.execute(user_id, id)
    return transaction_response(detail)
