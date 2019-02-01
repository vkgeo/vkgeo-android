package com.derevenetz.oleg.vkgeo.stdalone;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;

import android.app.Notification;
import android.app.Notification.Builder;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import org.qtproject.qt5.android.bindings.QtService;

import com.vk.sdk.api.VKError;
import com.vk.sdk.api.VKParameters;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKResponse;
import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKSdk;
import com.vk.sdk.VKSdk.LoginState;

public class VKGeoService extends QtService implements LocationListener
{
    private static class MessageHandler extends Handler {
        private final WeakReference<VKGeoService> serviceWeakRef;

        MessageHandler(VKGeoService service)
        {
            serviceWeakRef = new WeakReference<VKGeoService>(service);
        }

        @Override
        public void handleMessage(Message msg)
        {
            if (msg.what == MESSAGE_NOT_AUTHORIZED) {
                vkAuthChanged(false);
            } else if (msg.what == MESSAGE_AUTHORIZED) {
                Bundle bdl = msg.getData();

                if (bdl != null && bdl.containsKey("VKAccessToken") && bdl.getString("VKAccessToken") != null) {
                    try {
                        VKAccessToken.replaceToken(serviceWeakRef.get().getApplicationContext(), VKAccessToken.tokenFromUrlString(bdl.getString("VKAccessToken")));

                        vkAuthChanged(true);
                    } catch (Exception ex) {
                        Log.w("VKGeoService", "handleMessage() : " + ex.toString());
                    }
                }
            } else {
                super.handleMessage(msg);
            }
        }
    }

    public static final int             MESSAGE_NOT_AUTHORIZED             = 1001,
                                        MESSAGE_AUTHORIZED                 = 1002;

    private static final int            LOCATION_SOURCE_SELECTION_INTERVAL = 60000;
    private static final long           LOCATION_UPDATE_MIN_TIME           = 30000,
                                        CENTRAL_LOCATION_CHANGE_TIMEOUT    = 900000;
    private static final float          LOCATION_UPDATE_MIN_DISTANCE       = 100.0f,
                                        CENTRAL_LOCATION_CHANGE_DISTANCE   = 500.0f;

    private boolean                     centralLocationChanged             = true;
    private long                        centralLocationChangeHandleRtNanos = 0;
    private String                      locationProvider                   = null;
    private Location                    currentLocation                    = null,
                                        centralLocation                    = null;
    private Notification.Builder        serviceNotificationBuilder         = null;
    private Messenger                   messenger                          = new Messenger(new MessageHandler(this));
    private HashMap<VKRequest, Boolean> vkRequestTracker                   = new HashMap<VKRequest, Boolean>();

    private static native void locationUpdated(double latitude, double longitude);
    private static native void batteryStatusUpdated(String status, int level);

    private static native void vkAuthChanged(boolean authorized);
    private static native void vkRequestComplete(String request, String response);
    private static native void vkRequestError(String request, String error_message);

    @Override
    public void onCreate()
    {
        super.onCreate();

        NotificationManager notification_manager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(getResources().getString(R.string.service_notification_channel_id),
                                                                  getResources().getString(R.string.service_notification_channel_name),
                                                                  NotificationManager.IMPORTANCE_LOW);

            channel.setShowBadge(false);

            notification_manager.createNotificationChannel(channel);

            serviceNotificationBuilder = new Notification.Builder(this, getResources().getString(R.string.service_notification_channel_id))
                                                                 .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                                 .setContentTitle(getResources().getString(R.string.service_notification_title))
                                                                 .setContentText(getResources().getString(R.string.service_notification_text))
                                                                 .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        } else {
            serviceNotificationBuilder = new Notification.Builder(this)
                                                                 .setPriority(Notification.PRIORITY_LOW)
                                                                 .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                                 .setContentTitle(getResources().getString(R.string.service_notification_title))
                                                                 .setContentText(getResources().getString(R.string.service_notification_text))
                                                                 .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        }

        startForeground(getResources().getInteger(R.integer.service_foreground_notification_id), serviceNotificationBuilder.build());

