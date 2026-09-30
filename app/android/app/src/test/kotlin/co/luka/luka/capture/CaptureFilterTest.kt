package co.luka.luka.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

class CaptureFilterTest {
    private val config = CaptureConfig.of(
        bankingApps = listOf("com.bancolombia.app", "com.nequi.MobileApp"),
        messagesApps = listOf("com.google.android.apps.messaging"),
        smsSenderPatterns = listOf("(?i)bancolombia", "(?i)bancodebogota|banco de bogota"),
    )
    private val filter = CaptureFilter(config)

    @Test
    fun `app bancaria con monto se captura como notification`() {
        val captured = filter.capture(
            packageName = "com.bancolombia.app",
            title = "Bancolombia",
            readText = { "Compraste \$12.000 en EXITO" },
        )
        assertEquals(
            Captured(CHANNEL_NOTIFICATION, "Bancolombia", "Compraste \$12.000 en EXITO"),
            captured,
        )
    }

    @Test
    fun `paquete no soportado se ignora sin leer el texto`() {
        var read = false
        val captured = filter.capture("com.whatsapp", "Mamá") { read = true; "hola \$5.000" }
        assertNull(captured)
        assertFalse(read)
    }

    @Test
    fun `sms de remitente bancario se captura con el remitente como titulo`() {
        val captured = filter.capture(
            packageName = "com.google.android.apps.messaging",
            title = "BANCOLOMBIA",
            readText = { "Bancolombia: Transferiste \$50.000" },
        )
        assertEquals(
            Captured(CHANNEL_SMS, "BANCOLOMBIA", "Bancolombia: Transferiste \$50.000"),
            captured,
        )
    }

    @Test
    fun `patron con alternativa y espacios`() {
        val captured = filter.capture("com.google.android.apps.messaging", "Banco de Bogota") {
            "Pago por COP 30.000"
        }
        assertEquals(CHANNEL_SMS, captured?.channel)
    }

    @Test
    fun `sms de otro remitente se ignora sin leer el texto (AC-3_3)`() {
        var read = false
        val captured = filter.capture("com.google.android.apps.messaging", "Juan") {
            read = true
            "me debes \$20.000"
        }
        assertNull(captured)
        assertFalse(read)
    }

    @Test
    fun `sms sin titulo se ignora`() {
        assertNull(filter.capture("com.google.android.apps.messaging", null) { "\$1.000" })
    }

    @Test
    fun `sin monto se ignora`() {
        assertNull(filter.capture("com.nequi.MobileApp", "Nequi") { "Tu clave cambió" })
        assertNull(filter.capture("com.nequi.MobileApp", "Nequi") { "Código 123456" })
        assertNull(filter.capture("com.nequi.MobileApp", "Nequi") { null })
        assertNull(filter.capture("com.nequi.MobileApp", "Nequi") { "   " })
    }

    @Test
    fun `montos reconocidos por el pre-filtro`() {
        for (text in listOf("Pagaste \$8.500", "Valor COP 45000", "Recibiste 1.250.000 de Ana", "USD 12,000")) {
            assertEquals(text, CHANNEL_NOTIFICATION, filter.capture("com.nequi.MobileApp", "Nequi") { text }?.channel)
        }
    }

    @Test
    fun `recorta titulo y texto a los limites`() {
        val captured = filter.capture("com.bancolombia.app", "T".repeat(900)) {
            "\$1.000 " + "x".repeat(20_000)
        }!!
        assertEquals(MAX_TITLE, captured.title!!.length)
        assertEquals(MAX_TEXT, captured.text.length)
    }

    @Test
    fun `sin config no captura nada`() {
        val empty = CaptureFilter(CaptureConfig.EMPTY)
        assertNull(empty.capture("com.bancolombia.app", "Bancolombia") { "\$1.000" })
    }

    @Test
    fun `un patron invalido se salta sin romper los demas`() {
        val broken = CaptureConfig.of(
            bankingApps = emptyList(),
            messagesApps = listOf("com.google.android.apps.messaging"),
            smsSenderPatterns = listOf("(", "(?i)nequi"),
        )
        val captured = CaptureFilter(broken).capture("com.google.android.apps.messaging", "NEQUI") {
            "Recibiste \$10.000"
        }
        assertEquals(CHANNEL_SMS, captured?.channel)
    }
}
