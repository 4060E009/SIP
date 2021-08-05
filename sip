MainActivity.kt
**
package com.example.sip

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.RemoteException
import android.view.View
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.abtollc.sdk.*
import org.abtollc.sdk.AbtoPhone.INVALID_CALL_ID
import org.abtollc.sdk.OnInitializeListener.InitializeState
import org.abtollc.utils.Log
import org.abtollc.utils.codec.Codec
import android.os.Bundle as Bundle1


@SuppressLint("StaticFieldLeak")
lateinit var abtoPhone: AbtoPhone
private var activeCallId = INVALID_CALL_ID
var REQUEST_CODE_ASK_MULTIPLE_PERMISSIONS = 124
val  RegDomain = "192.168.5.19:5060"
val  RegProxy = ""
val  RegPassword = "000000"
val  RegUser = "009"

var inComingCallId: Int = 0

class MainActivity : AppCompatActivity(), OnInitializeListener, OnIncomingCallListener {



    val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle1?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        abtoPhone = (application as App).abtoPhone
        val bCanStartPhoneInitialization =
            if (Build.VERSION.SDK_INT >= 23) askPermissions() else true
        if (bCanStartPhoneInitialization) initPhone()

        abtoPhone.config.addAccount(RegDomain,RegProxy,RegUser,RegPassword,null, "", 300, false)
        //Register
        try {
            abtoPhone.register()
        } catch (e: RemoteException) {
            android.util.Log.d(TAG, "RegistrationFailed: " + e)
            e.printStackTrace()
        }
        abtoPhone.setIncomingCallListener(this)

