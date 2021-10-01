package com.derevenetz.oleg.vkgeo.stdalone.util;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vk.sdk.api.VKError;
import com.vk.sdk.api.VKParameters;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKResponse;

public class VKBatchRequestManager
{
    private static final int   VK_API_ERROR_AUTHORIZATION_FAILED = 5;

    private boolean            canInteractWithUI                 = true;
    private HashSet<VKRequest> vkRequestTracker                  = new HashSet<>();

    public VKBatchRequestManager(boolean can_interact_with_ui)
    {
        canInteractWithUI = can_interact_with_ui;
    }

    public void execute(String request_list, VKBatchRequestCallback callback) throws org.json.JSONException
    {
        JSONArray json_request_list = new JSONArray(request_list);

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
                    Log.w("VKBatchRequestManager", "execute() : invalid request");
                }
            }

            execute_code.append("];");

            VKRequest vk_request = new VKRequest("execute", VKParameters.from("code", execute_code.toString()));

            vk_request.shouldInterruptUI = canInteractWithUI;

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
                                    callback.requestFailed(json_request_list.optString(i), error_str);
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
                                        callback.requestCompleted(json_request_list.optString(i), responses.get(i));
                                    }
                                } else {
                                    for (int i = 0; i < json_request_list.length(); i++) {
                                        callback.requestFailed(json_request_list.optString(i), error_str);
                                    }
                                }
                            } else {
                                for (int i = 0; i < json_request_list.length(); i++) {
                                    callback.requestCompleted(json_request_list.optString(i), "");
                                }
                            }
                        } else {
                            for (int i = 0; i < json_request_list.length(); i++) {
                                callback.requestCompleted(json_request_list.optString(i), "");
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

                            if (error.errorCode == VKError.VK_API_ERROR && error.apiError != null &&
                                                                           error.apiError.errorCode == VK_API_ERROR_AUTHORIZATION_FAILED) {
                                callback.authorizationFailed();
                            }
                        }

                        for (int i = 0; i < json_request_list.length(); i++) {
                            callback.requestFailed(json_request_list.optString(i), error_str);
                        }
                    }
                }
            });
        }
    }

    public void cancelAll()
    {
        Iterator<VKRequest> vk_request_tracker_keys_iter = new HashSet<>(vkRequestTracker).iterator();

        while (vk_request_tracker_keys_iter.hasNext()) {
            vk_request_tracker_keys_iter.next().cancel();
        }
    }
}
