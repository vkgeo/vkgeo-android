#include <QtAndroidExtras/QAndroidJniObject>

#include "androidgw.h"
#include "vkhelper.h"

AndroidGW *AndroidGW::Instance = nullptr;

AndroidGW::AndroidGW(QObject *parent) : QObject(parent)
{
    Instance = this;
}

AndroidGW::~AndroidGW()
{
}

AndroidGW *AndroidGW::instance()
{
    return Instance;
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoActivity_bannerViewHeightUpdated(JNIEnv *, jclass, jint height)
{
    emit AndroidGW::instance()->setBannerViewHeight(height);
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoActivity_vkAuthChanged(JNIEnv *, jclass, jboolean authorized)
{
    if (authorized) {
        emit AndroidGW::instance()->setAuthState(VKAuthState::StateAuthorized);
    } else {
        emit AndroidGW::instance()->setAuthState(VKAuthState::StateNotAuthorized);
    }
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoActivity_vkRequestComplete(JNIEnv *jni_env, jclass, jstring j_request, jstring j_response)
{
    const char* request_str  = jni_env->GetStringUTFChars(j_request,  nullptr);
    const char* response_str = jni_env->GetStringUTFChars(j_response, nullptr);
    QString     request      = request_str;
    QString     response     = response_str;

    jni_env->ReleaseStringUTFChars(j_request,  request_str);
    jni_env->ReleaseStringUTFChars(j_response, response_str);

    emit AndroidGW::instance()->processResponse(response, request);
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoActivity_vkRequestError(JNIEnv *jni_env, jclass, jstring j_request, jstring j_error_message)
{
    const char* request_str       = jni_env->GetStringUTFChars(j_request,       nullptr);
    const char* error_message_str = jni_env->GetStringUTFChars(j_error_message, nullptr);
    QString     request           = request_str;
    QString     error_message     = error_message_str;

    jni_env->ReleaseStringUTFChars(j_request,       request_str);
    jni_env->ReleaseStringUTFChars(j_error_message, error_message_str);

    emit AndroidGW::instance()->processError(error_message, request);
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoService_locationUpdated(JNIEnv *, jclass, jdouble latitude, jdouble longitude)
{
    emit AndroidGW::instance()->processLocationUpdate(latitude, longitude);
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoService_batteryStatusUpdated(JNIEnv *jni_env, jclass, jstring j_status, jint level)
{
    const char* status_str = jni_env->GetStringUTFChars(j_status, nullptr);
    QString     status     = status_str;

    jni_env->ReleaseStringUTFChars(j_status, status_str);

    emit AndroidGW::instance()->processBatteryStatusUpdate(status, level);
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoService_vkAuthChanged(JNIEnv *, jclass, jboolean authorized)
{
    if (authorized) {
        emit AndroidGW::instance()->setAuthState(VKAuthState::StateAuthorized);
    } else {
        emit AndroidGW::instance()->setAuthState(VKAuthState::StateNotAuthorized);
    }
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoService_vkRequestComplete(JNIEnv *jni_env, jclass, jstring j_request, jstring j_response)
{
    const char* request_str  = jni_env->GetStringUTFChars(j_request,  nullptr);
    const char* response_str = jni_env->GetStringUTFChars(j_response, nullptr);
    QString     request      = request_str;
    QString     response     = response_str;

    jni_env->ReleaseStringUTFChars(j_request,  request_str);
    jni_env->ReleaseStringUTFChars(j_response, response_str);

    emit AndroidGW::instance()->processResponse(response, request);
}

extern "C" JNIEXPORT void JNICALL Java_com_derevenetz_oleg_vkgeoapp_VKGeoService_vkRequestError(JNIEnv *jni_env, jclass, jstring j_request, jstring j_error_message)
{
    const char* request_str       = jni_env->GetStringUTFChars(j_request,       nullptr);
    const char* error_message_str = jni_env->GetStringUTFChars(j_error_message, nullptr);
    QString     request           = request_str;
    QString     error_message     = error_message_str;

    jni_env->ReleaseStringUTFChars(j_request,       request_str);
    jni_env->ReleaseStringUTFChars(j_error_message, error_message_str);

    emit AndroidGW::instance()->processError(error_message, request);
}
