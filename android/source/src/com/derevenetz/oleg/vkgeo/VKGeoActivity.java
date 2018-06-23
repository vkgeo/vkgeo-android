package com.derevenetz.oleg.vkgeo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import org.json.JSONArray;
import org.json.JSONObject;

import org.qtproject.qt5.android.bindings.QtActivity;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.InterstitialAd;
import com.google.android.gms.ads.MobileAds;

import com.vk.sdk.api.VKBatchRequest;
import com.vk.sdk.api.VKBatchRequest.VKBatchRequestListener;
import com.vk.sdk.api.VKError;
import com.vk.sdk.api.VKParameters;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKResponse;
import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKAccessTokenTracker;
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKSdk;

public class VKGeoActivity extends QtActivity
{
    private static final String                     ADMOB_APP_ID                 = "ca-app-pub-2455088855015693~7279538773";
    private static final String                     ADMOB_ADVIEW_UNIT_ID         = "ca-app-pub-3940256099942544/6300978111";
    private static final String                     ADMOB_INTERSTITIALAD_UNIT_ID = "ca-app-pub-3940256099942544/1033173712";
    private static final String                     ADMOB_TEST_DEVICE_ID         = "";

    private static final AdSize                     ADMOB_ADVIEW_ADSIZE          = AdSize.SMART_BANNER;

    private static boolean                          statusBarVisible             = false,
                                                    mobileAdsInitialized         = false;
    private static int                              statusBarHeight              = 0;
    private static VKGeoActivity                    instance                     = null;
    private static AdView                           adView                       = null;
    private static InterstitialAd                   interstitialAd               = null;
    private static HashMap<VKBatchRequest, Boolean> vkBatchRequestTracker        = new HashMap<VKBatchRequest, Boolean>();

    private static VKAccessTokenTracker vkAccessTokenTracker = new VKAccessTokenTracker() {
        @Override
        public void onVKAccessTokenChanged(VKAccessToken oldToken, VKAccessToken newToken) {
            if (newToken != null) {
                vkTokenChanged(true);
            } else {
                vkTokenChanged(false);
            }
        }
    };

    private static native void adViewHeightUpdated(int adview_height);

    private static native void vkTokenChanged(boolean valid);
    private static native void vkRequestComplete(String request, String response);
    private static native void vkRequestError(String request, String error_message);

    public VKGeoActivity()
    {
        instance = this;
    }

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        int resource_id = getResources().getIdentifier("status_bar_height", "dimen", "android");

        if (resource_id > 0) {
            statusBarHeight = getResources().getDimensionPixelSize(resource_id);
        }

