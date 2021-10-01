package com.derevenetz.oleg.vkgeo.gplay;

import java.lang.ref.WeakReference;

import android.Manifest;
import android.app.Notification;
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
import android.location.LocationProvider;
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

import org.qtproject.qt5.android.bindings.QtService;

import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKSdk;

import com.derevenetz.oleg.vkgeo.gplay.util.VKBatchRequestCallback;
import com.derevenetz.oleg.vkgeo.gplay.util.VKBatchRequestManager;

public class VKGeoService extends QtService implements LocationListener
{
    private static class MessageHandler extends Handler {
        private final WeakReference<VKGeoService> serviceWeakRef;

        MessageHandler(VKGeoService service)
        {
            serviceWeakRef = new WeakReference<>(service);
        }

        @Override
        public void handleMessage(Message msg)
        {
            if (msg.what == MESSAGE_SETTINGS_UPDATED) {
                settingsUpdated();
            } else if (msg.what == MESSAGE_NOT_AUTHORIZED) {
                vkAuthUpdated(false);
            } else if (msg.what == MESSAGE_AUTHORIZED) {
                Bundle bdl = msg.getData();

                if (bdl != null && bdl.containsKey("VKAccessToken") && bdl.getString("VKAccessToken") != null) {
                    try {
                        VKAccessToken.replaceToken(serviceWeakRef.get().getApplicationContext(), VKAccessToken.tokenFromUrlString(bdl.getString("VKAccessToken")));

                        vkAuthUpdated(true);
                    } catch (Exception ex) {
                        Log.e("VKGeoService", "handleMessage() : " + ex.toString());
                    }
                }
            } else {
                super.handleMessage(msg);
            }
        }
    }

    public static final int       MESSAGE_SETTINGS_UPDATED           = 1001,
                                  MESSAGE_NOT_AUTHORIZED             = 1002,
                                  MESSAGE_AUTHORIZED                 = 1003;

    private static final int      LOCATION_SOURCE_SELECTION_INTERVAL = 60000;
    private static final long     LOCATION_UPDATE_MIN_TIME           = 30000,
                                  CENTRAL_LOCATION_CHANGE_TIMEOUT    = 900000;
    private static final float    LOCATION_UPDATE_MIN_DISTANCE       = 100.0f,
                                  CENTRAL_LOCATION_CHANGE_DISTANCE   = 500.0f;

    private boolean               centralLocationChanged             = true;
    private long                  centralLocationChangeHandleRtNanos = 0;
    private String                locationProvider                   = null;
    private Location              currentLocation                    = null,
                                  centralLocation                    = null;
    private Criteria              locationSourceSelectionCriteria    = new Criteria();
    private Notification.Builder  serviceNotificationBuilder         = null;
    private Messenger             messenger                          = new Messenger(new MessageHandler(this));
    private VKBatchRequestManager vkBatchRequestManager              = new VKBatchRequestManager(false);

    private static native void settingsUpdated();

    private static native void locationUpdated(double latitude, double longitude);
    private static native void batteryStatusUpdated(String status, int level);

    private static native void vkAuthUpdated(boolean authorized);
    private static native void vkRequestCompleted(String request, String response);
    private static native void vkRequestFailed(String request, String error_message);

    @Override
    public void onCreate()
    {
        super.onCreate();

        locationSourceSelectionCriteria.setAltitudeRequired(false);
        locationSourceSelectionCriteria.setBearingRequired(false);
        locationSourceSelectionCriteria.setSpeedRequired(false);

        locationSourceSelectionCriteria.setHorizontalAccuracy(Criteria.ACCURACY_HIGH);
        locationSourceSelectionCriteria.setPowerRequirement(Criteria.NO_REQUIREMENT);

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
        if (locationProvider != null && locationProvider.equals(provider)) {
            locationProvider = null;
        }
    }

    @Override
    public void onProviderEnabled(String provider)
    {
        // Ignore
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras)
    {
        if (locationProvider != null && locationProvider.equals(provider) && status == LocationProvider.OUT_OF_SERVICE) {
            locationProvider = null;
        }
    }

