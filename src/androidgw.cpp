#include <QtAndroidExtras/QAndroidJniObject>

#include "vkhelper.h"

#include "androidgw.h"

#define JAVA_NATIVE_METHOD_NAME(class_name, method_name) Java_com_derevenetz_oleg_vkgeo_gplay_ ## class_name ## _ ## method_name

AndroidGW::AndroidGW(QObject *parent) :
    QObject(parent)
{
}

AndroidGW &AndroidGW::GetInstance()
{
    static AndroidGW instance;

    return instance;
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoActivity, deviceConfigurationUpdated)(JNIEnv *, jclass)
{
    emit AndroidGW::GetInstance().deviceConfigurationUpdated();
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoActivity, vkAuthUpdated)(JNIEnv *, jclass, jboolean authorized)
{
    if (authorized) {
        emit AndroidGW::GetInstance().authStateUpdated(VKAuthState::StateAuthorized);
    } else {
        emit AndroidGW::GetInstance().authStateUpdated(VKAuthState::StateNotAuthorized);
    }
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoActivity, vkRequestCompleted)(JNIEnv *jni_env, jclass, jstring j_request, jstring j_response)
{
    const char *request_str  = jni_env->GetStringUTFChars(j_request,  nullptr);
    const char *response_str = jni_env->GetStringUTFChars(j_response, nullptr);
    QString     request      = QString::fromUtf8(request_str);
    QString     response     = QString::fromUtf8(response_str);

    jni_env->ReleaseStringUTFChars(j_request,  request_str);
    jni_env->ReleaseStringUTFChars(j_response, response_str);

    emit AndroidGW::GetInstance().vkRequestCompleted(response, request);
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoActivity, vkRequestFailed)(JNIEnv *jni_env, jclass, jstring j_request, jstring j_error_message)
{
    const char *request_str       = jni_env->GetStringUTFChars(j_request,       nullptr);
    const char *error_message_str = jni_env->GetStringUTFChars(j_error_message, nullptr);
    QString     request           = QString::fromUtf8(request_str);
    QString     error_message     = QString::fromUtf8(error_message_str);

    jni_env->ReleaseStringUTFChars(j_request,       request_str);
    jni_env->ReleaseStringUTFChars(j_error_message, error_message_str);

    emit AndroidGW::GetInstance().vkRequestFailed(error_message, request);
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoService, settingsUpdated)(JNIEnv *, jclass)
{
    emit AndroidGW::GetInstance().settingsUpdated();
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoService, locationUpdated)(JNIEnv *, jclass, jdouble latitude, jdouble longitude)
{
    emit AndroidGW::GetInstance().locationUpdated(latitude, longitude);
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoService, batteryStatusUpdated)(JNIEnv *jni_env, jclass, jstring j_status, jint level)
{
    const char *status_str = jni_env->GetStringUTFChars(j_status, nullptr);
    QString     status     = QString::fromUtf8(status_str);

    jni_env->ReleaseStringUTFChars(j_status, status_str);

    emit AndroidGW::GetInstance().batteryStatusUpdated(status, level);
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoService, vkAuthUpdated)(JNIEnv *, jclass, jboolean authorized)
{
    if (authorized) {
        emit AndroidGW::GetInstance().authStateUpdated(VKAuthState::StateAuthorized);
    } else {
        emit AndroidGW::GetInstance().authStateUpdated(VKAuthState::StateNotAuthorized);
    }
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoService, vkRequestCompleted)(JNIEnv *jni_env, jclass, jstring j_request, jstring j_response)
{
    const char *request_str  = jni_env->GetStringUTFChars(j_request,  nullptr);
    const char *response_str = jni_env->GetStringUTFChars(j_response, nullptr);
    QString     request      = QString::fromUtf8(request_str);
    QString     response     = QString::fromUtf8(response_str);

    jni_env->ReleaseStringUTFChars(j_request,  request_str);
    jni_env->ReleaseStringUTFChars(j_response, response_str);

    emit AndroidGW::GetInstance().vkRequestCompleted(response, request);
}

extern "C" JNIEXPORT void JNICALL JAVA_NATIVE_METHOD_NAME(VKGeoService, vkRequestFailed)(JNIEnv *jni_env, jclass, jstring j_request, jstring j_error_message)
{
    const char *request_str       = jni_env->GetStringUTFChars(j_request,       nullptr);
    const char *error_message_str = jni_env->GetStringUTFChars(j_error_message, nullptr);
    QString     request           = QString::fromUtf8(request_str);
    QString     error_message     = QString::fromUtf8(error_message_str);

    jni_env->ReleaseStringUTFChars(j_request,       request_str);
    jni_env->ReleaseStringUTFChars(j_error_message, error_message_str);

    emit AndroidGW::GetInstance().vkRequestFailed(error_message, request);
}
