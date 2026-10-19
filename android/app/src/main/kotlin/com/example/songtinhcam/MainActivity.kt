package com.example.songtinhcam

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.songtinhcam/file_picker"
    private var pendingResult: MethodChannel.Result? = null
    private var contentToSave: String? = null

    companion object {
        private const val REQUEST_PICK_FILE = 1001
        private const val REQUEST_SAVE_FILE = 1002
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFile" -> {
                    if (pendingResult != null) {
                        result.error("ALREADY_ACTIVE", "A file picking operation is already in progress.", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "*/*"))
                        }
                        startActivityForResult(intent, REQUEST_PICK_FILE)
                    } catch (e: Exception) {
                        try {
                            val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "*/*"
                            }
                            startActivityForResult(fallbackIntent, REQUEST_PICK_FILE)
                        } catch (e2: Exception) {
                            pendingResult = null
                            result.error("PICK_ERROR", e2.message, null)
                        }
                    }
                }
                "saveFile" -> {
                    if (pendingResult != null) {
                        result.error("ALREADY_ACTIVE", "A file operation is already in progress.", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    val fileName = call.argument<String>("fileName") ?: "songtinhcam_backup.json"
                    contentToSave = call.argument<String>("content") ?: ""
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, REQUEST_SAVE_FILE)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("SAVE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_PICK_FILE) {
            val res = pendingResult
            pendingResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri: Uri = data.data!!
                    var fileName = uri.lastPathSegment ?: "backup.json"
                    contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                        val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                        if (nameIndex != -1 && cursor.moveToFirst()) {
                            fileName = cursor.getString(nameIndex)
                        }
                    }

                    val inputStream = contentResolver.openInputStream(uri)
                    val reader = BufferedReader(InputStreamReader(inputStream, Charsets.UTF_8))
                    val stringBuilder = StringBuilder()
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        stringBuilder.append(line).append('\n')
                    }
                    reader.close()
                    inputStream?.close()

                    res?.success(mapOf(
                        "name" to fileName,
                        "content" to stringBuilder.toString()
                    ))
                } catch (e: Exception) {
                    res?.error("READ_ERROR", e.message, null)
                }
            } else {
                res?.success(null)
            }
        } else if (requestCode == REQUEST_SAVE_FILE) {
            val res = pendingResult
            pendingResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri: Uri = data.data!!
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        val bytes = (contentToSave ?: "").toByteArray(Charsets.UTF_8)
                        outputStream.write(bytes)
                        outputStream.flush()
                    }
                    contentToSave = null
                    res?.success(mapOf(
                        "success" to true,
                        "uri" to uri.toString()
                    ))
                } catch (e: Exception) {
                    res?.error("WRITE_ERROR", e.message, null)
                }
            } else {
                res?.success(null)
            }
        }
    }
}
