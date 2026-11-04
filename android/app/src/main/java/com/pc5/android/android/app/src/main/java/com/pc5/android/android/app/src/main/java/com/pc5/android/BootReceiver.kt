package com.pc5.android

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(ctx: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED && action != "android.intent.action.QUICKBOOT_POWERON") return

        val prefs = ctx.getSharedPreferences("pc5", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("autostart", false)) return

        val key = prefs.getString("key", null) ?: return
        val did = prefs.getString("did", null) ?: return
        val expires = prefs.getLong("expiresAt", 0L)
        if (expires in 1 until System.currentTimeMillis()) return

        Pc5VpnService.start(ctx, key, did, prefs.getString("mode", "").orEmpty(), expires)
    }
}
