#
# Copyright (C) 2018-2020 QuasarApp.
# Distributed under the MIT software license, see the accompanying
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.
#


# This module implementation next cmake cunctions :
#
#
# ***Testing***
# addTestsArg( name testExec arg ) // name target for test utiliry of your application
# - name - prefix for taget (any word)
# - testExec - name of tests utility (without extensions)
# - arg - arguments fot testExec
#
# addTests (name testExec )// name target for test utiliry of your application (without arguments)
# - name - prefix for taget (any word)
# - testExec - name of tests utility (without extensions)
#
# initTests - init main test target for tessting all added tests, this method need to call befor all invoced addTests methods.
#
#
# *** Deployment ***
# addDeploy(name targets targetDir) // add deploy target for deployed your application via cqtdeployer tool
# - name - this is prefix of added subtarget (any word)
# - targets - this is list of cqtdeployer targets see cqtdeployer help https://github.com/QuasarApp/CQtDeployer/wiki/Options (-bin)
# - targetDir - this is target directory see option targetDir of cqtdeployer help https://github.com/QuasarApp/CQtDeployer/wiki/Options (-targetDir)
#
# addDeployFromFile(name) // some as initDeploy but use CQtDeployer.json for configuration.
# - name - this is prefix of added subtarget (any word)
#
# addDeployFromCustomFile(name file) // some as initDeploy but use custo path for deployment file for configuration.
# - name - this is prefix of added subtarget (any word)
# - file - this is path to config file of cqtdeployer
#
# addDeploySnap(name targetDir) // add to deploy step substeps for create a snap package
# - name - this is prefix of added subtarget (any word)
# - targetDir - distanation direcroty for snap files
#
# addDeployQIF(name sourceDir targetDir config) // add to deploy step substeps for create Qt Install FrameWork Installer
# - name - this is prefix of added subtarget (any word)
# - location for created installer
# - sourceDir - path to folder with qif template
# - config - path to config file of qif template
#
# addDeployAPK(name input aliase keystore keystorePass targetDir) // add subtargets of deploy setep for create signed android apk file
# - name - this is prefix of added subtarget (any word)
# - input - path to input android json file : *-deployment-settings.json
# - aliase - aliase for key store
# - keystore - path of key store
# - keystorePass - pass of keystore file
# - targetDir - target dir for output apk file
#
# initDeploy() // create a main deploy target fpr all addDeploy subtargets. this method need to call befor invoced of all addDeploy methods
#
#
# *** Release ***
# initRelease() // create the general release target for all subtargets addRelease. This method need to call befor invoce all addRelease methods.
#
# addReleaseSnap(name) // create subtargets for publish snap deployed snap package
# - name - this is prefix of added subtarget (any word)
#
# addReleaseQif(name sourceDir targetDir) // create subtargets for publish the qif package on qif repository
# - name - this is prefix of added subtarget (any word)
# - sourceDir - path to folder with qif template
# - targetDir - path to target derictory
#
#
# *** Dcumentation ***
# initDoc() // create the general doc target for all subtargets addDoc. This method need to call befor invoce all addDoc methods.
#
# addDoc(name doxygenFile) // create subtargets for generate documentation of cpp code
# - name - this is prefix of added subtarget (any word)
# - doxygenFile - this is path to doxygen configuration file
#


if(DEFINED QUASARAPP_DEFAULT_TARGETS)
  return()
else()
  set(QUASARAPP_DEFAULT_TARGETS 1)
endif()

set(DOC_TARGETS_LIST "")
set(TEST_TARGETS_LIST "")
set(DEPLOY_TARGETS_LIST "")
set(RELEASE_TARGETS_LIST "")
set(DIR_FOR_TESTING ${PROJECT_SOURCE_DIR}/Testing)

function(emptyTarget targetName)

    if(TARGET ${targetName})
        message("the ${targetName} target already created!")
        return()

    endif(TARGET ${targetName})

    ADD_CUSTOM_TARGET(
        ${targetName}
    )

endfunction()

function(initTests)

    if(TARGET test)
        message("the test target already created!")
        return()

    endif(TARGET test)

    message("test sub targets: ${TEST_TARGETS_LIST}")

    ADD_CUSTOM_TARGET(
        test
        COMMENT "=================== Run Test ==================="
        DEPENDS
    )

    message("prepare tests for ${TEST_TARGETS_LIST}")

endfunction()

