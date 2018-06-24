package com.derevenetz.oleg.vkgeo;

import android.content.Intent;
import android.os.Build;

import org.qtproject.qt5.android.bindings.QtApplication;

import com.vk.sdk.VKSdk;

public class VKGeoApplication extends QtApplication
{
    @Override
    public void onCreate()
    {
        super.onCreate();

        VKSdk.initialize(this);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            this.startForegroundService(new Intent(this, VKGeoService.class));
        } else {
            this.startService(new Intent(this, VKGeoService.class));
        }
    }
}
