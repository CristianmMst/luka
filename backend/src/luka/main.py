"""Punto de entrada ASGI: `uvicorn luka.main:app`."""

from luka.app import create_app

app = create_app()
