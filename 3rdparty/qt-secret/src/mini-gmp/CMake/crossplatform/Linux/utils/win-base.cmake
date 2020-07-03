#
# Copyright (C) 2018-2019 QuasarApp.
# Distributed under the MIT software license, see the accompanying
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.
#

if(DEFINED CROSSPLATFORM_BUILD_TOOLCHAIN_WIN_BASE)
  return()
else()
  set(CROSSPLATFORM_BUILD_TOOLCHAIN_WIN_BASE 1)
endif()

# the name of the target operating system
SET(CMAKE_SYSTEM_NAME Windows)

# which compilers to use for C and C++
SET(CMAKE_C_COMPILER ${PLATFORM_COMPILLER_NAME}-${BASE_COMPILLER_NAME}-gcc)
SET(CMAKE_CXX_COMPILER ${PLATFORM_COMPILLER_NAME}-${BASE_COMPILLER_NAME}-g++)
SET(CMAKE_RC_COMPILER ${PLATFORM_COMPILLER_NAME}-${BASE_COMPILLER_NAME}-windres)

# here is the target environment located
SET(CMAKE_FIND_ROOT_PATH /usr/${PLATFORM_COMPILLER_NAME}-${BASE_COMPILLER_NAME})

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

