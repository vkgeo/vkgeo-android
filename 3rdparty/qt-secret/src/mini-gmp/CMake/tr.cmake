#
# Copyright (C) 2018-2020 QuasarApp.
# Distributed under the MIT software license, see the accompanying
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.
#

if(DEFINED PROJECT_TR_SUPPORT)
  return()
else()
  set(PROJECT_TR_SUPPORT 1)
endif()

function(prepareQM sourceDir ts_files)

    find_program(LUPDATE_EXECUTABLE lupdate)
    find_program(LRELEASE_EXECUTABLE lrelease)

    foreach(_ts_file ${ts_files})

        execute_process(
            COMMAND ${LUPDATE_EXECUTABLE} -recursive ${sourceDir} -ts ${_ts_file})
        execute_process(
            COMMAND ${LRELEASE_EXECUTABLE} ${_ts_file})

    endforeach()


endfunction()