        if ((getWindow().getDecorView().getSystemUiVisibility() & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
            statusBarVisible = true;
        } else {
            statusBarVisible = false;
        }

        getWindow().getDecorView().setOnSystemUiVisibilityChangeListener(new View.OnSystemUiVisibilityChangeListener() {
            @Override
            public void onSystemUiVisibilityChange(int visibility)
            {
                if ((visibility & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
                    statusBarVisible = true;

                    if (adView != null) {
                        int ad_visibility = adView.getVisibility();

                        adView.setVisibility(View.GONE);
                        adView.setY(statusBarHeight);
                        adView.setVisibility(ad_visibility);
                    }
                } else {
                    statusBarVisible = false;

                    if (adView != null) {
                        int ad_visibility = adView.getVisibility();

                        adView.setVisibility(View.GONE);
                        adView.setY(0);
                        adView.setVisibility(ad_visibility);
                    }
                }
            }
        });

        if (!mobileAdsInitialized) {
            MobileAds.initialize(this, ADMOB_APP_ID);

            mobileAdsInitialized = true;
        }
    }

    @Override
    public void onResume()
    {
        super.onResume();

        if (adView != null) {
            adView.resume();
        }
    }

    @Override
    public void onPause()
    {
        if (adView != null) {
            adView.pause();
        }

        super.onPause();
    }

    @Override
    public void onDestroy()
    {
        if (adView != null) {
            adView.destroy();

            adView = null;
        }

        super.onDestroy();
    }

    public static int getScreenDPI()
    {
        DisplayMetrics metrics = instance.getResources().getDisplayMetrics();

        return metrics.densityDpi;
    }

    public static void showAdView()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                View view = instance.getWindow().getDecorView().getRootView();

                if (view instanceof ViewGroup) {
                    ViewGroup view_group = (ViewGroup)view;

                    if (adView != null) {
                        view_group.removeView(adView);

                        adView.destroy();

                        adViewHeightUpdated(0);

                        adView = null;
                    }

                    FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT,
                                                                                   FrameLayout.LayoutParams.WRAP_CONTENT,
                                                                                   Gravity.CENTER_HORIZONTAL);

                    adView = new AdView(instance);

                    adView.setAdSize(ADMOB_ADVIEW_ADSIZE);
                    adView.setAdUnitId(ADMOB_ADVIEW_UNIT_ID);
                    adView.setLayoutParams(params);
                    adView.setVisibility(View.GONE);

                    if (statusBarVisible) {
                        adView.setY(statusBarHeight);
                    } else {
                        adView.setY(0);
                    }

                    adView.setAdListener(new AdListener() {
                        @Override
                        public void onAdLoaded()
                        {
                            if (adView != null) {
                                adView.setVisibility(View.VISIBLE);

                                adView.post(new Runnable() {
                                    @Override
                                    public void run()
                                    {
                                        if (adView != null) {
                                            adViewHeightUpdated(adView.getHeight());
                                        }
                                    }
                                });
                            }
                        }

                        @Override
                        public void onAdFailedToLoad(int errorCode)
                        {
                            if (adView != null) {
                                adView.setVisibility(View.VISIBLE);

                                adView.post(new Runnable() {
                                    @Override
                                    public void run()
                                    {
                                        if (adView != null) {
                                            adViewHeightUpdated(adView.getHeight());
                                        }
                                    }
                                });
                            }
                        }
                    });

                    view_group.addView(adView);

                    AdRequest.Builder builder = new AdRequest.Builder();

                    if (!ADMOB_TEST_DEVICE_ID.equals("")) {
                        builder.addTestDevice(ADMOB_TEST_DEVICE_ID);
                    }

                    adView.loadAd(builder.build());
                }
            }
        });
    }

    public static void hideAdView()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                View view = instance.getWindow().getDecorView().getRootView();

                if (view instanceof ViewGroup) {
                    ViewGroup view_group = (ViewGroup)view;

                    if (adView != null) {
                        view_group.removeView(adView);

                        adView.destroy();

                        adViewHeightUpdated(0);

                        adView = null;
                    }
                }
            }
        });
    }

    public static void createInterstitialAd()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                if (interstitialAd == null) {
                    interstitialAd = new InterstitialAd(instance);

                    interstitialAd.setAdUnitId(ADMOB_INTERSTITIALAD_UNIT_ID);

                    interstitialAd.setAdListener(new AdListener() {
                        @Override
                        public void onAdClosed()
                        {
                            if (interstitialAd != null) {
                                AdRequest.Builder builder = new AdRequest.Builder();

                                if (!ADMOB_TEST_DEVICE_ID.equals("")) {
                                    builder.addTestDevice(ADMOB_TEST_DEVICE_ID);
                                }

                                interstitialAd.loadAd(builder.build());
                            }
                        }

                        @Override
                        public void onAdFailedToLoad(int errorCode)
                        {
                            if (interstitialAd != null) {
                                new Handler().postDelayed(new Runnable() {
                                    @Override
                                    public void run()
                                    {
                                        if (interstitialAd != null) {
                                            AdRequest.Builder builder = new AdRequest.Builder();

                                            if (!ADMOB_TEST_DEVICE_ID.equals("")) {
                                                builder.addTestDevice(ADMOB_TEST_DEVICE_ID);
                                            }

                                            interstitialAd.loadAd(builder.build());
                                        }
                                    }
                                }, 60000);
                            }
                        }
                    });

                    AdRequest.Builder builder = new AdRequest.Builder();

                    if (!ADMOB_TEST_DEVICE_ID.equals("")) {
                        builder.addTestDevice(ADMOB_TEST_DEVICE_ID);
                    }

                    interstitialAd.loadAd(builder.build());
                }
            }
        });
    }

    public static void showInterstitialAd()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                if (interstitialAd != null && interstitialAd.isLoaded()) {
                    interstitialAd.show();
                }
            }
        });
    }

    public static void initVK()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                vkAccessTokenTracker.startTracking();

                VKSdk.initialize(instance);
            }
        });
    }

    public static void loginVK(String auth_scope)
    {
        final String f_auth_scope = auth_scope;

        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                try {
                    JSONArray         json_auth_scope = new JSONArray(f_auth_scope);
                    ArrayList<String> vk_auth_scope   = new ArrayList<String>();

                    for (int i = 0; i < json_auth_scope.length(); i++) {
                        vk_auth_scope.add(json_auth_scope.get(i).toString());
                    }

                    VKSdk.login(instance, vk_auth_scope.toArray(new String[vk_auth_scope.size()]));
                } catch (Exception ex) {
                    Log.w("VKGeoActivity", "loginVK() : " + ex.toString());
                }
            }
        });
    }

    public static void logoutVK()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                VKSdk.logout();
            }
        });
    }

    public static void executeVKBatch(String request_list)
    {
        final String f_request_list = request_list;

        instance.runOnUiThread(new Runnable() {
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

                            VKRequest vk_request = new VKRequest(json_request.getString("method"), VKParameters.from((Object[])vk_parameters.toArray(new String[vk_parameters.size()])));

                            vk_request.setRequestListener(new VKRequestListener() {
                                @Override
                                public void onComplete(VKResponse response) {
                                    vkRequestComplete(json_request.toString(), response.json.toString());
                                }

                                @Override
                                public void onError(VKError error) {
                                    vkRequestError(json_request.toString(), error.errorMessage);
                                }
                            });

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
        instance.runOnUiThread(new Runnable() {
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

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        VKSdk.onActivityResult(requestCode, resultCode, data, new VKCallback<VKAccessToken>() {
            @Override
            public void onResult(VKAccessToken token) {
            }

            @Override
            public void onError(VKError error) {
                Log.w("VKGeoActivity", error.errorMessage);
            }
        });
    }
}
