package com.infinite.foodkie.express.foodkie_express

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class BluetoothMethodChannel(private val context: Context, flutterEngine: FlutterEngine) {
    private val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.infinite.foodkie.express.foodkie_express/bluetooth")
    private val scope = CoroutineScope(Dispatchers.Main)

    // Standard SPP UUID
    private val UUID_SPP = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    // Bluetooth related objects
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    init {
        initBluetooth()
        setupMethodChannel()
    }

    private fun initBluetooth() {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        bluetoothAdapter = bluetoothManager?.adapter
    }

    private fun setupMethodChannel() {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    result.success(bluetoothAdapter != null)
                }
                "isEnabled" -> {
                    result.success(bluetoothAdapter?.isEnabled == true)
                }
                "requestEnable" -> {
                    requestEnable(result)
                }
                "getBondedDevices" -> {
                    getBondedDevices(result)
                }
                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connectToDevice(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Device address required", null)
                    }
                }
                "disconnect" -> {
                    disconnect(result)
                }
                "write" -> {
                    val data = call.argument<ByteArray>("data")
                    if (data != null) {
                        writeData(data, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Data required", null)
                    }
                }
                "isConnected" -> {
                    result.success(bluetoothSocket?.isConnected == true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestEnable(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not available on this device", null)
            return
        }

        if (bluetoothAdapter?.isEnabled == true) {
            result.success(true)
            return
        }

        // This should be integrated with your main activity for proper permission handling
        // For simplicity, we're just checking and returning the current state
        if (hasBluetoothPermissions()) {
            try {
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                // This needs to be properly integrated with your activity
                // activity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT)
                result.success(false) // Return false as we can't enable directly here
            } catch (e: Exception) {
                result.error("ENABLE_FAILED", "Failed to request Bluetooth enable", e.message)
            }
        } else {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
        }
    }

    private fun getBondedDevices(result: MethodChannel.Result) {
        if (!hasBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not available on this device", null)
            return
        }

        try {
            val bondedDevices = bluetoothAdapter?.bondedDevices
            val devicesList = bondedDevices?.map {
                mapOf(
                    "name" to (it.name ?: "Unknown Device"),
                    "address" to it.address,
                    "type" to it.type,
                    "isBonded" to true
                )
            }?.toList() ?: listOf()

            result.success(devicesList)
        } catch (e: Exception) {
            result.error("GET_DEVICES_FAILED", "Failed to get bonded devices", e.message)
        }
    }

    private fun connectToDevice(address: String, result: MethodChannel.Result) {
        if (!hasBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        scope.launch {
            try {
                // Disconnect existing connection if any
                disconnect(null)

                // Get the BluetoothDevice
                val device = bluetoothAdapter?.getRemoteDevice(address)
                    ?: throw Exception("Device not found: $address")

                // Connect to the device
                withContext(Dispatchers.IO) {
                    bluetoothSocket = device.createRfcommSocketToServiceRecord(UUID_SPP)
                    bluetoothSocket?.connect()
                    outputStream = bluetoothSocket?.outputStream
                }

                result.success(bluetoothSocket?.isConnected == true)
            } catch (e: Exception) {
                disconnect(null)
                result.error("CONNECTION_FAILED", "Failed to connect to device: ${e.message}", null)
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result?) {
        scope.launch {
            try {
                withContext(Dispatchers.IO) {
                    try {
                        outputStream?.close()
                    } catch (_: Exception) {}

                    try {
                        bluetoothSocket?.close()
                    } catch (_: Exception) {}
                }

                outputStream = null
                bluetoothSocket = null

                result?.success(true)
            } catch (e: Exception) {
                result?.error("DISCONNECT_FAILED", "Failed to disconnect: ${e.message}", null)
            }
        }
    }

    private fun writeData(data: ByteArray, result: MethodChannel.Result) {
        if (bluetoothSocket?.isConnected != true) {
            result.error("NOT_CONNECTED", "Not connected to any device", null)
            return
        }

        scope.launch {
            try {
                withContext(Dispatchers.IO) {
                    outputStream?.write(data)
                    outputStream?.flush()
                }
                result.success(true)
            } catch (e: IOException) {
                disconnect(null)
                result.error("WRITE_FAILED", "Failed to write data: ${e.message}", null)
            }
        }
    }

    private fun hasBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED &&
                    ActivityCompat.checkSelfPermission(
                        context,
                        Manifest.permission.BLUETOOTH_SCAN
                    ) == PackageManager.PERMISSION_GRANTED
        } else {
            return ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED &&
                    ActivityCompat.checkSelfPermission(
                        context,
                        Manifest.permission.BLUETOOTH_ADMIN
                    ) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun cleanup() {
        disconnect(null)
    }
}