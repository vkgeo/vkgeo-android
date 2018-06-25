package com.derevenetz.oleg.vkgeo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Process;
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
    private static boolean                          statusBarVisible      = false;
    private static int                              statusBarHeight       = 0;
    private static VKGeoActivity                    instance              = null;
    private static AdView                           bannerView            = null;
    private static InterstitialAd                   interstitial          = null;
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

    private static native void bannerViewHeightUpdated(int height);

    private static native void vkAuthChanged(boolean authorized);
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

                    if (bannerView != null) {
                        int banner_visibility = bannerView.getVisibility();

                        bannerView.setVisibility(View.GONE);
                        bannerView.setY(statusBarHeight);
                        bannerView.setVisibility(banner_visibility);
                    }
                } else {
                    statusBarVisible = false;

                    if (bannerView != null) {
                        int banner_visibility = bannerView.getVisibility();

                        bannerView.setVisibility(View.GONE);
                        bannerView.setY(0);
                        bannerView.setVisibility(banner_visibility);
                    }
                }
            }
        });
    }

    @Override
    public void onResume()
    {
        super.onResume();

        if (bannerView != null) {
            bannerView.resume();
        }
    }

    @Override
    public void onPause()
    {
        if (bannerView != null) {
            bannerView.pause();
        }

        super.onPause();
    }

    @Override
    public void onDestroy()
    {
        if (bannerView != null) {
            bannerView.destroy();

            bannerView = null;
        }

       /*
        * This call hangs when foreground service is running,
        * so we just kill activity process instead (service
        * is running in a different process).
        *
        * super.onDestroy();
        */

        Process.killProcess(Process.myPid());
    }

    public static int getScreenDPI()
    {
        DisplayMetrics metrics = instance.getResources().getDisplayMetrics();

        return metrics.densityDpi;
    }

    public static void initAds(String app_id, String interstitial_unit_id)
    {
        final String f_app_id               = app_id;
        final String f_interstitial_unit_id = interstitial_unit_id;

        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                MobileAds.initialize(instance, f_app_id);

                interstitial = new InterstitialAd(instance);

                interstitial.setAdUnitId(f_interstitial_unit_id);

                interstitial.setAdListener(new AdListener() {
                    @Override
                    public void onAdClosed()
                    {
                        if (interstitial != null) {
                            AdRequest.Builder builder = new AdRequest.Builder();

                            interstitial.loadAd(builder.build());
                        }
                    }

                    @Override
                    public void onAdFailedToLoad(int errorCode)
                    {
                        if (interstitial != null) {
                            new Handler().postDelayed(new Runnable() {
                                @Override
                                public void run()
                                {
                                    if (interstitial != null) {
                                        AdRequest.Builder builder = new AdRequest.Builder();

                                        interstitial.loadAd(builder.build());
                                    }
                                }
                            }, 60000);
                        }
                    }
                });

                AdRequest.Builder builder = new AdRequest.Builder();

                interstitial.loadAd(builder.build());
            }
        });
    }

    public static void showBannerView(String unit_id)
    {
        final String f_unit_id = unit_id;

        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                View view = instance.getWindow().getDecorView().getRootView();

                if (view instanceof ViewGroup) {
                    ViewGroup view_group = (ViewGroup)view;

                    if (bannerView != null) {
                        view_group.removeView(bannerView);

                        bannerView.destroy();

                        bannerViewHeightUpdated(0);

                        bannerView = null;
                    }

                    FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT,
                                                                                   FrameLayout.LayoutParams.WRAP_CONTENT,
                                                                                   Gravity.CENTER_HORIZONTAL);

                    bannerView = new AdView(instance);

                    bannerView.setAdSize(AdSize.SMART_BANNER);
                    bannerView.setAdUnitId(f_unit_id);
                    bannerView.setLayoutParams(params);
                    bannerView.setVisibility(View.GONE);

                    if (statusBarVisible) {
                        bannerView.setY(statusBarHeight);
                    } else {
                        bannerView.setY(0);
                    }

                    bannerView.setAdListener(new AdListener() {
                        @Override
                        public void onAdLoaded()
                        {
                            if (bannerView != null) {
                                bannerView.setVisibility(View.VISIBLE);

                                bannerView.post(new Runnable() {
                                    @Override
                                    public void run()
                                    {
                                        if (bannerView != null) {
                                            bannerViewHeightUpdated(bannerView.getHeight());
                                        }
                                    }
                                });
                            }
                        }

                        @Override
                        public void onAdFailedToLoad(int errorCode)
                        {
                            if (bannerView != null) {
                                bannerView.setVisibility(View.VISIBLE);

                                bannerView.post(new Runnable() {
                                    @Override
                                    public void run()
                                    {
                                        if (bannerView != null) {
                                            bannerViewHeightUpdated(bannerView.getHeight());
                                        }
                                    }
                                });
                            }
                        }
                    });

                    view_group.addView(bannerView);

                    AdRequest.Builder builder = new AdRequest.Builder();

                    bannerView.loadAd(builder.build());
                }
            }
        });
    }

    public static void hideBannerView()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                View view = instance.getWindow().getDecorView().getRootView();

                if (view instanceof ViewGroup) {
                    ViewGroup view_group = (ViewGroup)view;

                    if (bannerView != null) {
                        view_group.removeView(bannerView);

                        bannerView.destroy();

                        bannerViewHeightUpdated(0);

                        bannerView = null;
                    }
                }
            }
        });
    }

    public static void showInterstitial()
    {
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run()
            {
                if (interstitial != null && interstitial.isLoaded()) {
                    interstitial.show();
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
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        super.onActivityResult(requestCode, resultCode, data);

        VKSdk.onActivityResult(requestCode, resultCode, data, new VKCallback<VKAccessToken>() {
            @Override
            public void onResult(VKAccessToken token) {
            }

            @Override
            public void onError(VKError error) {
                Log.w("VKGeoActivity", error.toString());
            }
        });
    }
}
