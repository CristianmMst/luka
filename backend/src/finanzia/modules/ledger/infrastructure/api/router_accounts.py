"""Router HTTP de ledger: `/accounts` (spec 005 SS7, controller ruling 4)."""

from uuid import UUID

from fastapi import APIRouter, Depends, status

from finanzia.modules.ledger.application.dto import UNSET, AccountInput, AccountPatch
from finanzia.modules.ledger.application.use_cases.create_account import CreateAccount
from finanzia.modules.ledger.application.use_cases.delete_account import DeleteAccount
from finanzia.modules.ledger.application.use_cases.list_accounts import ListAccounts
from finanzia.modules.ledger.application.use_cases.update_account import UpdateAccount
from finanzia.modules.ledger.infrastructure.api.deps import (
    get_create_account_use_case,
    get_current_user_id,
    get_delete_account_use_case,
    get_list_accounts_use_case,
    get_update_account_use_case,
)
from finanzia.modules.ledger.infrastructure.api.patch_utils import resolve_required_patch_field
from finanzia.modules.ledger.infrastructure.api.presenters import account_response
from finanzia.modules.ledger.infrastructure.api.schemas import (
    AccountResponse,
    CreateAccountRequest,
    PatchAccountRequest,
)

router = APIRouter(tags=["ledger"], dependencies=[Depends(get_current_user_id)])


@router.get("/accounts")
async def list_accounts(
    user_id: UUID = Depends(get_current_user_id),
    use_case: ListAccounts = Depends(get_list_accounts_use_case),
) -> list[AccountResponse]:
    """Cuentas vinculadas propias del usuario (spec 005 SS7)."""
    accounts = await use_case.execute(user_id)
    return [account_response(account) for account in accounts]


@router.post("/accounts", status_code=status.HTTP_201_CREATED)
async def create_account(
    body: CreateAccountRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: CreateAccount = Depends(get_create_account_use_case),
) -> AccountResponse:
    """Vincula una cuenta propia; `(bank, last4)` duplicado -> 409 (spec 005 SS7)."""
    input_ = AccountInput(bank=body.bank, kind=body.kind, last4=body.last4, alias=body.alias)
    account = await use_case.execute(user_id, input_)
    return account_response(account)


@router.patch("/accounts/{id}")
async def patch_account(
    id: UUID,
    body: PatchAccountRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: UpdateAccount = Depends(get_update_account_use_case),
) -> AccountResponse:
    """Edita `kind`/`last4`/`alias` de una cuenta propia (el banco no es editable)."""
    fields = body.model_fields_set
    patch = AccountPatch(
        kind=resolve_required_patch_field(body.kind, present="kind" in fields, field="kind"),
        last4=body.last4 if "last4" in fields else UNSET,
        alias=body.alias if "alias" in fields else UNSET,
    )
    account = await use_case.execute(user_id, id, patch)
    return account_response(account)


@router.delete("/accounts/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: DeleteAccount = Depends(get_delete_account_use_case),
) -> None:
    """Desvincula una cuenta propia; sus transacciones quedan con `account_id` NULL."""
    await use_case.execute(user_id, id)