        runOnMainThreadWithDelay(new Runnable() {
            @Override
            public void run()
            {
                selectLocationSource();
            }
        }, LOCATION_SOURCE_SELECTION_INTERVAL);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId)
    {
        return Service.START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent)
    {
        return messenger.getBinder();
    }

    @Override
    public void onLocationChanged(Location location)
    {
        if (currentLocation == null || currentLocation.distanceTo(location) > location.getAccuracy()) {
            currentLocation = location;

            locationUpdated(currentLocation.getLatitude(), currentLocation.getLongitude());

            if (centralLocation == null || centralLocation.distanceTo(currentLocation) > CENTRAL_LOCATION_CHANGE_DISTANCE) {
                centralLocation        = currentLocation;
                centralLocationChanged = true;
            }

            batteryStatusUpdated(getBatteryStatus(), getBatteryLevel());
        }
    }

    @Override
    public void onProviderDisabled(String provider)
    {
    }

    @Override
    public void onProviderEnabled(String provider)
    {
    }

    @Override
    public void onStatusChanged (String provider, int status, Bundle extras)
    {
    }

    public void showFriendsNearbyNotification(String friend_id, String friend_name)
    {
        NotificationManager  notification_manager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
        Notification.Builder notification_builder = null;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(getResources().getString(R.string.friends_nearby_notification_channel_id),
                                                                  getResources().getString(R.string.friends_nearby_notification_channel_name),
                                                                  NotificationManager.IMPORTANCE_DEFAULT);

            channel.setShowBadge(true);

            notification_manager.createNotificationChannel(channel);

            notification_builder = new Notification.Builder(this, getResources().getString(R.string.friends_nearby_notification_channel_id))
                                                           .setAutoCancel(true)
                                                           .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                           .setContentTitle(getResources().getString(R.string.friends_nearby_notification_title))
                                                           .setContentText(String.format(getResources().getString(R.string.friends_nearby_notification_text), friend_name))
                                                           .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        } else {
            notification_builder = new Notification.Builder(this)
                                                           .setPriority(Notification.PRIORITY_DEFAULT)
                                                           .setDefaults(Notification.DEFAULT_ALL)
                                                           .setAutoCancel(true)
                                                           .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                           .setContentTitle(getResources().getString(R.string.friends_nearby_notification_title))
                                                           .setContentText(String.format(getResources().getString(R.string.friends_nearby_notification_text), friend_name))
                                                           .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        }

        notification_manager.notify(getResources().getInteger(R.integer.friends_nearby_notification_first_id) + (friend_id.hashCode() & 0xFFFF), notification_builder.build());
    }

    public void initVK()
    {
        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                if (VKSdk.isLoggedIn()) {
                    vkAuthChanged(true);
                } else {
                    vkAuthChanged(false);
                }
            }
        });
    }

    public void loginVK(String auth_scope)
    {
    }

    public void logoutVK()
    {
    }

    public void executeVKBatch(String request_list)
    {
        final String f_request_list = request_list;

        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                try {
                    final JSONArray json_request_list = new JSONArray(f_request_list);

                    if (json_request_list.length() > 0) {
                        String execute_code = "return [";

                        for (int i = 0; i < json_request_list.length(); i++) {
                            JSONObject json_request = json_request_list.getJSONObject(i);

                            if (json_request.has("method")) {
                                execute_code = execute_code + String.format("API.%s(%s)", json_request.getString("method"), json_request.optString("parameters"));

                                if (i < json_request_list.length() - 1) {
                                    execute_code = execute_code + ",";
                                }
                            } else {
                                Log.w("VKGeoService", "executeVKBatch() : invalid request");
                            }
                        }

                        execute_code = execute_code + "];";

                        final VKRequest vk_request = new VKRequest("execute", VKParameters.from("code", execute_code));

                        vkRequestTracker.put(vk_request, true);

                        vk_request.executeWithListener(new VKRequestListener() {
                            @Override
                            public void onComplete(VKResponse response)
                            {
                                if (vkRequestTracker.containsKey(vk_request)) {
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
                                                vkRequestError(json_request_list.optString(i), error_str);
                                            }
                                        } else if (response.json.has("response")) {
                                            String            error_str = null;
                                            ArrayList<String> responses = new ArrayList<String>();

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
                                                    vkRequestComplete(json_request_list.optString(i), responses.get(i));
                                                }
                                            } else {
                                                for (int i = 0; i < json_request_list.length(); i++) {
                                                    vkRequestError(json_request_list.optString(i), error_str);
                                                }
                                            }
                                        } else {
                                            for (int i = 0; i < json_request_list.length(); i++) {
                                                vkRequestComplete(json_request_list.optString(i), "");
                                            }
                                        }
                                    } else {
                                        for (int i = 0; i < json_request_list.length(); i++) {
                                            vkRequestComplete(json_request_list.optString(i), "");
                                        }
                                    }
                                }
                            }

                            @Override
                            public void onError(VKError error)
                            {
                                if (vkRequestTracker.containsKey(vk_request)) {
                                    vkRequestTracker.remove(vk_request);

                                    String error_str = "";

                                    if (error != null) {
                                        error_str = error.toString();
                                    }

                                    for (int i = 0; i < json_request_list.length(); i++) {
                                        vkRequestError(json_request_list.optString(i), error_str);
                                    }
                                }
                            }
                        });
                    }
                } catch (Exception ex) {
                    Log.w("VKGeoService", "executeVKBatch() : " + ex.toString());
                }
            }
        });
    }

    public void cancelAllVKRequests()
    {
        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                Iterator<VKRequest> vk_request_tracker_keys_iter = new HashSet<VKRequest>(vkRequestTracker.keySet()).iterator();

                while (vk_request_tracker_keys_iter.hasNext()) {
                    vk_request_tracker_keys_iter.next().cancel();
                }
            }
        });
    }

    private void selectLocationSource()
    {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            LocationManager manager = (LocationManager)getSystemService(Context.LOCATION_SERVICE);

            if (manager != null) {
                Criteria criteria = new Criteria();

                criteria.setAltitudeRequired(false);
                criteria.setBearingRequired(false);
                criteria.setSpeedRequired(false);

                if (centralLocationChanged) {
                    criteria.setHorizontalAccuracy(Criteria.ACCURACY_HIGH);
                    criteria.setPowerRequirement(Criteria.NO_REQUIREMENT);
                } else if (SystemClock.elapsedRealtimeNanos() - centralLocationChangeHandleRtNanos > CENTRAL_LOCATION_CHANGE_TIMEOUT * 1000000) {
                    criteria.setHorizontalAccuracy(Criteria.ACCURACY_MEDIUM);
                    criteria.setPowerRequirement(Criteria.POWER_LOW);
                } else {
                    criteria = null;
                }

                if (criteria != null) {
                    String provider = manager.getBestProvider(criteria, true);

                    if (provider != null) {
                        if (locationProvider == null || !locationProvider.equals(provider)) {
                            manager.removeUpdates(this);

                            locationProvider = null;

                            try {
                                manager.requestLocationUpdates(provider, LOCATION_UPDATE_MIN_TIME, LOCATION_UPDATE_MIN_DISTANCE, this);

                                locationProvider = provider;

                                if (centralLocationChanged) {
                                    centralLocationChanged             = false;
                                    centralLocationChangeHandleRtNanos = SystemClock.elapsedRealtimeNanos();
                                }

                                if (serviceNotificationBuilder != null) {
                                    NotificationManager notification_manager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);

                                    if (locationProvider.equals(LocationManager.GPS_PROVIDER)) {
                                        serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_provider),
                                                                                                 getResources().getString(R.string.location_provider_gps)));
                                    } else if (locationProvider.equals(LocationManager.NETWORK_PROVIDER)) {
                                        serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_provider),
                                                                                                 getResources().getString(R.string.location_provider_network)));
                                    } else if (locationProvider.equals(LocationManager.PASSIVE_PROVIDER)) {
                                        serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_provider),
                                                                                                 getResources().getString(R.string.location_provider_passive)));
                                    } else {
                                        serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_provider),
                                                                                                 locationProvider));
                                    }

                                    notification_manager.notify(getResources().getInteger(R.integer.service_foreground_notification_id), serviceNotificationBuilder.build());
                                }
                            } catch (Exception ex) {
                                Log.w("VKGeoService", "selectLocationSource() : " + ex.toString());
                            }
                        } else {
                            if (centralLocationChanged) {
                                centralLocationChanged             = false;
                                centralLocationChangeHandleRtNanos = SystemClock.elapsedRealtimeNanos();
                            }
                        }
                    }
                }
            }
        }

        runOnMainThreadWithDelay(new Runnable() {
            @Override
            public void run()
            {
                selectLocationSource();
            }
        }, LOCATION_SOURCE_SELECTION_INTERVAL);
    }

    private String getBatteryStatus()
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

    private int getBatteryLevel()
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

    private void runOnMainThread(Runnable runnable)
    {
        new Handler(Looper.getMainLooper()).post(runnable);
    }

    private void runOnMainThreadWithDelay(Runnable runnable, int delay)
    {
        new Handler(Looper.getMainLooper()).postDelayed(runnable, delay);
    }
}
