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
import android.content.pm.PackageManager;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.Looper;
import android.os.SystemClock;
import android.support.v4.content.ContextCompat;
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
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKSdk;
import com.vk.sdk.VKSdk.LoginState;

public class VKGeoService extends QtService implements LocationListener
{
    private class MessageHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            if (msg.what == MESSAGE_NOT_AUTHORIZED) {
                vkAuthChanged(false);
            } else if (msg.what == MESSAGE_AUTHORIZED) {
                Bundle bdl = msg.getData();

                if (bdl != null && bdl.containsKey("VKAccessToken")) {
                    VKAccessToken.replaceToken(getApplicationContext(), VKAccessToken.tokenFromUrlString(bdl.getString("VKAccessToken")));

                    vkAuthChanged(true);
                } else {
                    vkAuthChanged(false);
                }
            } else {
                super.handleMessage(msg);
            }
        }
    }

    public static final int                  MESSAGE_NOT_AUTHORIZED             = 1001,
                                             MESSAGE_AUTHORIZED                 = 1002;

    private static final int                 LOCATION_SOURCE_SELECTION_INTERVAL = 60000;
    private static final long                LOCATION_UPDATE_MIN_TIME_DELTA     = 300000,
                                             LOCATION_UPDATE_CTR_TIMEOUT        = 600000,
                                             LOCATION_UPDATE_MIN_TIME           = 300000;
    private static final float               LOCATION_UPDATE_MIN_DISTANCE       = 100.0f,
                                             LOCATION_UPDATE_CTR_DISTANCE       = 500.0f;

    private boolean                          centerLocationChanged              = true;
    private long                             centerLocationChangeRealtimeNanos  = 0;
    private String                           locationProvider                   = null;
    private Location                         centerLocation                     = null,
                                             lastLocation                       = null;
    private LocationManager                  locationManager                    = null;
    private NotificationManager              notificationManager                = null;
    private Notification.Builder             notificationBuilder                = null;
    private Messenger                        messenger                          = new Messenger(new MessageHandler());
    private HashMap<VKRequest,      Boolean> vkRequestTracker                   = new HashMap<VKRequest,      Boolean>();
    private HashMap<VKBatchRequest, Boolean> vkBatchRequestTracker              = new HashMap<VKBatchRequest, Boolean>();

    private static native void locationUpdated(double latitude, double longitude);

    private static native void vkAuthChanged(boolean authorized);
    private static native void vkRequestComplete(String request, String response);
    private static native void vkRequestError(String request, String error_message);

    @Override
    public void onCreate()
    {
        super.onCreate();

        notificationManager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(getResources().getString(R.string.service_notification_channel_id),
                                                                  getResources().getString(R.string.service_notification_channel_name),
                                                                  NotificationManager.IMPORTANCE_LOW);

            channel.setShowBadge(false);

            notificationManager.createNotificationChannel(channel);

            notificationBuilder = new Notification.Builder(this, getResources().getString(R.string.service_notification_channel_id))
                                                          .setSmallIcon(R.drawable.ic_notification)
                                                          .setContentTitle(getResources().getString(R.string.service_notification_title))
                                                          .setContentText(getResources().getString(R.string.service_notification_text))
                                                          .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        } else {
            notificationBuilder = new Notification.Builder(this)
                                                          .setPriority(Notification.PRIORITY_LOW)
                                                          .setSmallIcon(R.drawable.ic_notification)
                                                          .setContentTitle(getResources().getString(R.string.service_notification_title))
                                                          .setContentText(getResources().getString(R.string.service_notification_text))
                                                          .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        }

        startForeground(getResources().getInteger(R.integer.service_foreground_notification_id), notificationBuilder.build());

        locationManager = (LocationManager)getSystemService(Context.LOCATION_SERVICE);

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
    public IBinder onBind(Intent intent) {
        return messenger.getBinder();
    }

    @Override
    public void onLocationChanged(Location location)
    {
        if (lastLocation != null) {
            if (location.getElapsedRealtimeNanos() - lastLocation.getElapsedRealtimeNanos() > LOCATION_UPDATE_MIN_TIME_DELTA * 1000000 ||
                location.getAccuracy() > lastLocation.getAccuracy()) {
                lastLocation = location;

                locationUpdated(lastLocation.getLatitude(), lastLocation.getLongitude());
            }
        } else {
            lastLocation = location;

            locationUpdated(lastLocation.getLatitude(), lastLocation.getLongitude());
        }
        if (centerLocation == null || centerLocation.distanceTo(lastLocation) > LOCATION_UPDATE_CTR_DISTANCE) {
            centerLocation        = lastLocation;
            centerLocationChanged = true;
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
                            Log.w("VKGeoService", "executeVKBatch() : invalid request");
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
                Iterator<VKBatchRequest> vk_batch_request_tracker_keys = vkBatchRequestTracker.keySet().iterator();

                while (vk_batch_request_tracker_keys.hasNext()) {
                    vk_batch_request_tracker_keys.next().cancel();
                }
            }
        });
    }

    private void selectLocationSource()
    {
        if (locationManager != null) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                Criteria criteria = new Criteria();

                criteria.setAltitudeRequired(false);
                criteria.setBearingRequired(false);
                criteria.setSpeedRequired(false);

                if (centerLocationChanged) {
                    criteria.setHorizontalAccuracy(Criteria.ACCURACY_HIGH);
                    criteria.setPowerRequirement(Criteria.NO_REQUIREMENT);
                } else if (SystemClock.elapsedRealtimeNanos() - centerLocationChangeRealtimeNanos > LOCATION_UPDATE_CTR_TIMEOUT * 1000000) {
                    criteria.setHorizontalAccuracy(Criteria.NO_REQUIREMENT);
                    criteria.setPowerRequirement(Criteria.POWER_LOW);
                } else {
                    criteria = null;
                }

                if (criteria != null) {
                    String provider = locationManager.getBestProvider(criteria, true);

                    if (provider != null) {
                        if (locationProvider == null || !locationProvider.equals(provider)) {
                            locationManager.removeUpdates(this);

                            try {
                                if (lastLocation == null) {
                                    Location location = locationManager.getLastKnownLocation(provider);

                                    if (location != null) {
                                        onLocationChanged(location);
                                    }
                                }

                                locationManager.requestLocationUpdates(provider, LOCATION_UPDATE_MIN_TIME, LOCATION_UPDATE_MIN_DISTANCE, this);

                                locationProvider = provider;

                                if (centerLocationChanged) {
                                    centerLocationChanged             = false;
                                    centerLocationChangeRealtimeNanos = SystemClock.elapsedRealtimeNanos();
                                }

                                if (notificationManager != null && notificationBuilder != null) {
                                    if (criteria.getHorizontalAccuracy() == Criteria.ACCURACY_HIGH) {
                                        notificationBuilder.setContentTitle(getResources().getString(R.string.service_notification_title_high_accuracy));
                                    } else if (criteria.getPowerRequirement() == Criteria.POWER_LOW) {
                                        notificationBuilder.setContentTitle(getResources().getString(R.string.service_notification_title_low_power));
                                    } else {
                                        notificationBuilder.setContentTitle(getResources().getString(R.string.service_notification_title));
                                    }

                                    notificationManager.notify(getResources().getInteger(R.integer.service_foreground_notification_id), notificationBuilder.build());
                                }
                            } catch (Exception ex) {
                                Log.w("VKGeoService", "selectLocationSource() : " + ex.toString());
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

    private void runOnMainThread(Runnable runnable)
    {
        new Handler(Looper.getMainLooper()).post(runnable);
    }

    private void runOnMainThreadWithDelay(Runnable runnable, int delay)
    {
        new Handler(Looper.getMainLooper()).postDelayed(runnable, delay);
    }
}
