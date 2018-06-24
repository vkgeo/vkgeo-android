package com.derevenetz.oleg.vkgeo;

import android.content.Intent;

import org.qtproject.qt5.android.bindings.QtApplication;

import com.vk.sdk.VKSdk;

public class VKGeoApplication extends QtApplication
{
    @Override
    public void onCreate()
    {
        super.onCreate();

        VKSdk.initialize(this);

        this.startService(new Intent(this, VKGeoService.class));
    }
}
