TEMPLATE = app
TARGET = vkgeo

QT += quick quickcontrols2 location positioning purchasing
CONFIG += c++17

DEFINES += QT_DEPRECATED_WARNINGS QT_NO_CAST_FROM_ASCII QT_NO_CAST_TO_ASCII

INCLUDEPATH += \
    3rdparty/libsodium/include

SOURCES += \
    src/androidgw.cpp \
    src/appsettings.cpp \
    src/batteryhelper.cpp \
    src/cryptohelper.cpp \
    src/gplayhelper.cpp \
    src/main.cpp \
    src/uihelper.cpp \
    src/vkhelper.cpp \
    src/vkservice.cpp

HEADERS += \
    3rdparty/libsodium/include/sodium.h \
    3rdparty/libsodium/include/sodium/core.h \
    3rdparty/libsodium/include/sodium/crypto_aead_aes256gcm.h \
    3rdparty/libsodium/include/sodium/crypto_aead_chacha20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_aead_xchacha20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_auth.h \
    3rdparty/libsodium/include/sodium/crypto_auth_hmacsha256.h \
    3rdparty/libsodium/include/sodium/crypto_auth_hmacsha512.h \
    3rdparty/libsodium/include/sodium/crypto_auth_hmacsha512256.h \
    3rdparty/libsodium/include/sodium/crypto_box.h \
    3rdparty/libsodium/include/sodium/crypto_box_curve25519xchacha20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_box_curve25519xsalsa20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_core_ed25519.h \
    3rdparty/libsodium/include/sodium/crypto_core_hchacha20.h \
    3rdparty/libsodium/include/sodium/crypto_core_hsalsa20.h \
    3rdparty/libsodium/include/sodium/crypto_core_ristretto255.h \
    3rdparty/libsodium/include/sodium/crypto_core_salsa20.h \
    3rdparty/libsodium/include/sodium/crypto_core_salsa2012.h \
    3rdparty/libsodium/include/sodium/crypto_core_salsa208.h \
    3rdparty/libsodium/include/sodium/crypto_generichash.h \
    3rdparty/libsodium/include/sodium/crypto_generichash_blake2b.h \
    3rdparty/libsodium/include/sodium/crypto_hash.h \
    3rdparty/libsodium/include/sodium/crypto_hash_sha256.h \
    3rdparty/libsodium/include/sodium/crypto_hash_sha512.h \
    3rdparty/libsodium/include/sodium/crypto_kdf.h \
    3rdparty/libsodium/include/sodium/crypto_kdf_blake2b.h \
    3rdparty/libsodium/include/sodium/crypto_kx.h \
    3rdparty/libsodium/include/sodium/crypto_onetimeauth.h \
    3rdparty/libsodium/include/sodium/crypto_onetimeauth_poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_pwhash.h \
    3rdparty/libsodium/include/sodium/crypto_pwhash_argon2i.h \
    3rdparty/libsodium/include/sodium/crypto_pwhash_argon2id.h \
    3rdparty/libsodium/include/sodium/crypto_pwhash_scryptsalsa208sha256.h \
    3rdparty/libsodium/include/sodium/crypto_scalarmult.h \
    3rdparty/libsodium/include/sodium/crypto_scalarmult_curve25519.h \
    3rdparty/libsodium/include/sodium/crypto_scalarmult_ed25519.h \
    3rdparty/libsodium/include/sodium/crypto_scalarmult_ristretto255.h \
    3rdparty/libsodium/include/sodium/crypto_secretbox.h \
    3rdparty/libsodium/include/sodium/crypto_secretbox_xchacha20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_secretbox_xsalsa20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_secretstream_xchacha20poly1305.h \
    3rdparty/libsodium/include/sodium/crypto_shorthash.h \
    3rdparty/libsodium/include/sodium/crypto_shorthash_siphash24.h \
    3rdparty/libsodium/include/sodium/crypto_sign.h \
    3rdparty/libsodium/include/sodium/crypto_sign_ed25519.h \
    3rdparty/libsodium/include/sodium/crypto_sign_edwards25519sha512batch.h \
    3rdparty/libsodium/include/sodium/crypto_stream.h \
    3rdparty/libsodium/include/sodium/crypto_stream_chacha20.h \
    3rdparty/libsodium/include/sodium/crypto_stream_salsa20.h \
    3rdparty/libsodium/include/sodium/crypto_stream_salsa2012.h \
    3rdparty/libsodium/include/sodium/crypto_stream_salsa208.h \
    3rdparty/libsodium/include/sodium/crypto_stream_xchacha20.h \
    3rdparty/libsodium/include/sodium/crypto_stream_xsalsa20.h \
    3rdparty/libsodium/include/sodium/crypto_verify_16.h \
    3rdparty/libsodium/include/sodium/crypto_verify_32.h \
    3rdparty/libsodium/include/sodium/crypto_verify_64.h \
    3rdparty/libsodium/include/sodium/export.h \
    3rdparty/libsodium/include/sodium/randombytes.h \
    3rdparty/libsodium/include/sodium/randombytes_internal_random.h \
    3rdparty/libsodium/include/sodium/randombytes_sysrandom.h \
    3rdparty/libsodium/include/sodium/runtime.h \
    3rdparty/libsodium/include/sodium/utils.h \
    3rdparty/libsodium/include/sodium/version.h \
    src/androidgw.h \
    src/appsettings.h \
    src/batteryhelper.h \
    src/cryptohelper.h \
    src/gplayhelper.h \
    src/uihelper.h \
    src/vkhelper.h \
    src/vkservice.h

