package co.finanzia.finanzia.capture

const val CHANNEL_NOTIFICATION = "notification"
const val CHANNEL_SMS = "sms_notification"

/** Límites de `POST /v1/ingest/notifications`; el backend igual trunca el cuerpo a 8 KB. */
const val MAX_TITLE = 500
const val MAX_TEXT = 8192

/** Paquetes y remitentes soportados, espejo de `GET /v1/config/capture` (spec 006 §3.1). */
class CaptureConfig private constructor(
    val bankingApps: Set<String>,
    val messagesApps: Set<String>,
    val senderPatterns: List<Regex>,
) {
    companion object {
        val EMPTY = CaptureConfig(emptySet(), emptySet(), emptyList())

        /** Un patrón que no compila se salta: no debe tumbar la captura de los demás. */
        fun of(
            bankingApps: List<String>,
            messagesApps: List<String>,
            smsSenderPatterns: List<String>,
        ) = CaptureConfig(
            bankingApps.toSet(),
            messagesApps.toSet(),
            smsSenderPatterns.mapNotNull { runCatching { Regex(it) }.getOrNull() },
        )
    }
}

data class Captured(val channel: String, val title: String?, val text: String)

/**
 * Decide si una notificación se captura (spec 006 §3.2). Lo que no pasa no se
 * guarda ni se envía; en SMS de otro remitente ni siquiera se lee el texto
 * (AC-3.3), por eso [capture] recibe el texto como función.
 */
class CaptureFilter(private val config: CaptureConfig) {
    fun capture(packageName: String, title: String?, readText: () -> String?): Captured? {
        val channel = when (packageName) {
            in config.bankingApps -> CHANNEL_NOTIFICATION
            in config.messagesApps -> {
                // El título de la notificación de Mensajes es el remitente del SMS.
                if (title.isNullOrBlank() || config.senderPatterns.none { it.containsMatchIn(title) }) {
                    return null
                }
                CHANNEL_SMS
            }
            else -> return null
        }
        val text = readText()?.trim()
        if (text.isNullOrEmpty() || !AMOUNT.containsMatchIn(text)) return null
        return Captured(channel, title?.take(MAX_TITLE), text.take(MAX_TEXT))
    }

    private companion object {
        /** Pre-filtro barato: signo de moneda, `COP` o cifra con separador de miles. */
        val AMOUNT = Regex("""\$|\bCOP\b|\d{1,3}(?:[.,]\d{3})+""")
    }
}
