package com.derevenetz.oleg.vkgeo.stdalone;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;

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
import org.json.JSONObject;

import org.qtproject.qt5.android.bindings.QtActivity;

import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKAccessTokenTracker;
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKSdk;
import com.vk.sdk.api.VKError;
import com.vk.sdk.api.VKParameters;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKResponse;

public class VKGeoActivity extends QtActivity
{
    private Messenger          serviceMessenger = null;
    private HashSet<VKRequest> vkRequestTracker = new HashSet<>();

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
                    final JSONArray json_request_list = new JSONArray(f_request_list);

                    if (json_request_list.length() > 0) {
                        StringBuilder execute_code = new StringBuilder("return [");

                        for (int i = 0; i < json_request_list.length(); i++) {
                            JSONObject json_request = json_request_list.getJSONObject(i);

                            if (json_request.has("method")) {
                                execute_code.append(String.format("API.%s(%s)", json_request.getString("method"), json_request.optString("parameters")));

                                if (i < json_request_list.length() - 1) {
                                    execute_code.append(",");
                                }
                            } else {
                                Log.w("VKGeoActivity", "executeVKBatch() : invalid request");
                            }
                        }

                        execute_code.append("];");

                        final VKRequest vk_request = new VKRequest("execute", VKParameters.from("code", execute_code.toString()));

                        vkRequestTracker.add(vk_request);

                        vk_request.executeWithListener(new VKRequestListener() {
                            @Override
                            public void onComplete(VKResponse response)
                            {
                                if (vkRequestTracker.contains(vk_request)) {
                                    vkRequestTracker.remove(vk_request);

                                    if (response != null && response.json != null) {
                                        if (response.json.has("execute_errors")) {
                                            String error_str = "";

                                            try {
                                                JSONArray json_execute_errors_list = response.json.getJSONArray("execute_errors");

                                                if (json_execute_errors_list.length() > 0 && json_execute_errors_list.getJSONObject(0).has("error_msg")) {
                                                    error_str = json_execute_errors_list.getJSONObject(0).getString("error_msg");
                                                } else {
                                                    error_str = "response has execute_errors without error_msg";
                                                }
                                            } catch (Exception ex) {
                                                error_str = ex.toString();
                                            }

                                            for (int i = 0; i < json_request_list.length(); i++) {
                                                vkRequestFailed(json_request_list.optString(i), error_str);
                                            }
                                        } else if (response.json.has("response")) {
                                            String            error_str = null;
                                            ArrayList<String> responses = new ArrayList<>();

                                            try {
                                                JSONArray json_response_list = response.json.getJSONArray("response");

                                                for (int i = 0; i < json_request_list.length(); i++) {
                                                    if (i < json_response_list.length()) {
                                                        responses.add((new JSONObject().put("response", json_response_list.get(i))).toString());
                                                    } else {
                                                        responses.add("");
                                                    }
                                                }
                                            } catch (Exception ex) {
                                                error_str = ex.toString();
                                            }

                                            if (error_str == null) {
                                                for (int i = 0; i < json_request_list.length(); i++) {
                                                    vkRequestCompleted(json_request_list.optString(i), responses.get(i));
                                                }
                                            } else {
                                                for (int i = 0; i < json_request_list.length(); i++) {
                                                    vkRequestFailed(json_request_list.optString(i), error_str);
                                                }
                                            }
                                        } else {
                                            for (int i = 0; i < json_request_list.length(); i++) {
                                                vkRequestCompleted(json_request_list.optString(i), "");
                                            }
                                        }
                                    } else {
                                        for (int i = 0; i < json_request_list.length(); i++) {
                                            vkRequestCompleted(json_request_list.optString(i), "");
                                        }
                                    }
                                }
                            }

                            @Override
                            public void onError(VKError error)
                            {
                                if (vkRequestTracker.contains(vk_request)) {
                                    vkRequestTracker.remove(vk_request);

                                    String error_str = "";

                                    if (error != null) {
                                        error_str = error.toString();
                                    }

                                    for (int i = 0; i < json_request_list.length(); i++) {
                                        vkRequestFailed(json_request_list.optString(i), error_str);
                                    }
                                }
                            }
                        });
                    }
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
                Iterator<VKRequest> vk_request_tracker_keys_iter = new HashSet<>(vkRequestTracker).iterator();

                while (vk_request_tracker_keys_iter.hasNext()) {
                    vk_request_tracker_keys_iter.next().cancel();
                }
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
