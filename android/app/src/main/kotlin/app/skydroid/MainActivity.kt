package app.skydroid;

// Thanks to https://github.com/hui-z/flutter_install_plugin for the native code

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileNotFoundException

class MainActivity: FlutterActivity() {
  private val CHANNEL = "app.skydroid/native"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      // Note: this method is invoked on the main thread.
      if (call.method == "install") {
        
          result.success(install(call.argument("path") ?: ""))
      }else if (call.method == "uninstall") {
        
          result.success(uninstall(call.argument("packageName") ?: ""))
      }else if (call.method == "launch") {
        
          result.success(launch(call.argument("packageName") ?: ""))
      }
    }
  }

  private fun uninstall(packageName: String): String {
    val intent = Intent(Intent.ACTION_DELETE);
    intent.data = Uri.parse("package:" + packageName)
    activity.startActivity(intent);
    return ""
  }

  private fun launch(packageName: String): String {
    val launchIntent = getPackageManager().getLaunchIntentForPackage(packageName);
    if (launchIntent != null) { 
        activity.startActivity(launchIntent);
    }
    return ""
  }

  private fun install(path: String): String {

      val currentAppId = "app.skydroid"



        val file = File(path)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if (canRequestPackageInstalls(activity)) install24(activity, file, currentAppId)
            else {
                showSettingPackageInstall(activity)
                return "show"
            //    apkFile = file
            //    appId = currentAppId
            }
        } else {
            installBelow24(activity, file)
        }
      return "ok"
  }

          private fun showSettingPackageInstall(activity: Activity) { // todo to test with android 26
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("SettingPackageInstall", ">= Build.VERSION_CODES.O")
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:" + activity.packageName)
            activity.startActivityForResult(intent, 1234)
        } else {
            throw RuntimeException("VERSION.SDK_INT < O")
        }

    }  


    private fun canRequestPackageInstalls(activity: Activity): Boolean {
        return Build.VERSION.SDK_INT <= Build.VERSION_CODES.O || context.packageManager.canRequestPackageInstalls()
    }

    private fun installBelow24(context: Context, file: File?) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val uri = Uri.fromFile(file)
        intent.setDataAndType(uri, "application/vnd.android.package-archive")
        context.startActivity(intent)
    }


    private fun install24(context: Context?, file: File?, appId: String?) {
        if (context == null) throw NullPointerException("context is null!")
        if (file == null) throw NullPointerException("file is null!")
        if (appId == null) throw NullPointerException("appId is null!")
        val intent = Intent(Intent.ACTION_VIEW)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val uri: Uri = FileProvider.getUriForFile(context, "$appId.fileProvider.install", file)
        intent.setDataAndType(uri, "application/vnd.android.package-archive")
        context.startActivity(intent)
    }


 /*     var uri=FileProvider.getUriForFile(context, context.getApplicationContext().getPackageName() + ".provider", File(path))
    var promptInstall = Intent(Intent.ACTION_VIEW)
    .setDataAndType(uri, 
                    "application/vnd.android.package-archive");
                    
    promptInstall.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

    startActivity(promptInstall); 

    return uri.toString()*/

}