        // Set registration event
        abtoPhone.setRegistrationStateListener(object : OnRegistrationListener {
            override fun onRegistrationFailed(accId: Long, statusCode: Int, statusText: String) {
                android.util.Log.d(TAG, "onRegistrationFailed ")
            }

            override fun onRegistered(accId: Long) {
                android.util.Log.d(TAG, "onRegistered")
            }

            override fun onUnRegistered(accId: Long) {
                android.util.Log.d(TAG, "onUnRegistered")
            }
        })
    }

    private fun initPhone() {
        val config: AbtoPhoneCfg = abtoPhone.getConfig()
        config.setCodecPriority(Codec.PCMU, 200.toShort())
        config.setCodecPriority(Codec.PCMA, 100.toShort())
        config.setCodecPriority(Codec.H264, 220.toShort())
        config.setCodecPriority(Codec.H263_1998, 210.toShort())
        config.sipPort = 0
        config.setSignallingTransport(AbtoPhoneCfg.SignalingTransportType.UDP)
        Log.setLogLevel(5)
        Log.setUseFile(true)
        abtoPhone.initialize(true)
        abtoPhone.setInitializeListener(this)
        android.util.Log.d(TAG, "initPhone: " + abtoPhone )
    }

    private fun askPermissions(): Boolean {
        android.util.Log.d(TAG, "askPermissions: ")
        val permissionsNeeded: ArrayList<String> = ArrayList<String>()
        val permissionsList: ArrayList<String> = ArrayList<String>()

        if (!addPermission(permissionsList, Manifest.permission.RECORD_AUDIO)) {
            permissionsNeeded.add("RECORD_AUDIO")
        }
        if (!addPermission(permissionsList, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
            permissionsNeeded.add("WRITE_EXTERNAL_STORAGE")
        }
        if (!addPermission(permissionsList, Manifest.permission.CAMERA)) {
            permissionsNeeded.add("CAMERA")
        }
        if (!addPermission(permissionsList, Manifest.permission.USE_SIP)) {
            permissionsNeeded.add("USE_SIP")
        }
        if (permissionsList.size > 0) {
            if (permissionsNeeded.size > 0) {
                ActivityCompat.requestPermissions(
                    this,
                    permissionsList.toTypedArray(),
                    REQUEST_CODE_ASK_MULTIPLE_PERMISSIONS
                )
                return false
            }
            ActivityCompat.requestPermissions(
                this,
                permissionsList.toTypedArray(),
                REQUEST_CODE_ASK_MULTIPLE_PERMISSIONS
            )
            return false
        }
        return true

    }

    private fun addPermission(permissionsList: ArrayList<String>, permission: String): Boolean {
        android.util.Log.d(TAG, "addPermission: ")
        if (ContextCompat.checkSelfPermission(
                this,
                permission
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionsList.add(permission)
            // Check for Rationale Option
            if (!ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {
                return false
            }
        }
        return true
    }

    override fun onInitializeState(p0: InitializeState?, p1: String?) {

    }
    override fun OnIncomingCall(callId: Int, p1: String?, p2: Long) {
        inComingCallId = callId
        android.util.Log.d(TAG, "callId" + callId )
        setContentView(R.layout.av_screen)

    }

    fun onBtnClick(view: View) {
            setContentView(R.layout.call)
    }

    fun onBtnClick1(view: View) {
        setContentView(R.layout.activity_main)
    }

    fun onBtnClick3(view: View) {
        setContentView(R.layout.activity_main)
    }
}
=================================================================================================================
CallEventsReceiver.kt
**
package com.example.sip

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.RemoteException
import android.util.Log
import org.abtollc.sdk.AbtoPhone
import org.abtollc.sdk.OnCallConnectedListener

private var activeCallId = AbtoPhone.INVALID_CALL_ID


class CallEventsReceiver : BroadcastReceiver(), OnCallConnectedListener {

    private var phone: AbtoPhone? = null

    override fun onReceive(context: Context, intent: Intent) {

        val bundle = intent.extras ?: return

        phone = App.app?.abtoPhone ?: return

        when {
            bundle.getBoolean(AbtoPhone.IS_INCOMING, false) -> {
                // Incoming call
                buildIncomingCallNotification(context, bundle)
            }
            bundle.getBoolean(KEY_REJECT_CALL, false) -> {
                // Reject call
                val callId = bundle.getInt(AbtoPhone.CALL_ID)
                cancelIncCallNotification(context, callId)
                try {
                    App.app?.abtoPhone?.rejectCall(callId)
                } catch (e: RemoteException) {
                    e.printStackTrace()
                }
            }
            bundle.getInt(AbtoPhone.CODE) == -1 -> {
                // Cancel call
                val callId = bundle.getInt(AbtoPhone.CALL_ID)
                cancelIncCallNotification(context, callId)
            }
        }
    }

    private fun buildIncomingCallNotification(context: Context, bundle: Bundle) {
        // Cancel incoming call notification
//        val intent = Intent(context, ScreenAV::class.java)
//        intent.putExtras(bundle)
//        if (!App.app!!.isAppInBackground()) { //App is foreground - start activity
//            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//            context.startActivity(intent)
//            return
//        }
//        val isVideoCall = bundle.getBoolean(AbtoPhone.HAS_VIDEO, false)
//        val title = if (isVideoCall) "Incoming video call Test" else "Incoming call Test"
//        val remoteContact = bundle.getString(AbtoPhone.REMOTE_CONTACT)
//        val callId = bundle.getInt(AbtoPhone.CALL_ID)
//        // Create channel
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && channelCall == null) {
//            channelCall = NotificationChannel(
//                CHANEL_CALL_ID,
//                context.getString(R.string.app_name) + " Call",
//                NotificationManager.IMPORTANCE_HIGH
//            )
//            channelCall!!.description = context.getString(R.string.app_name)
//            val notificationManager =
//                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
//            notificationManager?.createNotificationChannel(channelCall!!)
//        }
//        // Intent for launch ScreenAV
//        val notificationPendingIntent = PendingIntent.getActivity(
//            context, 1, intent,
//            PendingIntent.FLAG_UPDATE_CURRENT
//        )
//        // Intent for pickup audio call
//        val pickUpAudioIntent = Intent(context, ScreenAV::class.java)
//        pickUpAudioIntent.putExtras(bundle)
//        pickUpAudioIntent.putExtra(KEY_PICK_UP_AUDIO, true)
//        val pickUpAudioPendingIntent = PendingIntent.getActivity(
//            context, 2,
//            pickUpAudioIntent, PendingIntent.FLAG_UPDATE_CURRENT
//        )
//        // Intent for reject call
//        val rejectCallIntent = Intent()
//        rejectCallIntent.setPackage(context.packageName)
//        rejectCallIntent.action = AbtoPhone.ACTION_ABTO_CALL_EVENT
//        rejectCallIntent.putExtra(AbtoPhone.CALL_ID, callId)
//        rejectCallIntent.putExtra(KEY_REJECT_CALL, true)
//        val pendingRejectCall = PendingIntent.getBroadcast(
//            context, 4, rejectCallIntent,
//            PendingIntent.FLAG_CANCEL_CURRENT
//        )
//        // Style for popup notification
//        val bigText = NotificationCompat.BigTextStyle()
//        bigText.bigText(remoteContact)
//        bigText.setBigContentTitle(title)
//        // Create notification
//        val builder = NotificationCompat.Builder(context, CHANEL_CALL_ID)
//        builder.setColor(-0xff0100)
//            .setContentTitle(title)
//            .setContentIntent(notificationPendingIntent)
//            .setContentText(remoteContact)
//            .setDefaults(Notification.DEFAULT_ALL)
//            .setStyle(bigText)
//            .setPriority(Notification.PRIORITY_MAX)
//            .setCategory(NotificationCompat.CATEGORY_CALL)
//            .addAction(R.drawable.ic_launcher_background, "Hang Up Test", pendingRejectCall)
//            .addAction(R.drawable.ic_launcher_background, "Audio", pickUpAudioPendingIntent)
//            .setFullScreenIntent(notificationPendingIntent, true)
//        if (isVideoCall) {
//            // Intent for pickup video call
//            val pickUpVideoIntent = Intent(context, ScreenAV::class.java)
//            pickUpVideoIntent.putExtras(bundle)
//            pickUpVideoIntent.putExtra(KEY_PICK_UP_VIDEO, true)
//            val pickUpVideoPendingIntent = PendingIntent.getActivity(
//                context, 3,
//                pickUpVideoIntent, PendingIntent.FLAG_UPDATE_CURRENT
//            )
//            builder.addAction(R.drawable.ic_launcher_background, "Video", pickUpVideoPendingIntent)
//        }
//        val mNotificationManager =
//            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
//        val notification = builder.build()
//        mNotificationManager.notify(NOTIFICATION_INCOMING_CALL_ID + callId, notification)
//
        val isAppInBackground = App.app?.isAppInBackground() ?: return
        if (!isAppInBackground) { //App is foreground - start activity
            Log.d("LifeCycle","isAppInForeground")
                phone?.answerCall(inComingCallId,200,false)
                return
        }
        phone?.answerCall(inComingCallId,200,false)
        Log.d("LifeCycle","isAppInBackground")
    }

    companion object {
        const val CHANEL_CALL_ID = "abto_phone_call"
        private var channelCall: NotificationChannel? = null
        const val KEY_PICK_UP_AUDIO = "KEY_PICK_UP_AUDIO"
        const val KEY_PICK_UP_VIDEO = "KEY_PICK_UP_VIDEO"
        const val KEY_REJECT_CALL = "KEY_REJECT_CALL"
        private const val NOTIFICATION_INCOMING_CALL_ID = 1000
        fun cancelIncCallNotification(context: Context, callId: Int) {
            val mNotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            mNotificationManager?.cancel(NOTIFICATION_INCOMING_CALL_ID + callId)
        }
    }

    override fun onCallConnected(callId: Int, remoteContact: String?) {
        Log.d("onCallConnected","" + callId)
    }
}
=================================================================================================================
ScreenAV
**
package com.example.sip

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.PowerManager
import android.os.PowerManager.WakeLock
import android.os.RemoteException
import android.util.Log
import android.view.View
import android.widget.Toast
import org.abtollc.sdk.*
import org.abtollc.sdk.OnCallHeldListener.HoldState
import org.abtollc.sdk.OnInitializeListener.InitializeState

// com.example.sip/com.example.sip.MainActivity
// com.example.sip/com.example.sip.ScreenAV
class ScreenAV: Activity(), OnCallConnectedListener, OnRemoteAlertingListener, OnCallDisconnectedListener,
    OnCallHeldListener, OnToneReceivedListener, OnCallErrorListener,OnInitializeListener {

    protected val THIS_FILE = "ScreenAV"

    val POINT_TIME = "pointTime"
    val TOTAL_TIME = "totalTime"

    private var activeCallId = AbtoPhone.INVALID_CALL_ID

    lateinit var abtoPhone: AbtoPhone

    private var mInitialAutoSendVideoState = false

    private var mScreenWakeLock: WakeLock? = null
    private var mProximityWakeLock: WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.av_screen)

        initWakeLocks()

        abtoPhone = (application as AbtoApplication).abtoPhone
        mInitialAutoSendVideoState = abtoPhone.config.isEnabledAutoSendRtpVideo


        //Event handlers
        abtoPhone.setCallConnectedListener(this)
        abtoPhone.setCallDisconnectedListener(this)
        abtoPhone.setOnCallHeldListener(this)
        abtoPhone.setRemoteAlertingListener(this)
        abtoPhone.setToneReceivedListener(this)

        //Verify mode, in which was started this activity
        val bIsIncoming = intent.getBooleanExtra(AbtoPhone.IS_INCOMING, false)
        val startedFromService = intent.getBooleanExtra(AbtoPhone.ABTO_SERVICE_MARKER, false)
        if (startedFromService) {
            abtoPhone.initialize(true)
            abtoPhone.setInitializeListener(this)
        } else {
            answerCallByIntent()
        }

        // Cancel incoming call notification

        // Cancel incoming call notification
        activeCallId = intent.getIntExtra(AbtoPhone.CALL_ID, AbtoPhone.INVALID_CALL_ID)
        if (bIsIncoming) AbtoCallEventsReceiver.cancelIncCallNotification(this, activeCallId)

        Log.d(THIS_FILE, "callId - $activeCallId")

        mTotalTime = intent.getLongExtra(TOTAL_TIME, 0)
        mPointTime = intent.getLongExtra(POINT_TIME, 0)
        if (mTotalTime != 0L) {
            mHandler.removeCallbacks(mUpdateTimeTask)
            mHandler.postDelayed(mUpdateTimeTask, 100)
        }
    }

    private fun answerCallByIntent() {
        if (intent.getBooleanExtra(AbtoCallEventsReceiver.KEY_PICK_UP_AUDIO, false)) {
            pickUp(null)
        }
        if (intent.getBooleanExtra(AbtoCallEventsReceiver.KEY_PICK_UP_VIDEO, false)) {
            pickUpVideo(null)
        }
    }

    fun pickUp(view: View?) {
        try {
            abtoPhone.answerCall(activeCallId, 200, false)
        } catch (e: RemoteException) {
            Log.e(THIS_FILE, e.message!!)
        }
    }

    fun pickUpVideo(view: View?) {
        try {
            abtoPhone.answerCall(activeCallId, 200, true)
        } catch (e: RemoteException) {
            Log.e(THIS_FILE, e.message!!)
        }
    }

    // ==========Timer==============
    private var mPointTime: Long = 0
    private var mTotalTime: Long = 0
    private val mHandler = Handler()
    private val mUpdateTimeTask: Runnable = object : Runnable {
        override fun run() {
            mTotalTime += System.currentTimeMillis() - mPointTime
            mPointTime = System.currentTimeMillis()
            var seconds = (mTotalTime / 1000).toInt()
            val minutes = seconds / 60
            seconds = seconds % 60
            if (seconds < 10) {
                Log.d(TOTAL_TIME, "totalTime - $minutes")
            } else {
                Log.d(TOTAL_TIME, "totalTime - $minutes:$seconds")
            }
            mHandler.postDelayed(this, 1000)
        }
    }

    private fun initWakeLocks() {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        val flags = PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP
        mScreenWakeLock = powerManager.newWakeLock(flags, "com.abtotest.voiptest:wakelogtag")
        mScreenWakeLock?.setReferenceCounted(false)
        var field = 0x00000020
        try {
            field = PowerManager::class.java.javaClass.getField("PROXIMITY_SCREEN_OFF_WAKE_LOCK")
                .getInt(null)
        } catch (t: Throwable) {
        }
        mProximityWakeLock = powerManager.newWakeLock(field, localClassName)
    }

    private fun enableProximity() {
        if (!mProximityWakeLock!!.isHeld) {
            mProximityWakeLock!!.acquire()
        }
    }

    private fun disableProximity() {
        if (mProximityWakeLock!!.isHeld) {
            mProximityWakeLock!!.release()
        }
    }

    override fun onCallConnected(p0: Int, p1: String?) {
        if (mTotalTime == 0L) {
            mPointTime = System.currentTimeMillis()
            mHandler.removeCallbacks(mUpdateTimeTask)
            mHandler.postDelayed(mUpdateTimeTask, 100)
        }

        //phone.setMicrophoneMute(false);
        //phone.setMicrophoneLevel((float)3.0);


        //phone.setMicrophoneMute(false);
        //phone.setMicrophoneLevel((float)3.0);
        if (abtoPhone.isVideoCall(activeCallId)) {
            disableProximity()
        } else {
            enableProximity()
        }
    }

    override fun onRemoteAlerting(callId: Int, statusCode: Int, accId: Long) {
        if (activeCallId == AbtoPhone.INVALID_CALL_ID) activeCallId = callId

        when (statusCode) {
            OnRemoteAlertingListener.TRYING -> Log.d("onRemoteAlerting","Trying")
            OnRemoteAlertingListener.RINGING -> Log.d("onRemoteAlerting","Ringing")
            OnRemoteAlertingListener.SESSION_PROGRESS -> Log.d("onRemoteAlerting","Session in progress")
        }
    }

    override fun onCallDisconnected(callId: Int, remoteContact: String?, statusCode: Int, statusMessage: String?) {
        if (callId == activeCallId) {
            finish()
            mTotalTime = 0
        }
    }

    override fun onCallHeld(callId: Int, state: HoldState?) {
        when (state) {
            HoldState.LOCAL_HOLD -> Log.d("HoldState","Local Hold")
            HoldState.REMOTE_HOLD -> Log.d("HoldState","Remote Hold")
            HoldState.ACTIVE -> Log.d("HoldState","Active")
        }
    }

    override fun onToneReceived(callId: Int, tone: Char) {
        Toast.makeText(this@ScreenAV, "DTMF received: $tone", Toast.LENGTH_SHORT).show()
    }

    override fun onCallError(remoteContact: String?, statusCode: Int, message: String?) {
        Toast.makeText(this@ScreenAV, "onCallError: $statusCode", Toast.LENGTH_SHORT).show()
    }

    override fun onInitializeState(state: OnInitializeListener.InitializeState?, message: String?) {
        if (state == InitializeState.SUCCESS) {
            abtoPhone.setInitializeListener(null)
            answerCallByIntent()
        }
    }

}
=================================================================================================================
AppInBackgroundHandler
**
package com.example.sip

