package co.luka.luka

import co.luka.luka.capture.CaptureChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CaptureChannel(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
