package com.example.flutter_gaming


import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import android.widget.Toast
import androidx.core.app.ActivityCompat
import com.example.flutter_gaming.DisplayService.Companion.isRecording
import com.example.flutter_gaming.DisplayService.Companion.isStreaming
import com.example.flutter_gaming.DisplayService.Companion.sendIntent
import com.example.flutter_gaming.DisplayService.Companion.setData
import io.flutter.embedding.android.FlutterActivity
import net.ossrs.rtmp.ConnectCheckerRtmp


class MainActivity : FlutterActivity(), ConnectCheckerRtmp {

  private val PERMISSIONS = arrayOf<String>(
    Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA,
    Manifest.permission.WRITE_EXTERNAL_STORAGE
  )

  private val REQUEST_CODE_STREAM = 179 //random num
  private val REQUEST_CODE_RECORD = 180 //random num

  private var notificationManager: NotificationManager? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    getInstance()

    if (!hasPermissions(this, PERMISSIONS)) {
      ActivityCompat.requestPermissions(this, PERMISSIONS, 1);
    }
    startStreaming()
  }

  private fun hasPermissions(context: Context?, permissions: Array<String>): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && context != null && permissions != null) {
      for (permission in permissions) {
        if (ActivityCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
          return false
        }
      }
    }
    return true
  }

  private fun getInstance() {
    DisplayService.init(this)
  }


  override fun onConnectionSuccessRtmp() {
    runOnUiThread { Toast.makeText(activity, "Connection success", Toast.LENGTH_SHORT).show() }
  }

  override fun onConnectionFailedRtmp(reason: String) {
    runOnUiThread {
      Toast.makeText(activity, "Connection failed. $reason", Toast.LENGTH_SHORT)
        .show()
      stopNotification()
      stopService(Intent(activity, DisplayService::class.java))
    }
  }

  override fun onNewBitrateRtmp(bitrate: Long) {}

  override fun onDisconnectRtmp() {
    runOnUiThread { Toast.makeText(activity, "Disconnected", Toast.LENGTH_SHORT).show() }
  }

  override fun onAuthErrorRtmp() {
    runOnUiThread { Toast.makeText(activity, "Auth error", Toast.LENGTH_SHORT).show() }
  }

  override fun onAuthSuccessRtmp() {
    runOnUiThread { Toast.makeText(activity, "Auth success", Toast.LENGTH_SHORT).show() }
  }

  private fun initNotification() {
    val notificationBuilder: Notification.Builder = Notification.Builder(this).setSmallIcon(R.drawable.notification_anim)
      .setContentTitle("Streaming")
      .setContentText("Display mode stream")
      .setTicker("Stream in progress")
    notificationBuilder.setAutoCancel(true)
    if (notificationManager != null) notificationManager!!.notify(12345, notificationBuilder.build())
  }

  private fun stopNotification() {
    if (notificationManager != null) {
      notificationManager!!.cancel(12345)
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    Log.i("SOMETHING", "in activity result ${resultCode}")
    if (data != null && (requestCode == REQUEST_CODE_STREAM
        || requestCode == REQUEST_CODE_RECORD && resultCode == Activity.RESULT_OK)) {
      initNotification()
      Log.i("SOMETHING", "Starting service")
      setData(resultCode, data)
      val intent = Intent(this, DisplayService::class.java)
      intent.putExtra("endpoint", "rtmp://global-live.mux.com:5222/app/692aedb2-b900-076a-bbeb-8a16503fa315")
      startService(intent)
    } else {
      Toast.makeText(this, "No permissions available", Toast.LENGTH_SHORT).show()
    }
  }

  fun startStreaming() {
    if (!isStreaming()) {
      startActivityForResult(sendIntent(), REQUEST_CODE_STREAM)
    } else {
      stopService(Intent(activity, DisplayService::class.java))
    }
    if (!isStreaming() && !isRecording()) {
      stopNotification()
    }
  }
}
