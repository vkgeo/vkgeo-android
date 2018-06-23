#include <QtAndroidExtras/QAndroidJniObject>

#include "admobhelper.h"
#include "vkhelper.h"

static void bannerViewHeightUpdated(JNIEnv *, jclass, jint height)
{
    AdMobHelper::setBannerViewHeight(height);
}

static void vkAuthChanged(JNIEnv *, jclass, jboolean authorized)
{
    if (authorized) {
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
    { "bannerViewHeightUpdated", "(I)V",                                    (void *)bannerViewHeightUpdated },
    { "vkAuthChanged",           "(Z)V",                                    (void *)vkAuthChanged },
    { "vkRequestComplete",       "(Ljava/lang/String;Ljava/lang/String;)V", (void *)vkRequestComplete },
    { "vkRequestError",          "(Ljava/lang/String;Ljava/lang/String;)V", (void *)vkRequestError }
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
