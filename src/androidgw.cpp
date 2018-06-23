#include <QtAndroidExtras/QAndroidJniObject>

#include "vkhelper.h"

static void adViewHeightUpdated(JNIEnv *, jclass, jint adview_height)
{
    //emit AndroidGW::instance()->adViewHeightUpdated(adview_height);
}

static void vkTokenChanged(JNIEnv *, jclass, jboolean valid)
{
    if (valid) {
        VKHelper::setAuthState(VKAuthState::StateAuthorized);
    } else {
        VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
    }
}

static void vkRequestComplete(JNIEnv *jni_env, jclass, jstring j_request, jstring j_response)
{
    const char* request_str  = jni_env->GetStringUTFChars(j_request,  NULL);
    const char* response_str = jni_env->GetStringUTFChars(j_response, NULL);
    QString     request      = request_str;
    QString     response     = response_str;

    jni_env->ReleaseStringUTFChars(j_request,  request_str);
    jni_env->ReleaseStringUTFChars(j_response, response_str);

    VKHelper::processResponse(response, request);
}

static void vkRequestError(JNIEnv *jni_env, jclass, jstring j_request, jstring j_error_message)
{
    const char* request_str       = jni_env->GetStringUTFChars(j_request,       NULL);
    const char* error_message_str = jni_env->GetStringUTFChars(j_error_message, NULL);
    QString     request           = request_str;
    QString     error_message     = error_message_str;

    jni_env->ReleaseStringUTFChars(j_request,       request_str);
    jni_env->ReleaseStringUTFChars(j_error_message, error_message_str);

    VKHelper::processError(error_message, request);
}

static JNINativeMethod methods[] = {
    { "adViewHeightUpdated", "(I)V",                                   (void *)adViewHeightUpdated },
    { "vkTokenChanged",      "(Z)V",                                   (void *)vkTokenChanged },
    { "vkRequestComplete",   "(Ljava/lang/String;Ljava/lang/String)V", (void *)vkRequestComplete },
    { "vkRequestError",      "(Ljava/lang/String;Ljava/lang/String)V", (void *)vkRequestError }
};

jint JNICALL JNI_OnLoad(JavaVM *vm, void *)
{
    JNIEnv *env;

    if (vm->GetEnv(reinterpret_cast<void **>(&env), JNI_VERSION_1_4) == JNI_OK) {
        jclass clazz = env->FindClass("com/derevenetz/oleg/vkgeo/VKGeoActivity");

        if (env->RegisterNatives(clazz, methods, sizeof(methods) / sizeof(methods[0])) >= 0) {
            return JNI_VERSION_1_4;
        } else {
            return JNI_FALSE;
        }
    } else {
        return JNI_FALSE;
    }
}