    public void showNotLoggedInNotification()
    {
        NotificationManager  notification_manager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
        Notification.Builder notification_builder = null;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(getResources().getString(R.string.authorization_state_notification_channel_id),
                                                                  getResources().getString(R.string.authorization_state_notification_channel_name),
                                                                  NotificationManager.IMPORTANCE_DEFAULT);

            channel.setShowBadge(true);

            notification_manager.createNotificationChannel(channel);

            notification_builder = new Notification.Builder(this, getResources().getString(R.string.authorization_state_notification_channel_id))
                                                           .setAutoCancel(true)
                                                           .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                           .setContentTitle(getResources().getString(R.string.not_logged_in_notification_title))
                                                           .setContentText(getResources().getString(R.string.not_logged_in_notification_text))
                                                           .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        } else {
            notification_builder = new Notification.Builder(this)
                                                           .setPriority(Notification.PRIORITY_DEFAULT)
                                                           .setDefaults(Notification.DEFAULT_ALL)
                                                           .setAutoCancel(true)
                                                           .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                           .setContentTitle(getResources().getString(R.string.not_logged_in_notification_title))
                                                           .setContentText(getResources().getString(R.string.not_logged_in_notification_text))
                                                           .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        }

        notification_manager.notify(getResources().getInteger(R.integer.not_logged_in_notification_id), notification_builder.build());
    }

    public void hideNotLoggedInNotification()
    {
        NotificationManager notification_manager = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);

        notification_manager.cancel(getResources().getInteger(R.integer.not_logged_in_notification_id));
    }

    public void showFriendsNearbyNotification(String user_id, String user_name)
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
                                                           .setContentText(String.format(getResources().getString(R.string.friends_nearby_notification_text), user_name))
                                                           .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        } else {
            notification_builder = new Notification.Builder(this)
                                                           .setPriority(Notification.PRIORITY_DEFAULT)
                                                           .setDefaults(Notification.DEFAULT_ALL)
                                                           .setAutoCancel(true)
                                                           .setSmallIcon(R.drawable.ic_stat_notify_service)
                                                           .setContentTitle(getResources().getString(R.string.friends_nearby_notification_title))
                                                           .setContentText(String.format(getResources().getString(R.string.friends_nearby_notification_text), user_name))
                                                           .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, VKGeoActivity.class), 0));
        }

        notification_manager.notify(getResources().getInteger(R.integer.friends_nearby_notification_first_id) + (user_id.hashCode() & 0xFFFF), notification_builder.build());
    }

    public void initVK()
    {
        runOnMainThread(new Runnable() {
            @Override
            public void run()
            {
                vkAuthUpdated(VKSdk.isLoggedIn());
            }
        });
    }

    public void executeVKBatch(String request_list)
    {
        final String f_request_list = request_list;

        runOnMainThread(new Runnable() {
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

                        @Override
                        public void authorizationFailed()
                        {
                            showNotLoggedInNotification();
                        }
                    });
                } catch (Exception ex) {
                    Log.e("VKGeoService", "executeVKBatch() : " + ex.toString());
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
                vkBatchRequestManager.cancelAll();
            }
        });
    }

    private void selectLocationSource()
    {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
             (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
              checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED))) {
            LocationManager manager = (LocationManager)getSystemService(Context.LOCATION_SERVICE);

            if (manager != null) {
                if (centralLocationChanged) {
                    locationSourceSelectionCriteria.setHorizontalAccuracy(Criteria.ACCURACY_HIGH);
                    locationSourceSelectionCriteria.setPowerRequirement(Criteria.NO_REQUIREMENT);
                } else if (SystemClock.elapsedRealtimeNanos() - centralLocationChangeHandleRtNanos > CENTRAL_LOCATION_CHANGE_TIMEOUT * 1000000) {
                    locationSourceSelectionCriteria.setHorizontalAccuracy(Criteria.ACCURACY_MEDIUM);
                    locationSourceSelectionCriteria.setPowerRequirement(Criteria.POWER_LOW);
                }

                String provider = manager.getBestProvider(locationSourceSelectionCriteria, true);

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
                                    serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_with_provider),
                                                                                             getResources().getString(R.string.gps_location_provider)));
                                } else if (locationProvider.equals(LocationManager.NETWORK_PROVIDER)) {
                                    serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_with_provider),
                                                                                             getResources().getString(R.string.network_location_provider)));
                                } else if (locationProvider.equals(LocationManager.PASSIVE_PROVIDER)) {
                                    serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_with_provider),
                                                                                             getResources().getString(R.string.passive_location_provider)));
                                } else {
                                    serviceNotificationBuilder.setContentTitle(String.format(getResources().getString(R.string.service_notification_title_with_provider),
                                                                                             locationProvider));
                                }

                                notification_manager.notify(getResources().getInteger(R.integer.service_foreground_notification_id), serviceNotificationBuilder.build());
                            }
                        } catch (Exception ex) {
                            Log.e("VKGeoService", "selectLocationSource() : " + ex.toString());
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
