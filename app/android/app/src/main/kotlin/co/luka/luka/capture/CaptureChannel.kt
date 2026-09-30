package co.luka.luka.capture

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * `MethodChannel("co.luka/capture")`, contraparte de
 * `lib/features/capture/data/method_channel_notification_source.dart`. La base
 * se toca en un hilo aparte y la respuesta vuelve al hilo principal.
 */
class CaptureChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    private val store = CaptureStore.get(context)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isPermissionGranted" -> result.success(isPermissionGranted())
            "openPermissionSettings" -> {
                context.startActivity(
                    Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success(null)
            }
            "claimFor" -> background(result) { store.claimFor(call.argument<String>("userId")!!) }
            "setConfig" -> background(result) {
                store.setConfig(
                    call.argument<List<String>>("bankingApps")!!,
                    call.argument<List<String>>("messagesApps")!!,
                    call.argument<List<String>>("smsSenderPatterns")!!,
                )
            }
            "pending" -> background(result) {
                store.pending(call.argument<Int>("limit")!!).map {
                    mapOf(
                        "id" to it.id,
                        "package" to it.packageName,
                        "channel" to it.channel,
                        "postedAtMs" to it.postedAtMs,
                        "offsetMinutes" to it.offsetMinutes,
                        "title" to it.title,
                        "text" to it.text,
                    )
                }
            }
            "remove" -> background(result) {
                store.remove(call.argument<List<Number>>("ids")!!.map { it.toLong() })
            }
            "clear" -> background(result) { store.clear() }
            else -> result.notImplemented()
        }
    }

    private fun isPermissionGranted(): Boolean {
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
            ?: return false
        val mine = ComponentName(context, LukaNotificationListener::class.java)
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == mine }
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work().takeUnless { it == Unit }
                main.post { result.success(value) }
            } catch (e: Exception) {
                // Solo el tipo: el mensaje podría traer datos de la cola (P1).
                main.post { result.error("capture_error", e.javaClass.simpleName, null) }
            }
        }
    }

    private companion object {
        const val NAME = "co.luka/capture"
    }
}
