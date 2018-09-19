package com.derevenetz.oleg.vkgeoapp;

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
            startForegroundService(new Intent(this, VKGeoService.class));
        } else {
            startService(new Intent(this, VKGeoService.class));
        }
    }
}
