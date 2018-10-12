package com.derevenetz.oleg.vkgeo.stdalone;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class VKGeoReceiver extends BroadcastReceiver
{
    @Override
    public void onReceive(Context context, Intent intent)
    {
        if (intent.getAction().equals("android.intent.action.BOOT_COMPLETED") ||
            intent.getAction().equals("android.intent.action.MY_PACKAGE_REPLACED")) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(new Intent(context, VKGeoService.class));
            } else {
                context.startService(new Intent(context, VKGeoService.class));
            }
        }
    }
}
