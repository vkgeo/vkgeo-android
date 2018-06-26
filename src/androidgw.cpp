#include <QtAndroidExtras/QAndroidJniObject>

#include "androidgw.h"
#include "vkhelper.h"

AndroidGW *AndroidGW::Instance = NULL;

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

static void bannerViewHeightUpdated(JNIEnv *, jclass, jint height)
{
    emit AndroidGW::instance()->setBannerViewHeight(height);
}

static void locationUpdated(JNIEnv *, jclass, jdouble latitude, jdouble longitude)
{
    emit AndroidGW::instance()->processLocationUpdate(latitude, longitude);
}

static void vkAuthChanged(JNIEnv *, jclass, jboolean authorized)
{
    if (authorized) {
        emit AndroidGW::instance()->setAuthState(VKAuthState::StateAuthorized);
    } else {
        emit AndroidGW::instance()->setAuthState(VKAuthState::StateNotAuthorized);
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

    emit AndroidGW::instance()->processResponse(response, request);
}

static void vkRequestError(JNIEnv *jni_env, jclass, jstring j_request, jstring j_error_message)
{
    const char* request_str       = jni_env->GetStringUTFChars(j_request,       NULL);
    const char* error_message_str = jni_env->GetStringUTFChars(j_error_message, NULL);
    QString     request           = request_str;
    QString     error_message     = error_message_str;

    jni_env->ReleaseStringUTFChars(j_request,       request_str);
    jni_env->ReleaseStringUTFChars(j_error_message, error_message_str);

    emit AndroidGW::instance()->processError(error_message, request);
}

static JNINativeMethod activity_methods[] = {
    { "bannerViewHeightUpdated", "(I)V",                                    (void *)bannerViewHeightUpdated },
    { "vkAuthChanged",           "(Z)V",                                    (void *)vkAuthChanged },
    { "vkRequestComplete",       "(Ljava/lang/String;Ljava/lang/String;)V", (void *)vkRequestComplete },
    { "vkRequestError",          "(Ljava/lang/String;Ljava/lang/String;)V", (void *)vkRequestError }
};
static int activity_methods_count = 4;

static JNINativeMethod service_methods[] = {
    { "locationUpdated",   "(DD)V",                                   (void *)locationUpdated },
    { "vkAuthChanged",     "(Z)V",                                    (void *)vkAuthChanged },
    { "vkRequestComplete", "(Ljava/lang/String;Ljava/lang/String;)V", (void *)vkRequestComplete },
    { "vkRequestError",    "(Ljava/lang/String;Ljava/lang/String;)V", (void *)vkRequestError }
};
static int service_methods_count = 4;

jint JNICALL JNI_OnLoad(JavaVM *vm, void *)
{
    JNIEnv *env;

    if (vm->GetEnv(reinterpret_cast<void **>(&env), JNI_VERSION_1_4) == JNI_OK) {
        bool   success        = true;
        jclass activity_clazz = env->FindClass("com/derevenetz/oleg/vkgeo/VKGeoActivity");
        jclass service_clazz  = env->FindClass("com/derevenetz/oleg/vkgeo/VKGeoService");

        if (activity_clazz != NULL) {
            success = false;

            if (env->RegisterNatives(activity_clazz, activity_methods, activity_methods_count) >= 0) {
                success = true;
            }
        }
        if (service_clazz != NULL) {
            success = false;

            if (env->RegisterNatives(service_clazz, service_methods, service_methods_count) >= 0) {
                success = true;
            }
        }

        if (success) {
            return JNI_VERSION_1_4;
        } else {
            return JNI_FALSE;
        }
    } else {
        return JNI_FALSE;
    }
}
