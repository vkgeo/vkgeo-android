package com.derevenetz.oleg.vkgeo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import android.app.Notification;
import android.app.Notification.Builder;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import org.qtproject.qt5.android.bindings.QtService;

import com.vk.sdk.api.VKBatchRequest;
import com.vk.sdk.api.VKBatchRequest.VKBatchRequestListener;
import com.vk.sdk.api.VKError;
import com.vk.sdk.api.VKParameters;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKResponse;
import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKAccessTokenTracker;
import com.vk.sdk.VKSdk;

public class VKGeoService extends QtService
{
    private static HashMap<VKRequest,      Boolean> vkRequestTracker      = new HashMap<VKRequest,      Boolean>();
    private static HashMap<VKBatchRequest, Boolean> vkBatchRequestTracker = new HashMap<VKBatchRequest, Boolean>();

    private static VKAccessTokenTracker vkAccessTokenTracker = new VKAccessTokenTracker() {
        @Override
        public void onVKAccessTokenChanged(VKAccessToken oldToken, VKAccessToken newToken) {
            if (newToken != null) {
                vkAuthChanged(true);
            } else {
                vkAuthChanged(false);
            }
        }
    };

    private static native void vkAuthChanged(boolean authorized);
    private static native void vkRequestComplete(String request, String response);
    private static native void vkRequestError(String request, String error_message);

    public VKGeoService()
    {
    }

    @Override
    public void onCreate()
    {
        super.onCreate();

        Notification notification = null;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = (NotificationManager)this.getSystemService(Context.NOTIFICATION_SERVICE);
            NotificationChannel channel = new NotificationChannel(getResources().getString(R.string.service_notification_channel_id),
                                                                  getResources().getString(R.string.service_notification_channel_name), NotificationManager.IMPORTANCE_DEFAULT);

            manager.createNotificationChannel(channel);

            notification = new Notification.Builder(this, getResources().getString(R.string.service_notification_channel_id))
                                                   .setSmallIcon(R.drawable.ic_notification)
                                                   .setContentTitle(getResources().getString(R.string.service_notification_title))
                                                   .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0))
                                                   .build();
        } else {
            notification = new Notification.Builder(this)
                                                   .setSmallIcon(R.drawable.ic_notification)
                                                   .setContentTitle(getResources().getString(R.string.service_notification_title))
                                                   .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0))
                                                   .build();
        }

        startForeground(getResources().getInteger(R.integer.service_foreground_notification_id), notification);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId)
    {
        return Service.START_STICKY;
    }

    public static void initVK()
    {
        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                vkAccessTokenTracker.startTracking();

                if (VKSdk.isLoggedIn()) {
                    vkAuthChanged(true);
                } else {
                    vkAuthChanged(false);
                }
            }
        });
    }

    public static void loginVK(String auth_scope)
    {
    }

    public static void logoutVK()
    {
    }

    public static void executeVKBatch(String request_list)
    {
        final String f_request_list = request_list;

        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                try {
                    JSONArray            json_request_list = new JSONArray(f_request_list);
                    ArrayList<VKRequest> vk_requests       = new ArrayList<VKRequest>();

                    for (int i = 0; i < json_request_list.length(); i++) {
                        final JSONObject json_request = json_request_list.getJSONObject(i);

                        if (json_request.has("method")) {
                            ArrayList<String> vk_parameters = new ArrayList<String>();

                            if (json_request.has("parameters")) {
                                JSONObject       json_parameters      = json_request.getJSONObject("parameters");
                                Iterator<String> json_parameters_keys = json_parameters.keys();

                                while (json_parameters_keys.hasNext()) {
                                    String key = json_parameters_keys.next();

                                    vk_parameters.add(key);
                                    vk_parameters.add(json_parameters.get(key).toString());
                                }
                            }

                            final VKRequest vk_request = new VKRequest(json_request.getString("method"),
                                                                       VKParameters.from((Object[])vk_parameters.toArray(new String[vk_parameters.size()])));

                            vk_request.setRequestListener(new VKRequestListener() {
                                @Override
                                public void onComplete(VKResponse response) {
                                    if (vkRequestTracker.containsKey(vk_request)) {
                                        vkRequestTracker.remove(vk_request);

                                        String response_str = "";

                                        if (response != null && response.json != null) {
                                            response_str = response.json.toString();
                                        }

                                        vkRequestComplete(json_request.toString(), response_str);
                                    }
                                }

                                @Override
                                public void onError(VKError error) {
                                    if (vkRequestTracker.containsKey(vk_request)) {
                                        vkRequestTracker.remove(vk_request);

                                        vkRequestError(json_request.toString(), error.toString());
                                    }
                                }
                            });

                            vkRequestTracker.put(vk_request, true);

                            vk_requests.add(vk_request);
                        } else {
                            Log.w("VKGeoActivity", "executeVKBatch() : invalid request");
                        }
                    }

                    if (vk_requests.size() > 0) {
                        final VKBatchRequest vk_batch_request = new VKBatchRequest(vk_requests.toArray(new VKRequest[vk_requests.size()]));

                        vkBatchRequestTracker.put(vk_batch_request, true);

                        vk_batch_request.executeWithListener(new VKBatchRequestListener() {
                            @Override
                            public void onComplete(VKResponse[] responses) {
                                vkBatchRequestTracker.remove(vk_batch_request);
                            }

                            @Override
                            public void onError(VKError error) {
                                vkBatchRequestTracker.remove(vk_batch_request);
                            }
                        });
                    }
                } catch (Exception ex) {
                    Log.w("VKGeoActivity", "executeVKBatch() : " + ex.toString());
                }
            }
        });
    }

    public static void cancelAllVKRequests()
    {
        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                Iterator<VKBatchRequest> vk_batch_request_tracker_keys = vkBatchRequestTracker.keySet().iterator();

                while (vk_batch_request_tracker_keys.hasNext()) {
                    vk_batch_request_tracker_keys.next().cancel();
                }
            }
        });
    }

    private static void runOnMainThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }
}
