"""Valores de test para los settings de Google que no tienen default.

Los client ID y la configuracion de Pub/Sub dependen del proyecto GCP de cada
entorno, asi que `Settings` los exige; aqui van valores ficticios, nunca los
del proyecto real.
"""

from support.oidc import PUSH_AUDIENCE, PUSH_SERVICE_ACCOUNT

TEST_GOOGLE_CLIENT_ID = "test-client"
TEST_GOOGLE_IOS_CLIENT_ID = "test-ios-client"
TEST_GMAIL_PUBSUB_TOPIC = "projects/test-project/topics/gmail-push"

#: Argumentos para `Settings(...)`.
GOOGLE_SETTINGS: dict[str, str] = {
    "google_client_id": TEST_GOOGLE_CLIENT_ID,
    "google_ios_client_id": TEST_GOOGLE_IOS_CLIENT_ID,
    "gmail_pubsub_topic": TEST_GMAIL_PUBSUB_TOPIC,
    "gmail_push_audience": PUSH_AUDIENCE,
    "gmail_push_service_account": PUSH_SERVICE_ACCOUNT,
}

#: Las mismas, como variables de entorno `LUKA_*`.
GOOGLE_ENV: dict[str, str] = {f"LUKA_{k.upper()}": v for k, v in GOOGLE_SETTINGS.items()}
