package co.finanzia.finanzia.capture

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.TimeZone

/**
 * Listener del sistema (spec 006 §3.2, spec 008 §4.1). Android lo mantiene vivo
 * aunque la app esté cerrada (AC-APP-2): filtra y guarda en la cola, y Dart la
 * envía la próxima vez que la app corre.
 *
 * Nunca registra en logs título, texto ni paquete (P1).
 */
class FinanziaNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            capture(sbn)
        } catch (e: Exception) {
            Log.w(TAG, "captura falló: ${e.javaClass.simpleName}")
        }
    }

    private fun capture(sbn: StatusBarNotification) {
        val notification = sbn.notification ?: return
        // El resumen de un grupo repite las notificaciones que ya llegaron.
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val store = CaptureStore.get(this)
        val extras = notification.extras
        val captured = CaptureFilter(store.config()).capture(
            packageName = sbn.packageName,
            title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
            readText = {
                (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                    ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
            },
        ) ?: return

        store.enqueue(
            PendingNotification(
                id = 0,
                packageName = sbn.packageName,
                channel = captured.channel,
                postedAtMs = sbn.postTime,
                offsetMinutes = TimeZone.getDefault().getOffset(sbn.postTime) / 60_000,
                title = captured.title,
                text = captured.text,
            ),
        )
    }

    private companion object {
        const val TAG = "finanzia.capture"
    }
}
