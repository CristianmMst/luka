package co.luka.luka.capture

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONArray

/** Una notificación ya filtrada, pendiente de que Dart la envíe. */
data class PendingNotification(
    val id: Long,
    val packageName: String,
    val channel: String,
    val postedAtMs: Long,
    val offsetMinutes: Int,
    val title: String?,
    val text: String,
)

/**
 * Cola y config del listener. La cola es el outbox de este canal (spec 006 §3.2):
 * sobrevive a que maten la app y Dart la vacía cuando vuelve a correr. Solo
 * guarda lo que ya pasó el filtro (P6).
 */
class CaptureStore private constructor(context: Context) :
    SQLiteOpenHelper(context, "luka_capture.db", null, 1) {

    private val prefs = context.getSharedPreferences("luka_capture", Context.MODE_PRIVATE)

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE pending_notifications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              package TEXT NOT NULL,
              channel TEXT NOT NULL,
              posted_at_ms INTEGER NOT NULL,
              offset_minutes INTEGER NOT NULL,
              title TEXT,
              text TEXT NOT NULL
            )
            """.trimIndent(),
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    @Synchronized
    fun config(): CaptureConfig {
        val banking = prefs.getString(KEY_BANKING, null) ?: return CaptureConfig.EMPTY
        return CaptureConfig.of(
            bankingApps = banking.toList(),
            messagesApps = prefs.getString(KEY_MESSAGES, "[]")!!.toList(),
            smsSenderPatterns = prefs.getString(KEY_PATTERNS, "[]")!!.toList(),
        )
    }

    @Synchronized
    fun setConfig(bankingApps: List<String>, messagesApps: List<String>, patterns: List<String>) {
        prefs.edit()
            .putString(KEY_BANKING, JSONArray(bankingApps).toString())
            .putString(KEY_MESSAGES, JSONArray(messagesApps).toString())
            .putString(KEY_PATTERNS, JSONArray(patterns).toString())
            .apply()
    }

    /** Si la cola era de otro usuario, la borra con la config antes de cambiar de dueño. */
    @Synchronized
    fun claimFor(userId: String) {
        val owner = prefs.getString(KEY_OWNER, null)
        if (owner != null && owner != userId) clear()
        prefs.edit().putString(KEY_OWNER, userId).apply()
    }

    @Synchronized
    fun enqueue(item: PendingNotification) {
        val db = writableDatabase
        db.insert(
            TABLE,
            null,
            ContentValues().apply {
                put("package", item.packageName)
                put("channel", item.channel)
                put("posted_at_ms", item.postedAtMs)
                put("offset_minutes", item.offsetMinutes)
                put("title", item.title)
                put("text", item.text)
            },
        )
        // Tope para que una cola que nunca se vacía no crezca sin límite.
        db.execSQL(
            "DELETE FROM $TABLE WHERE id NOT IN (SELECT id FROM $TABLE ORDER BY id DESC LIMIT $MAX_ROWS)",
        )
    }

    @Synchronized
    fun pending(limit: Int): List<PendingNotification> =
        readableDatabase.query(TABLE, null, null, null, null, null, "id ASC", limit.toString())
            .use { c ->
                buildList {
                    while (c.moveToNext()) {
                        add(
                            PendingNotification(
                                id = c.getLong(c.getColumnIndexOrThrow("id")),
                                packageName = c.getString(c.getColumnIndexOrThrow("package")),
                                channel = c.getString(c.getColumnIndexOrThrow("channel")),
                                postedAtMs = c.getLong(c.getColumnIndexOrThrow("posted_at_ms")),
                                offsetMinutes = c.getInt(c.getColumnIndexOrThrow("offset_minutes")),
                                title = c.getString(c.getColumnIndexOrThrow("title")),
                                text = c.getString(c.getColumnIndexOrThrow("text")),
                            ),
                        )
                    }
                }
            }

    @Synchronized
    fun remove(ids: List<Long>) {
        if (ids.isEmpty()) return
        writableDatabase.delete(TABLE, "id IN (${ids.joinToString(",") { "?" }})", ids.map { it.toString() }.toTypedArray())
    }

    /** Borra la cola y la config: sin config el listener no captura nada. */
    @Synchronized
    fun clear() {
        writableDatabase.delete(TABLE, null, null)
        prefs.edit().clear().apply()
    }

    private fun String.toList(): List<String> {
        val array = JSONArray(this)
        return List(array.length()) { array.getString(it) }
    }

    companion object {
        private const val TABLE = "pending_notifications"
        private const val MAX_ROWS = 5000
        private const val KEY_OWNER = "owner"
        private const val KEY_BANKING = "banking_apps"
        private const val KEY_MESSAGES = "messages_apps"
        private const val KEY_PATTERNS = "sms_sender_patterns"

        @Volatile private var instance: CaptureStore? = null

        fun get(context: Context): CaptureStore =
            instance ?: synchronized(this) {
                instance ?: CaptureStore(context.applicationContext).also { instance = it }
            }
    }
}
