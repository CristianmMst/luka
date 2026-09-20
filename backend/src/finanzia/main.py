"""Punto de entrada ASGI: `uvicorn finanzia.main:app`."""

from finanzia.app import create_app

app = create_app()
