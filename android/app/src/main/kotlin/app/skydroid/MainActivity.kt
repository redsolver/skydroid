package app.skydroid;

// Thanks to https://github.com/Aefyr/SAI for the Shizuku Code

// Thanks to https://github.com/hui-z/flutter_install_plugin for the native code


import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import com.aefyr.sai.installer.ApkSourceBuilder
import com.aefyr.sai.installer2.base.SaiPiSessionObserver
import com.aefyr.sai.installer2.base.model.SaiPiSessionParams
import com.aefyr.sai.installer2.base.model.SaiPiSessionState
import com.aefyr.sai.installer2.base.model.SaiPiSessionStatus
import com.aefyr.sai.installer2.impl.FlexSaiPackageInstaller
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.File


class MainActivity: FlutterActivity(), SaiPiSessionObserver {
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
      }else if (call.method == "checkShizukuPermission") {
          // val res = PermissionsUtils.checkAndRequestShizukuPermissions(activity)
          val res = Shizuku.checkSelfPermission() == 0


          // System.out.println(Shizuku.pingBinder());

          result.success(res)
      }else if (call.method == "requestShizukuPermission") {

          Shizuku.requestPermission(1337)

      }else if (call.method == "installWithShizuku") {
          if(mInstaller==null) {

              mInstaller = FlexSaiPackageInstaller.getInstance(application);
              mInstaller!!.registerSessionObserver(this);
          }

          val currentAppId = "app.skydroid"
          val file = File(call.argument("path") ?: "")

          result.success(installPackages(application,file,currentAppId))
      }else if (call.method == "fetchShizukuInstallationStatus") {
          result.success(listOf(installationStatus,installationStatusError))

      }
    }
  }
    private var mInstaller: FlexSaiPackageInstaller? = null

    private var mOngoingSessionId: Long = 0

    private fun installPackages(context: Context?, file: File?, appId: String?) : Long { // 24+

        installationStatus = null
        installationStatusError = null

        if (context == null) throw NullPointerException("context is null!")
        if (file == null) throw NullPointerException("file is null!")
        if (appId == null) throw NullPointerException("appId is null!")
        // val intent = Intent(Intent.ACTION_VIEW)
        // intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        // intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val uri: Uri = FileProvider.getUriForFile(context, "$appId.fileProvider.install", file)
        // intent.setDataAndType(uri, "application/vnd.android.package-archive")
        // context.startActivity(intent)

        // ensureInstallerActuality()

        val apkSource = ApkSourceBuilder(context)
                .fromApkContentUris(listOf(uri))
                .setSigningEnabled(false)
                .build()

        mInstaller!!.enqueueSession(mInstaller!!.createSessionOnInstaller(2, SaiPiSessionParams(apkSource)));

        // mOngoingSessionId = mInstaller!!.createInstallationSession(apkSource)
        // mInstaller!!.startInstallationSession(mOngoingSessionId)

        return mOngoingSessionId
    }

    private var installationStatus: String? = null
    private var installationStatusError: String? = null

    override fun onSessionStateChanged(state: SaiPiSessionState) {
        installationStatus = state.status().getReadableName(application);
        if(state.status()==SaiPiSessionStatus.INSTALLATION_FAILED){
            installationStatusError = state.shortError()+"|||"+state.fullError()
        }

        // println("---")
        // println(installationStatus)
        // println(installationStatusError)
        // println(state.appTempName())
        // println(state.packageName())
        // println(state.packageMeta())
        // TODO println(state.sessionId().split("@").first())

        /*when (state.status()) {
            INSTALLATION_SUCCEED -> mEvents.setValue(Event2(EVENT_PACKAGE_INSTALLED, state.packageName()))
            INSTALLATION_FAILED -> mEvents.setValue(Event2(EVENT_INSTALLATION_FAILED, arrayOf<String>(state.shortError(), state.fullError())))
        }
        mSessions.setValue(mInstaller.getSessions())*/
    }

    /*override fun onStatusChanged(installationID: Long, status: SAIPackageInstaller.InstallationStatus?, packageNameOrErrorDescription: String?) {
        println("---")
        println(installationID)
        println(status)
        println(packageNameOrErrorDescription)
    }*/


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