import android.app.Activity
import android.app.Application.ActivityLifecycleCallbacks
import android.os.Bundle

class AppInBackgroundHandler : ActivityLifecycleCallbacks {
    private var activeActivities = 0
    override fun onActivityCreated(activity: Activity, bundle: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {
        activeActivities++
    }

    override fun onActivityPaused(activity: Activity) {
        activeActivities--
    }

    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, bundle: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
    fun isAppInBackground(): Boolean { return activeActivities == 0 }
}
=================================================================================================================
App
**
package com.example.sip

import android.content.IntentFilter
import org.abtollc.sdk.AbtoApplication
import org.abtollc.sdk.AbtoPhone

class App : AbtoApplication() {
    private val callEventsReceiver = CallEventsReceiver()
    private var appInBackgroundHandler: AppInBackgroundHandler? = null
    override fun onCreate() {
        super.onCreate()
        app = this
        registerReceiver(callEventsReceiver, IntentFilter(AbtoPhone.ACTION_ABTO_CALL_EVENT))
        appInBackgroundHandler = AppInBackgroundHandler()
        registerActivityLifecycleCallbacks(appInBackgroundHandler)
    }

    override fun onTerminate() {
        super.onTerminate()
        unregisterReceiver(callEventsReceiver)
        unregisterActivityLifecycleCallbacks(appInBackgroundHandler)
    }

    fun isAppInBackground(): Boolean {
        return appInBackgroundHandler!!.isAppInBackground()
    }

    companion object {
        var app: App? = null
            private set
    }
}
=================================================================================================================
