#
# Copyright (C) 2018-2020 QuasarApp.
# Distributed under the MIT software license, see the accompanying
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.
#

if(DEFINED CROSSPLATFORM_BUILD_TOOLCHAIN)
  return()
else()
  set(CROSSPLATFORM_BUILD_TOOLCHAIN 1)
endif()

# use TRGET_PLATFORM_LOOLCHAIN

set(CROSSPLATFORM_BUILD_TOOLCHAIN_PATH ${CMAKE_CURRENT_LIST_DIR}/${CMAKE_HOST_SYSTEM_NAME}/${TRGET_PLATFORM_TOOLCHAIN}.cmake)

if(EXISTS ${CROSSPLATFORM_BUILD_TOOLCHAIN_PATH})

    message("${TRGET_PLATFORM_TOOLCHAIN} exits in ${CROSSPLATFORM_BUILD_TOOLCHAIN_PATH}")
    
    include(${CROSSPLATFORM_BUILD_TOOLCHAIN_PATH})
    
else(EXISTS ${CROSSPLATFORM_BUILD_TOOLCHAIN_PATH})
    message("${TRGET_PLATFORM_TOOLCHAIN} not exits in ${CROSSPLATFORM_BUILD_TOOLCHAIN_PATH}")
endif()