function(addTestsArg name testExec arg)

    if(TARGET test${name})
        message("the test${name} target already created!")
        return()
    endif(TARGET test${name})

    set(EXEC_TEST ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${testExec})
    set(RUN_CMD ${DIR_FOR_TESTING}/${name}/${testExec}.sh)

    if (WIN32)
        set(EXEC_TEST ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${testExec}.exe)
        set(RUN_CMD ${DIR_FOR_TESTING}/${name}/${testExec}.exe)

    endif (WIN32)

    find_program(Q_MAKE_EXE qmake)

    find_program(CQT_EXE cqtdeployer)

    IF(NOT EXISTS ${CQT_EXE})
        message("the cqtdeployer not exits please install the cqtdeployer and run cmake again!")
        return()
    endif(NOT EXISTS ${CQT_EXE})


    ADD_CUSTOM_TARGET(
        deployTest${name}
        COMMAND cqtdeployer clear -bin ${EXEC_TEST} -qmake ${Q_MAKE_EXE} -targetDir ${DIR_FOR_TESTING}/${name} -libDir ${PROJECT_SOURCE_DIR} -recursiveDepth 5
        COMMENT "Deploy Test: cqtdeployer clear -bin ${EXEC_TEST} -targetDir ${DIR_FOR_TESTING}/${name} -libDir ${PROJECT_SOURCE_DIR} -recursiveDepth 5"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        )

    ADD_CUSTOM_TARGET(
        test${name}
        COMMAND ${RUN_CMD} ${arg}
        COMMENT "=================== Run Test ==================="
        WORKING_DIRECTORY ${DIR_FOR_TESTING}/${name}
        DEPENDS deployTest${name}
    )

    add_dependencies(test test${name})

endfunction()

function(addTests name testExec)

    if(TARGET test${name})
        message("the test${name} target already created!")
        return()

    endif(TARGET test${name})

    set(EXEC_TEST ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${testExec})
    set(RUN_CMD ${DIR_FOR_TESTING}/${name}/${testExec}.sh)

    if (WIN32)
        set(EXEC_TEST ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${testExec}.exe)
        set(RUN_CMD ${DIR_FOR_TESTING}/${name}/${testExec}.exe)

    endif (WIN32)

    find_program(Q_MAKE_EXE qmake)

    find_program(CQT_EXE cqtdeployer)

    IF(NOT EXISTS ${CQT_EXE})
        message("the cqtdeployer not exits please install the cqtdeployer and run cmake again!")
        return()
    endif(NOT EXISTS ${CQT_EXE})

    ADD_CUSTOM_TARGET(
        deployTest${name}
        COMMAND cqtdeployer clear -bin ${EXEC_TEST} -qmake ${Q_MAKE_EXE} -targetDir ${DIR_FOR_TESTING}/${name} -libDir ${PROJECT_SOURCE_DIR} -recursiveDepth 5
        COMMENT "Deploy Test: cqtdeployer clear -bin ${EXEC_TEST} -targetDir ${DIR_FOR_TESTING}/${name} -libDir ${PROJECT_SOURCE_DIR} -recursiveDepth 5"
    )


    ADD_CUSTOM_TARGET(
        test${name}
        COMMAND ${RUN_CMD}
        COMMENT "=================== Run Test ==================="
        WORKING_DIRECTORY ${DIR_FOR_TESTING}/${name}
        DEPENDS deployTest${name}
    )

    add_dependencies(test test${name})


    message("prepare tests for ${RUN_CMD}")

endfunction()

function(initDeploy)

    if(TARGET deploy)
        message("the deploy target already created!")
        return()

    endif(TARGET deploy)

    message("deploy subtargets: ${DEPLOY_TARGETS_LIST}")

    ADD_CUSTOM_TARGET(
        deploy
        COMMENT "=================== Run deploy ==================="
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}

    )

endfunction()

function(addDeploy name targets targetDir)

    if(TARGET deploy${name})
        message("the deploy${name} target already created!")
        return()

    endif(TARGET deploy${name})

    find_program(Q_MAKE_EXE qmake)

    find_program(CQT_EXE cqtdeployer)

    IF(NOT EXISTS ${CQT_EXE})
        message("the cqtdeployer not exits please install the cqtdeployer and run cmake again!")
        return()
    endif(NOT EXISTS ${CQT_EXE})

    ADD_CUSTOM_TARGET(
        deploy${name}
        COMMAND cqtdeployer clear -bin ${targets} -qmake ${Q_MAKE_EXE} -targetDir ${targetDir} -libDir ${PROJECT_SOURCE_DIR} -recursiveDepth 5
        COMMENT "Deploy: cqtdeployer clear -bin ${targets} -qmake ${Q_MAKE_EXE} -targetDir ${targetDir} -libDir ${PROJECT_SOURCE_DIR} -recursiveDepth 5"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )

    add_dependencies(deploy deploy${name})

endfunction()

