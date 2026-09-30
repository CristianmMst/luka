"""Router HTTP de ledger: `/review` (spec 005 SS7, D1, controller ruling 4).

Delgado, mismo patron que `router_transactions.py`: cada endpoint arma el
comando, llama al caso de uso obtenido via `deps.py` y traduce el resultado
con `presenters.py`.
"""

from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, status

from luka.modules.ledger.application.dto import ConvertReviewCommand, Cursor
from luka.modules.ledger.application.use_cases.convert_review_item import ConvertReviewItem
from luka.modules.ledger.application.use_cases.discard_review_item import DiscardReviewItem
from luka.modules.ledger.application.use_cases.list_review import ListReview
from luka.modules.ledger.infrastructure.api.deps import (
    get_convert_review_item_use_case,
    get_current_user_id,
    get_discard_review_item_use_case,
    get_list_review_use_case,
)
from luka.modules.ledger.infrastructure.api.presenters import (
    discard_review_response,
    review_entry_response,
    transaction_response,
)
from luka.modules.ledger.infrastructure.api.schemas import (
    ConvertReviewRequest,
    DiscardReviewResponse,
    ReviewEntryResponse,
    TransactionResponse,
)
from luka.shared.http.pagination import (
    CursorKind,
    Page,
    PageParams,
    decode_cursor,
    encode_cursor,
    page_params,
)

router = APIRouter(tags=["ledger"], dependencies=[Depends(get_current_user_id)])

_CURSOR_KIND: CursorKind = "review"


@router.get("/review")
async def list_review(
    page: PageParams = Depends(page_params),
    user_id: UUID = Depends(get_current_user_id),
    use_case: ListReview = Depends(get_list_review_use_case),
) -> Page[ReviewEntryResponse]:
    """Cola de revision del usuario, paginada por cursor (spec 005 SS1/SS7)."""
    cursor: Cursor | None = None
    if page.cursor is not None:
        sort_key, cursor_id = decode_cursor(page.cursor, _CURSOR_KIND)
        cursor = Cursor(sort_key=sort_key, id=cursor_id)

    result = await use_case.execute(user_id, cursor, page.limit)
    items = [
        response
        for response in (review_entry_response(entry) for entry in result.items)
        if response is not None
    ]
    next_cursor = None
    if result.next_cursor is not None:
        next_cursor = encode_cursor(
            result.next_cursor.sort_key, result.next_cursor.id, _CURSOR_KIND
        )
    return Page[ReviewEntryResponse](items=items, next_cursor=next_cursor)


@router.post("/review/{raw_message_id}/convert", status_code=status.HTTP_201_CREATED)
async def convert_review(
    raw_message_id: UUID,
    body: ConvertReviewRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: ConvertReviewItem = Depends(get_convert_review_item_use_case),
) -> TransactionResponse:
    """Convierte un item de revision en una transaccion manual (spec 005 SS7, AC-9.3)."""
    cmd = ConvertReviewCommand(
        user_id=user_id,
        raw_message_id=raw_message_id,
        amount=Decimal(body.amount),
        direction=body.direction,
        occurred_at=body.occurred_at,
        category_id=body.category_id,
        merchant=body.merchant,
        description=body.description,
        account_id=body.account_id,
        notes=body.notes,
        kind=body.kind,
    )
    detail = await use_case.execute(cmd)
    return transaction_response(detail)


@router.post("/review/{raw_message_id}/discard")
async def discard_review(
    raw_message_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: DiscardReviewItem = Depends(get_discard_review_item_use_case),
) -> DiscardReviewResponse:
    """Descarta un item de revision sin crear transaccion (spec 005 SS7)."""
    item = await use_case.execute(user_id, raw_message_id)
    return discard_review_response(item)
