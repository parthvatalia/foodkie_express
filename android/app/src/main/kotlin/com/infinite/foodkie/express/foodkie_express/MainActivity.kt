package com.infinite.foodkie.express.foodkie_express

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine


class MainActivity : FlutterActivity(){
    private var bluetoothMethodChannel: BluetoothMethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize BluetoothMethodChannel
        bluetoothMethodChannel = BluetoothMethodChannel(applicationContext, flutterEngine)
    }

    override fun onDestroy() {
        bluetoothMethodChannel?.cleanup()
        super.onDestroy()
    }
}