function(addDeployFromFile name)

    if(TARGET deploy${name})
        message("the deploy${name} target already created!")
        return()

    endif(TARGET deploy${name})

    find_program(Q_MAKE_EXE qmake)
    find_program(CQT_EXE cqtdeployer)

    IF(NOT EXISTS ${CQT_EXE})
        message("the cqtdeployer not exits please install the cqtdeployer and run cmake again!")
        return()
    endif(NOT EXISTS ${CQT_EXE})

    ADD_CUSTOM_TARGET(
        deploy${name}
        COMMAND cqtdeployer -qmake ${Q_MAKE_EXE}
        COMMENT "Deploy: cqtdeployer -qmake ${Q_MAKE_EXE}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )
    add_dependencies(deploy deploy${name})


endfunction()

function(addDeployFromCustomFile name file)

    if(TARGET deploy${name})
        message("the deploy${name} target already created!")
        return()

    endif(TARGET deploy${name})

    find_program(Q_MAKE_EXE qmake)
    find_program(CQT_EXE cqtdeployer)

    IF(NOT EXISTS ${CQT_EXE})
        message("the cqtdeployer not exits please install the cqtdeployer and run cmake again!")
        return()
    endif(NOT EXISTS ${CQT_EXE})

    ADD_CUSTOM_TARGET(
        deploy${name}
        COMMAND cqtdeployer -qmake ${Q_MAKE_EXE} -confFile ${file}
        COMMENT "Deploy: cqtdeployer -qmake ${Q_MAKE_EXE} -confFile ${file}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )

    add_dependencies(deploy deploy${name})

endfunction()

function(addDeploySnap name targetDir)

    if(TARGET snap${name})
        message("the snap${name} target already created!")
        return()

    endif(TARGET snap${name})

    find_program(SNAPCRAFT_EXE "snapcraft")

    if(NOT EXISTS ${SNAPCRAFT_EXE})
        message("please install the snapcraft befor deploy this project! Use: sudo snap install snapcraft --classic")
        return()
    endif(NOT EXISTS ${SNAPCRAFT_EXE})

    ADD_CUSTOM_TARGET(
        snapClear${name}
        COMMAND snapcraft clean
        COMMENT "clear snap: snapcraft clear"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}

    )

    ADD_CUSTOM_TARGET(
        snapcraft${name}
        COMMAND snapcraft
        COMMENT "create snap: snapcraft"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        DEPENDS deploy${name} snapClear${name}
    )

    ADD_CUSTOM_TARGET(
        snapcraftCopy${name}
        COMMAND ${CMAKE_COMMAND} -E copy *.snap ${targetDir}
        COMMENT "copy snap: ${CMAKE_COMMAND} -E copy *.snap ${targetDir}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        DEPENDS snapcraft${name}

    )

    ADD_CUSTOM_TARGET(
        snap${name}
        COMMENT "deploy snap${name}"
        DEPENDS snapcraftCopy${name}

    )

    add_dependencies(deploy snap${name})


endfunction()

function(addDeployQIF name sourceDir targetDir config)

    if(TARGET qifDeploy${name})
        message("the qifDeploy${name} target already created!")
        return()

    endif(TARGET qifDeploy${name})

    find_program(BINARYCREATOR_EXE binarycreator)

    IF(NOT EXISTS ${BINARYCREATOR_EXE})
        message("the Binarycreator not exits please install or adde path to QtInstaller Framework to PATH and run cmake again!")
        return()
    endif(NOT EXISTS ${BINARYCREATOR_EXE})

    set(OUT_EXE ${targetDir}/${PROJECT_NAME}OfllineInstaller.run)
    if (WIN32)
        set(OUT_EXE ${targetDir}/${PROJECT_NAME}OfllineInstaller.exe)
    endif (WIN32)

    ADD_CUSTOM_TARGET(
        qifDeploy${name}
        COMMAND ${BINARYCREATOR_EXE} --offline-only -c ${config} -p ${sourceDir}/packages ${OUT_EXE}
        COMMENT "deploy qif: ${BINARYCREATOR_EXE} --offline-only -c ${config} -p ${sourceDir}/packages ${OUT_EXE}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        DEPENDS deploy${name}

    )

    add_dependencies(deploy qifDeploy${name})

endfunction()

function(addDeployAPK name input aliase keystore keystorePass targetDir)

    if(TARGET deployAPK${name})
        message("the deployAPK${name} target already created!")
        return()

    endif(TARGET deployAPK${name})

    IF(NOT DEFINED $ENV{ANDROID_HOME})
        message("the ANDROID_HOME is not defined. define ANDROID_HOME variable and run cmake again!")
        return()
    endif(NOT DEFINED $ENV{ANDROID_HOME})


    set(OUTPUT_ANDROID "--output ${PROJECT_SOURCE_DIR}/AndroidBuild")
    set(INPUT_ANDROID "--input ${input}")
    set(JDK "--jdk /usr")
    set(SIGN "--sign '${keystore}' --storepass '${keystorePass}' --keypass '${keystorePass}' --release")

    find_program(A_DEPLOYER androiddeployqt)

    ADD_CUSTOM_TARGET(
        createAPK${name}
        COMMAND ${A_DEPLOYER} ${INPUT_ANDROID} ${OUTPUT_ANDROID} ${JDK} --gradle ${SIGN}
        COMMENT "Run deploy android apk : ${A_DEPLOYER} ${INPUT_ANDROID} ${OUTPUT_ANDROID} ${JDK} --gradle ${SIGN}"
    )

    ADD_CUSTOM_TARGET(
        deployAPK${name}
        COMMAND ${CMAKE_COMMAND} -E copy *.apk ${targetDir}
        COMMENT "copt apk: ${CMAKE_COMMAND} -E copy *.apk ${targetDir}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/AndroidBuild/build/outputs/apk/
        DEPENDS createAPK${name}

    )

    add_dependencies(deploy deployAPK${name})

endfunction()

function(initRelease)

    if(TARGET release)
        message("the release target already created!")
        return()

    endif(TARGET release)
    message("release subtargets: ${RELEASE_TARGETS_LIST}")

    ADD_CUSTOM_TARGET(
        release
        COMMENT "=================== Relese project ==================="
    )

endfunction()

function(addReleaseSnap name)

    if(TARGET snapRelease${name})
        message("the snapRelease${name} target already created!")
        return()

    endif(TARGET snapRelease${name})

    ADD_CUSTOM_TARGET(
        snapRelease${name}
        COMMAND snapcraft push
        COMMENT "snapRelease${name} release"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}

    )

    add_dependencies(release snapRelease${name})

