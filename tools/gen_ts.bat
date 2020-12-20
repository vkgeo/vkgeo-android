SET PATH=%PATH%;C:\Qt\5.12.10\mingw73_64\bin;C:\Qt\Tools\mingw730_64\bin

lupdate -locations absolute ..\vkgeo.pro -ts ..\translations\vkgeo_ru.src.ts

lconvert ..\translations\vkgeo_ru.src.ts ..\translations\vkgeo_ru.qt.ts -o ..\translations\vkgeo_ru.ts
