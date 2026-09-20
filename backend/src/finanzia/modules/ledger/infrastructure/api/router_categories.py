"""Router HTTP de ledger: `/categories` (spec 005 SS7, controller ruling 4)."""

from uuid import UUID

from fastapi import APIRouter, Depends, status

from finanzia.modules.ledger.application.dto import UNSET, CategoryInput, CategoryPatch
from finanzia.modules.ledger.application.use_cases.create_category import CreateCategory
from finanzia.modules.ledger.application.use_cases.delete_category import DeleteCategory
from finanzia.modules.ledger.application.use_cases.list_categories import ListCategories
from finanzia.modules.ledger.application.use_cases.update_category import UpdateCategory
from finanzia.modules.ledger.infrastructure.api.deps import (
    get_create_category_use_case,
    get_current_user_id,
    get_delete_category_use_case,
    get_list_categories_use_case,
    get_update_category_use_case,
)
from finanzia.modules.ledger.infrastructure.api.patch_utils import resolve_required_patch_field
from finanzia.modules.ledger.infrastructure.api.presenters import category_response
from finanzia.modules.ledger.infrastructure.api.schemas import (
    CategoryResponse,
    CreateCategoryRequest,
    PatchCategoryRequest,
)

router = APIRouter(tags=["ledger"], dependencies=[Depends(get_current_user_id)])


@router.get("/categories")
async def list_categories(
    user_id: UUID = Depends(get_current_user_id),
    use_case: ListCategories = Depends(get_list_categories_use_case),
) -> list[CategoryResponse]:
    """Categorias del sistema y propias, visibles para el usuario (spec 005 SS7)."""
    categories = await use_case.execute(user_id)
    return [category_response(category) for category in categories]


@router.post("/categories", status_code=status.HTTP_201_CREATED)
async def create_category(
    body: CreateCategoryRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: CreateCategory = Depends(get_create_category_use_case),
) -> CategoryResponse:
    """Crea una categoria propia; nombre duplicado -> 409 (spec 005 SS7)."""
    input_ = CategoryInput(
        name=body.name, icon=body.icon, color=body.color, fiscal_tag=body.fiscal_tag
    )
    category = await use_case.execute(user_id, input_)
    return category_response(category)


@router.patch("/categories/{id}")
async def patch_category(
    id: UUID,
    body: PatchCategoryRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: UpdateCategory = Depends(get_update_category_use_case),
) -> CategoryResponse:
    """Edita una categoria propia; las del sistema son inmutables (403)."""
    fields = body.model_fields_set
    patch = CategoryPatch(
        name=resolve_required_patch_field(body.name, present="name" in fields, field="name"),
        icon=body.icon if "icon" in fields else UNSET,
        color=body.color if "color" in fields else UNSET,
        fiscal_tag=resolve_required_patch_field(
            body.fiscal_tag, present="fiscal_tag" in fields, field="fiscal_tag"
        ),
    )
    category = await use_case.execute(user_id, id, patch)
    return category_response(category)


@router.delete("/categories/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: DeleteCategory = Depends(get_delete_category_use_case),
) -> None:
    """Borra una categoria propia; reasigna sus transacciones a `sin_categoria`."""
    await use_case.execute(user_id, id)
