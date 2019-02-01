PATH=%PATH%;C:\Qt\5.12.1\mingw73_64\bin;C:\Qt\Tools\mingw730_64\bin

lupdate ..\vkgeo.pro -ts ..\translations\vkgeo_ru.src.ts
lupdate ..\qml       -ts ..\translations\vkgeo_ru.qml.ts

lconvert ..\translations\vkgeo_ru.src.ts ..\translations\vkgeo_ru.qml.ts -o ..\translations\vkgeo_ru.ts
