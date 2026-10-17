"""Корневой роутер API версии 1."""

from fastapi import APIRouter

from app.api.v1.assessment import router as assessment_router
from app.api.v1.auth import router as auth_router
from app.api.v1.exercises import router as exercises_router
from app.api.v1.progress import router as progress_router


router = APIRouter(prefix="/api/v1")
router.include_router(auth_router)
router.include_router(exercises_router)
router.include_router(assessment_router)
router.include_router(progress_router)
