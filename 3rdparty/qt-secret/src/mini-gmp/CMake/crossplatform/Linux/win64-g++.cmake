#
# Copyright (C) 2018-2019 QuasarApp.
# Distributed under the MIT software license, see the accompanying
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.
#

if(DEFINED CROSSPLATFORM_BUILD_TOOLCHAIN_WIN_64)
  return()
else()
  set(CROSSPLATFORM_BUILD_TOOLCHAIN_WIN_64 1)
endif()

# the name of the target operating system
SET(BASE_COMPILLER_NAME w64-mingw32)
SET(PLATFORM_COMPILLER_NAME x86_64)


include(${CMAKE_CURRENT_LIST_DIR}/utils/win-base.cmake)

