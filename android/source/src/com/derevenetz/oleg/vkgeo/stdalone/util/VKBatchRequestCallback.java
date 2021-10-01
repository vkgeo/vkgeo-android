package com.derevenetz.oleg.vkgeo.stdalone.util;

public interface VKBatchRequestCallback
{
    void requestCompleted(String request, String response);
    void requestFailed(String request, String error_message);

    default void authorizationFailed()
    {
        // Ignore
    }
}