RESOURCES += \
    qml.qrc \
    resources.qrc \
    translations.qrc

TRANSLATIONS += \
    translations/vkgeo_ru.ts

QMAKE_CFLAGS += $$(QMAKE_CFLAGS_ENV)
QMAKE_CXXFLAGS += $$(QMAKE_CXXFLAGS_ENV)
QMAKE_LFLAGS += $$(QMAKE_LFLAGS_ENV)

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

android {
    QT += androidextras

    CONFIG(release, debug|release) {
        CONFIG += qtquickcompiler
    }

    OTHER_FILES += \
        android/source/AndroidManifest.xml \
        android/source/build.gradle \
        android/source/gradle.properties \
        android/source/gradlew \
        android/source/gradlew.bat \
        android/source/settings.gradle \
        android/source/3rdparty/vksdk_library/LICENSE \
        android/source/3rdparty/vksdk_library/build.gradle \
        android/source/3rdparty/vksdk_library/gradle.properties \
        android/source/3rdparty/vksdk_library/src/main/AndroidManifest.xml \
        android/source/3rdparty/vksdk_library/src/main/lint.xml \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKAccessToken.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKAccessTokenTracker.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKCallback.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKObject.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKScope.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKSdk.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKSdkVersion.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKServiceActivity.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/VKUIHelper.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/WebView.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKApi.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKApiConst.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKBatchRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKDefaultParser.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKError.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKParameters.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKParser.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKResponse.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKSyncRequestUtil.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/VKUploadBase.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/docs/VKUploadDocBase.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/docs/VKUploadDocRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/docs/VKUploadWallDocRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKAbstractOperation.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKHttpClient.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKHttpOperation.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKImageOperation.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKJsonOperation.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKModelOperation.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/httpClient/VKMultipartEntity.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiAudio.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiBase.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiCaptcha.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiDocs.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiFriends.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiGroups.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiMessages.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiPhotos.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiUsers.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiVideo.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/methods/VKApiWall.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/Identifiable.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/ParseUtils.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiApplicationContent.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiAudio.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiChat.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiCity.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiComment.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiCommunity.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiCommunityArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiCommunityFull.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiCountry.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiDialog.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiDocument.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiGetDialogResponse.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiGetMessagesResponse.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiLink.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiMessage.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiModel.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiNote.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiOwner.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPhoto.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPhotoAlbum.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPhotoSize.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPlace.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPoll.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPost.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiPostedPhoto.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiSchool.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiUniversity.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiUser.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiUserFull.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiVideo.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKApiWikiPage.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKAttachments.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKCommentArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKDocsArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKList.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKNotesArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKPhotoArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKPhotoSizes.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKPostArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKPrivacy.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKScopes.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKUsersArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VKWallPostResult.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VkAudioArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/VkVideoArray.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/model/package-info.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/photo/VKImageParameters.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/photo/VKUploadAlbumPhotoRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/photo/VKUploadImage.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/photo/VKUploadMessagesPhotoRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/photo/VKUploadPhotoBase.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/api/photo/VKUploadWallPhotoRequest.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/dialogs/VKCaptchaDialog.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/dialogs/VKOpenAuthDialog.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/dialogs/VKShareDialog.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/dialogs/VKShareDialogBuilder.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/dialogs/VKShareDialogDelegate.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/dialogs/VKShareDialogNative.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/util/VKJsonHelper.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/util/VKStringJoiner.java \
        android/source/3rdparty/vksdk_library/src/main/java/com/vk/sdk/util/VKUtil.java \
        android/source/3rdparty/vksdk_library/src/main/res/drawable/vk_clear_shape.xml \
        android/source/3rdparty/vksdk_library/src/main/res/drawable/vk_gray_transparent_shape.xml \
        android/source/3rdparty/vksdk_library/src/main/res/drawable/vk_share_send_button_background.xml \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-hdpi/bg_toolbar_shadow_dark.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-hdpi/ic_ab_app.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-hdpi/ic_close_white_24dp.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-mdpi/bg_toolbar_shadow_dark.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-mdpi/ic_ab_app.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-mdpi/ic_close_white_24dp.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xhdpi/bg_toolbar_shadow_dark.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xhdpi/ic_ab_app.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xhdpi/ic_close_white_24dp.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xxhdpi/bg_toolbar_shadow_dark.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xxhdpi/ic_ab_app.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xxhdpi/ic_close_white_24dp.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xxxhdpi/bg_toolbar_shadow_dark.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xxxhdpi/ic_ab_app.png \
        android/source/3rdparty/vksdk_library/src/main/res/drawable-xxxhdpi/ic_close_white_24dp.png \
        android/source/3rdparty/vksdk_library/src/main/res/layout/vk_captcha_dialog.xml \
        android/source/3rdparty/vksdk_library/src/main/res/layout/vk_open_auth_dialog.xml \
        android/source/3rdparty/vksdk_library/src/main/res/layout/vk_share_dialog.xml \
        android/source/3rdparty/vksdk_library/src/main/res/layout-v16/vk_share_dialog.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values/color.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values/dimen.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values/strings.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values/styles.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values-ru/strings.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values-v11/styles.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values-v21/styles.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values-w600dp/dimen.xml \
        android/source/3rdparty/vksdk_library/src/main/res/values-w720dp/dimen.xml \
        android/source/gradle/wrapper/gradle-wrapper.jar \
        android/source/gradle/wrapper/gradle-wrapper.properties \
        android/source/res/drawable/splash_qt.xml \
        android/source/res/drawable/splash_theme.xml \
        android/source/res/drawable-hdpi/ic_launcher_foreground.png \
        android/source/res/drawable-hdpi/ic_splash_qt.png \
        android/source/res/drawable-hdpi/ic_splash_theme.png \
        android/source/res/drawable-hdpi/ic_stat_notify_service.png \
        android/source/res/drawable-mdpi/ic_launcher_foreground.png \
        android/source/res/drawable-mdpi/ic_splash_qt.png \
        android/source/res/drawable-mdpi/ic_splash_theme.png \
        android/source/res/drawable-mdpi/ic_stat_notify_service.png \
        android/source/res/drawable-xhdpi/ic_launcher_foreground.png \
        android/source/res/drawable-xhdpi/ic_splash_qt.png \
        android/source/res/drawable-xhdpi/ic_splash_theme.png \
        android/source/res/drawable-xhdpi/ic_stat_notify_service.png \
        android/source/res/drawable-xxhdpi/ic_launcher_foreground.png \
        android/source/res/drawable-xxhdpi/ic_splash_qt.png \
        android/source/res/drawable-xxhdpi/ic_splash_theme.png \
        android/source/res/drawable-xxhdpi/ic_stat_notify_service.png \
        android/source/res/drawable-xxxhdpi/ic_launcher_foreground.png \
        android/source/res/drawable-xxxhdpi/ic_splash_qt.png \
        android/source/res/drawable-xxxhdpi/ic_splash_theme.png \
        android/source/res/drawable-xxxhdpi/ic_stat_notify_service.png \
        android/source/res/mipmap-anydpi-v26/ic_launcher.xml \
        android/source/res/mipmap-hdpi/ic_launcher.png \
        android/source/res/mipmap-mdpi/ic_launcher.png \
        android/source/res/mipmap-xhdpi/ic_launcher.png \
        android/source/res/mipmap-xxhdpi/ic_launcher.png \
        android/source/res/mipmap-xxxhdpi/ic_launcher.png \
        android/source/res/values/colors.xml \
        android/source/res/values/libs.xml \
        android/source/res/values/numbers.xml \
        android/source/res/values/strings.xml \
        android/source/res/values/styles.xml \
        android/source/res/values-ru/strings.xml \
        android/source/res/xml/backup_content.xml \
        android/source/src/com/derevenetz/oleg/vkgeo/gplay/VKGeoActivity.java \
        android/source/src/com/derevenetz/oleg/vkgeo/gplay/VKGeoApplication.java \
        android/source/src/com/derevenetz/oleg/vkgeo/gplay/VKGeoReceiver.java \
        android/source/src/com/derevenetz/oleg/vkgeo/gplay/VKGeoService.java

    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android/source

    contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
        LIBS += -L$$PWD/android/3rdparty/libsodium/armeabi-v7a -lsodium

        ANDROID_EXTRA_LIBS = \
            $$PWD/android/3rdparty/libsodium/armeabi-v7a/libsodium.so \
            $$PWD/android/3rdparty/openssl/armeabi-v7a/libcrypto_1_1.so \
            $$PWD/android/3rdparty/openssl/armeabi-v7a/libssl_1_1.so
    }

    contains(ANDROID_TARGET_ARCH,arm64-v8a) {
        LIBS += -L$$PWD/android/3rdparty/libsodium/arm64-v8a -lsodium

        ANDROID_EXTRA_LIBS = \
            $$PWD/android/3rdparty/libsodium/arm64-v8a/libsodium.so \
            $$PWD/android/3rdparty/openssl/arm64-v8a/libcrypto_1_1.so \
            $$PWD/android/3rdparty/openssl/arm64-v8a/libssl_1_1.so
    }
}