endfunction()

function(addReleaseQif name sourceDir targetDir)
    if(TARGET qifRelease${name})
        message("the qifRelease${name} target already created!")
        return()

    endif(TARGET qifRelease${name})

    find_program(BINARYCREATOR_EXE binarycreator)

    IF(NOT EXISTS ${BINARYCREATOR_EXE})
        message("the Binarycreator not exits please install or adde path to QtInstaller Framework to PATH and run cmake again!")
        return()
    endif(NOT EXISTS ${BINARYCREATOR_EXE})

    set(OUT_EXE ${targetDir}/${PROJECT_NAME}OfllineInstaller.run)
    if (WIN32)
        set(OUT_EXE ${targetDir}/${PROJECT_NAME}OfllineInstaller.exe)
    endif (WIN32)

    ADD_CUSTOM_TARGET(
        qifDeployOnline${name}
        COMMAND ${BINARYCREATOR_EXE} --online-only -c ${config} -p ${sourceDir}/packages ${OUT_EXE}
        COMMENT "deploy qif online: ${BINARYCREATOR_EXE} --online-only -c ${config} -p ${sourceDir}/packages ${OUT_EXE}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}

    )

    ADD_CUSTOM_TARGET(
        qifRelease${name}
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${sourceDir}
        ${CMAKE_BINARY_DIR}/Repo
        COMMENT "qifRelease${name} release ${CMAKE_COMMAND} -E copy_directory ${sourceDir} ${CMAKE_BINARY_DIR}/Repo"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        DEPENDS qifDeployOnline${name}
       )

   set(RELEASE_TARGETS_LIST ${RELEASE_TARGETS_LIST} qifRelease${name} PARENT_SCOPE)
   add_dependencies(release qifRelease${name})


endfunction()

function(addDoc name doxygenFile)

    if(TARGET doxygen${name})
        message("the doxygen${name} target already created!")
        return()

    endif(TARGET doxygen${name})

    find_program(DOXYGEN_EXECUTABLE doxygen)

    IF(NOT EXISTS ${DOXYGEN_EXECUTABLE})
        message("the doxygen not exits please install or add a path to doxygen to a PATH envirement variable and run cmake again!")
        return()
    endif(NOT EXISTS ${DOXYGEN_EXECUTABLE})

    ADD_CUSTOM_TARGET(
        doxygen${name}
        COMMAND ${DOXYGEN_EXECUTABLE} ${doxygenFile}
        COMMENT "${DOXYGEN_EXECUTABLE} ${doxygenFile}"
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}

    )

    add_dependencies(doc doxygen${name})

endfunction()

function(initDoc)
    if(TARGET doc)
        message("the doc target already created!")
        return()

    endif(TARGET doc)

    message("doc subtargets: ${DOC_TARGETS_LIST}")

    ADD_CUSTOM_TARGET(
        doc
        COMMENT "=================== Run generate docs ==================="
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )

endfunction()

function(initAll)
    initTests()
    initDoc()
    initDeploy()
    initRelease()

endfunction()

