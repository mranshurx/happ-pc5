package com.pc5.android

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import com.pc5.core.Pc5core
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class Pc5VpnService : VpnService() {

    private var tun: ParcelFileDescriptor? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val starting = AtomicBoolean(false)

    private var key: String = ""
    private var did: String = ""
    private var mode: String = ""
    private var expiresAt: Long = 0L

    private val expiryWatch = object : Runnable {
        override fun run() {
            if (expiresAt > 0 && System.currentTimeMillis() >= expiresAt) {
                VpnState.set(VpnState.Status.ERROR, "Subscription expired")
                shutdown()
                return
            }
            main.postDelayed(this, 30_000)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                shutdown()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                key = intent.getStringExtra(EXTRA_KEY).orEmpty()
                did = intent.getStringExtra(EXTRA_DID).orEmpty()
                mode = intent.getStringExtra(EXTRA_MODE).orEmpty()
                expiresAt = intent.getLongExtra(EXTRA_EXPIRES, 0L)
                begin()
            }
            ACTION_RECONNECT -> restart()
        }
        return START_STICKY
    }

    private fun begin() {
        if (key.isBlank()) {
            VpnState.set(VpnState.Status.ERROR, "Missing key")
            stopSelf()
            return
        }
        if (!starting.compareAndSet(false, true)) return

        Notifications.ensureChannel(this)
        VpnState.set(VpnState.Status.CONNECTING, "Applying profile")

        val notif = Notifications.build(this, "Connecting…", connected = true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                Notifications.ID,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(Notifications.ID, notif)
        }

        worker.execute {
            try {
                val json = try {
                    ConfigStore.fetch(key, did, mode)
                } catch (fetchError: Throwable) {
                    ConfigStore.cached(this) ?: throw fetchError
                }
                ConfigStore.save(this, json)

                val pfd = establishTun() ?: throw IllegalStateException("establish() returned null")
                val fd = pfd.detachFd()
                tun = pfd

                Pc5core.run(json, fd, 1500)
                if (!Pc5core.running()) throw IllegalStateException("core failed to start")

                main.post {
                    VpnState.set(VpnState.Status.UP, "Connected")
                    updateNotification("Connected", true)
                    main.removeCallbacks(expiryWatch)
                    main.postDelayed(expiryWatch, 30_000)
                    starting.set(false)
                }
            } catch (t: Throwable) {
                main.post {
                    VpnState.set(VpnState.Status.ERROR, t.message ?: "Connection failed")
                    starting.set(false)
                    shutdown()
                }
            }
        }
    }

    private fun establishTun(): ParcelFileDescriptor? {
        val b = Builder()
            .setSession("PC5")
            .setMtu(1500)
            .addAddress("10.10.10.2", 32)
            .addAddress("fd00:1:2:3::2", 128)
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)
            .addDnsServer("1.1.1.1")
            .addDnsServer("1.0.0.1")
            .setBlocking(false)

        runCatching { b.addDisallowedApplication(packageName) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) b.setMetered(false)

        return b.establish()
    }

    private fun restart() {
        worker.execute {
            runCatching { Pc5core.stop() }
            closeTun()
            main.post { begin() }
        }
    }

    private fun shutdown() {
        main.removeCallbacks(expiryWatch)
        worker.execute {
            runCatching { Pc5core.stop() }
            closeTun()
            main.post {
                VpnState.reset()
                runCatching {
                    getSystemService(NotificationManager::class.java).cancel(Notifications.ID)
                }
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
    }

    private fun closeTun() {
        runCatching { tun?.close() }
        tun = null
    }

    private fun updateNotification(text: String, connected: Boolean) {
        runCatching {
            getSystemService(NotificationManager::class.java)
                .notify(Notifications.ID, Notifications.build(this, text, connected))
        }
    }

    override fun onRevoke() {
        VpnState.set(VpnState.Status.IDLE, "Revoked")
        shutdown()
        super.onRevoke()
    }

    override fun onDestroy() {
        main.removeCallbacks(expiryWatch)
        worker.execute { runCatching { Pc5core.stop() } }
        closeTun()
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "com.pc5.android.START"
        const val ACTION_STOP = "com.pc5.android.STOP"
        const val ACTION_RECONNECT = "com.pc5.android.RECONNECT"
        const val EXTRA_KEY = "key"
        const val EXTRA_DID = "did"
        const val EXTRA_MODE = "mode"
        const val EXTRA_EXPIRES = "expires"

        fun start(ctx: Context, key: String, did: String, mode: String, expiresAt: Long) {
            val i = Intent(ctx, Pc5VpnService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_KEY, key)
                putExtra(EXTRA_DID, did)
                putExtra(EXTRA_MODE, mode)
                putExtra(EXTRA_EXPIRES, expiresAt)
            }
            ctx.startForegroundService(i)
        }

        fun stop(ctx: Context) {
            runCatching {
                ctx.startService(Intent(ctx, Pc5VpnService::class.java).setAction(ACTION_STOP))
            }
        }
    }
}
