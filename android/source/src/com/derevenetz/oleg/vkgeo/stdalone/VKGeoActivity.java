package com.derevenetz.oleg.vkgeo.stdalone;

import java.util.ArrayList;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.BatteryManager;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.util.Log;

import org.json.JSONArray;

import org.qtproject.qt5.android.bindings.QtActivity;

import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKAccessTokenTracker;
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKSdk;
import com.vk.sdk.api.VKError;

import com.derevenetz.oleg.vkgeo.stdalone.util.VKBatchRequestCallback;
import com.derevenetz.oleg.vkgeo.stdalone.util.VKBatchRequestManager;

public class VKGeoActivity extends QtActivity
{
    private Messenger             serviceMessenger      = null;
    private VKBatchRequestManager vkBatchRequestManager = new VKBatchRequestManager(true);

    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service)
        {
            serviceMessenger = new Messenger(service);
        }

        @Override
        public void onServiceDisconnected(ComponentName className)
        {
            serviceMessenger = null;
        }
    };

    private VKAccessTokenTracker vkAccessTokenTracker = new VKAccessTokenTracker() {
        @Override
        public void onVKAccessTokenChanged(VKAccessToken oldToken, VKAccessToken newToken)
        {
            if (newToken != null) {
                if (serviceMessenger != null) {
                    try {
                        Message msg = Message.obtain(null, VKGeoService.MESSAGE_AUTHORIZED);
                        Bundle  bdl = new Bundle();

                        bdl.putString("VKAccessToken", newToken.serialize());
                        msg.setData(bdl);

                        serviceMessenger.send(msg);
                    } catch (Exception ex) {
                        Log.e("VKGeoActivity", "onVKAccessTokenChanged() : " + ex.toString());
                    }
                }

                vkAuthUpdated(true);
            } else {
                if (serviceMessenger != null) {
                    try {
                        serviceMessenger.send(Message.obtain(null, VKGeoService.MESSAGE_NOT_AUTHORIZED));
                    } catch (Exception ex) {
                        Log.e("VKGeoActivity", "onVKAccessTokenChanged() : " + ex.toString());
                    }
                }

                vkAuthUpdated(false);
            }
        }
    };

    private static native void deviceConfigurationUpdated();

    private static native void vkAuthUpdated(boolean authorized);
    private static native void vkRequestCompleted(String request, String response);
    private static native void vkRequestFailed(String request, String error_message);

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        bindService(new Intent(this, VKGeoService.class), serviceConnection, Context.BIND_AUTO_CREATE);
    }

    @Override
    public void onDestroy()
    {
        if (serviceMessenger != null) {
            unbindService(serviceConnection);
        }

        super.onDestroy();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig)
    {
        super.onConfigurationChanged(newConfig);

        deviceConfigurationUpdated();
    }

    public int getScreenDpi()
    {
        DisplayMetrics metrics = getResources().getDisplayMetrics();

        return metrics.densityDpi;
    }

    public boolean getNightModeStatus()
    {
        Configuration config = getResources().getConfiguration();

        return ((config.uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES);
    }

    public String getBatteryStatus()
    {
        Intent battery_intent = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        int    battery_status = battery_intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);

        if (battery_status == BatteryManager.BATTERY_STATUS_CHARGING ||
            battery_status == BatteryManager.BATTERY_STATUS_FULL) {
            return "CHARGING";
        } else if (battery_status == BatteryManager.BATTERY_STATUS_DISCHARGING ||
                   battery_status == BatteryManager.BATTERY_STATUS_NOT_CHARGING) {
            return "DISCHARGING";
        } else {
            return "UNKNOWN";
        }
    }

    public int getBatteryLevel()
    {
        Intent battery_intent = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        int    battery_level  = battery_intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int    battery_scale  = battery_intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);

        if (battery_level > 0 && battery_scale > 0) {
            return (battery_level * 100) / battery_scale;
        } else {
            return 0;
        }
    }

    public void showAppSettings()
    {
        try {
            startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", getPackageName(), null)));
        } catch (Exception ex) {
            Log.e("VKGeoActivity", "showAppSettings() : " + ex.toString());
        }
    }

    public void sendInvitation(String text)
    {
        try {
            Intent intent = new Intent(Intent.ACTION_SEND);

            intent.setType("text/plain");
            intent.putExtra(Intent.EXTRA_TEXT, text);

            startActivity(Intent.createChooser(intent, getResources().getString(R.string.send_invitation_chooser_title)));
        } catch (Exception ex) {
            Log.e("VKGeoActivity", "sendInvitation() : " + ex.toString());
        }
    }

    public void notifyServiceAboutSettingsUpdate()
    {
        runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                if (serviceMessenger != null) {
                    try {
                        serviceMessenger.send(Message.obtain(null, VKGeoService.MESSAGE_SETTINGS_UPDATED));
                    } catch (Exception ex) {
                        Log.e("VKGeoActivity", "notifyServiceAboutSettingsUpdate() : " + ex.toString());
                    }
                }
            }
        });
    }

    public void initVK()
    {
        runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                vkAccessTokenTracker.startTracking();

                vkAuthUpdated(VKSdk.isLoggedIn());
            }
        });
    }

    public void loginVK(String auth_scope)
    {
        final String   f_auth_scope = auth_scope;
        final Activity f_activity   = this;

        runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                try {
                    JSONArray         json_auth_scope = new JSONArray(f_auth_scope);
                    ArrayList<String> vk_auth_scope   = new ArrayList<>();

                    for (int i = 0; i < json_auth_scope.length(); i++) {
                        vk_auth_scope.add(json_auth_scope.get(i).toString());
                    }

                    VKSdk.login(f_activity, vk_auth_scope.toArray(new String[vk_auth_scope.size()]));
                } catch (Exception ex) {
                    Log.e("VKGeoActivity", "loginVK() : " + ex.toString());
                }
            }
        });
    }

    public void logoutVK()
    {
        runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                VKSdk.logout();

                if (serviceMessenger != null) {
                    try {
                        serviceMessenger.send(Message.obtain(null, VKGeoService.MESSAGE_NOT_AUTHORIZED));
                    } catch (Exception ex) {
                        Log.e("VKGeoActivity", "logoutVK() : " + ex.toString());
                    }
                }
            }
        });
    }

    public void executeVKBatch(String request_list)
    {
        final String f_request_list = request_list;

        runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                try {
                    vkBatchRequestManager.execute(f_request_list, new VKBatchRequestCallback() {
                        @Override
                        public void requestCompleted(String request, String response)
                        {
                            vkRequestCompleted(request, response);
                        }

                        @Override
                        public void requestFailed(String request, String error_message)
                        {
                            vkRequestFailed(request, error_message);
                        }
                    });
                } catch (Exception ex) {
                    Log.e("VKGeoActivity", "executeVKBatch() : " + ex.toString());
                }
            }
        });
    }

    public void cancelAllVKRequests()
    {
        runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                vkBatchRequestManager.cancelAll();
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        super.onActivityResult(requestCode, resultCode, data);

        VKSdk.onActivityResult(requestCode, resultCode, data, new VKCallback<VKAccessToken>() {
            @Override
            public void onResult(VKAccessToken token)
            {
                // Ignore
            }

            @Override
            public void onError(VKError error)
            {
                String error_str = "";

                if (error != null) {
                    error_str = error.toString();
                }

                Log.e("VKGeoActivity", "onActivityResult() : " + error_str);
            }
        });
    }
}
