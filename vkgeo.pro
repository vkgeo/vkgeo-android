QT += quick quickcontrols2 sql location positioning purchasing
CONFIG += c++11

DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += src/main.cpp \
    src/androidgw.cpp \
    src/admobhelper.cpp \
    src/uihelper.cpp \
    src/vkhelper.cpp

HEADERS += \
    src/androidgw.h \
    src/admobhelper.h \
    src/uihelper.h \
    src/vkhelper.h

RESOURCES += \
    qml.qrc \
    resources.qrc \
    translations.qrc

TRANSLATIONS += \
    translations/vkgeo_ru.ts

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

android {
    QT += androidextras

    OTHER_FILES += \
        android/source/AndroidManifest.xml \
        android/source/res/drawable-hdpi/ic_launcher.png \
        android/source/res/drawable-mdpi/ic_launcher.png \
        android/source/res/drawable-xhdpi/ic_launcher.png \
        android/source/res/drawable-xxhdpi/ic_launcher.png \
        android/source/res/drawable-xxxhdpi/ic_launcher.png \
        android/source/res/values/numbers.xml \
        android/source/res/values/strings.xml \
        android/source/src/com/derevenetz/oleg/vkgeo/VKGeoActivity.java \
        android/source/src/com/derevenetz/oleg/vkgeo/VKGeoApplication.java \
        android/source/src/com/derevenetz/oleg/vkgeo/VKGeoService.java

    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android/source

    contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
        ANDROID_EXTRA_LIBS = \
            $$PWD/android/source/lib/armeabi-v7a/libcrypto.so \
            $$PWD/android/source/lib/armeabi-v7a/libssl.so
    }
}

# Default rules for deployment.
include(deployment.pri)
