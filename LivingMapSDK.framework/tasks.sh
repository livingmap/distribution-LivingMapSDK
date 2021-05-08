#!/bin/bash

#--------------------------------------------------------------------------
# Living Map iOS SDK Build and Deployment Tasks
#
# (c) 2020 Living Map Ltd.
#
# This file contains shell functions directly associated with Makefile
# build targets and is expected to be invoked via a 'make' command, e.g.
#
#    $ SDK=aa make test
#
# Users are not expected to run commands here directly.  The Makefile
# contains more information on the targets available. Type 'make' for help.
#--------------------------------------------------------------------------

# Set the Root directory, i.e. the directory this file is in
# https://stackoverflow.com/a/246128/2431627
ROOT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Output and Logging locations
OUTPUT_DIR_NAME="Output"
LOG_DIR_NAME="BuildLogs"
OUTPUT_DIR_PATH="${ROOT_DIRECTORY}/${OUTPUT_DIR_NAME}"
OUTPUT_LOGS_DIR="${ROOT_DIRECTORY}/${OUTPUT_DIR_NAME}/${LOG_DIR_NAME}"
ARTEFACT_DIR="${OUTPUT_DIR_PATH}"

# xcpretty hides a lot of xcodebuild's output detail.  We indirect via a variable
# for the times we do want to dig into output.  Not (yet) a make target option.
#XCPRETTY="cat"
XCPRETTY="$( which xcpretty )"

WORKSPACE="NewSDKs.xcworkspace"

#==========================================================================
#
# MARK: Main Tasks
#
#==========================================================================

#--------------------------------------------------------------------------
# Remove all  traces of the various builds, including Xcode cleanup, removing 
# build binary artifacts, Derived Data etc.
#--------------------------------------------------------------------------
function clean {
    _PUSHD

    set_frameworks
    debug_env
    
    echo "Cleaning up"

    for framework in ${FRAMEWORKS[@]}; do
        echo "Cleaning $framework"
        # Run the Xcode target clean command
        xcodebuild \
            -workspace "${WORKSPACE}" \
            -scheme "${framework}" \
            clean | \
        "${XCPRETTY[@]}"
    done

    echo "Removing the build artefact directory"
    if [ "$SDK" = "all" ]; then
        rm -rf "${ARTEFACT_DIR}"
    fi

    # TODO: DerivedData (workspace-level, how to find it? Via plist?)

    echo "Done"

    _POPD
}

#--------------------------------------------------------------------------
# Build universal binary frameworks
#
# The built artifacts are suitable for upload to customer-facing repos and
# manual inclusion in apps.
#--------------------------------------------------------------------------
#function make_binary {
#    _PUSHD
#
#    # Create the log directory
#    mkdir -p "${OUTPUT_LOGS_DIR}"
#
#    # Configure what gets built based on environment variables
#    set_frameworks
#    set_platforms
#    set_build_configuration
#    debug_env
#
#    # Loop over the frameworks and platforms, and build (universal) binary frameworks if specified
#
#    echo "Building "$BUILD_CONFIGURATION" version for [ ${FRAMEWORKS[@]} ] as binary framework(s) for [ ${PLATFORMS[@]} ]"
#    echo
#
#    # set -x
#
#    for framework in ${FRAMEWORKS[@]}; do
#        for platform in ${PLATFORMS[@]}; do
#
#            echo "Building $framework for ${platform}"
#
#            # Create the log file
#            touch "${OUTPUT_LOGS_DIR}/${BUILD_CONFIGURATION}-${platform}-${framework}"
#
#            set -o pipefail && \
#            xcodebuild \
#                    ONLY_ACTIVE_ARCH=NO \
#                    BITCODE_GENERATION_MODE=bitcode \
#                    -workspace "SDKs.xcworkspace" \
#                    -scheme "${framework}" \
#                    -sdk ${platform} \
#                    -configuration "${BUILD_CONFIGURATION}" \
#                    CONFIGURATION_BUILD_DIR="${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-${platform}" \
#                    clean build | \
#            "${XCPRETTY[@]}"
#        done
#
#        set -x
#
#        # Merge frameworks into a universal one if 'all' has been specified as a platform
#        if [ "$PLATFORM" = "all" ]; then
#            echo "Building ${framework} Universal Framework"
#
#
#
#            if [ -d "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework" ] && \
#               [ -d "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphoneos/${framework}.framework" ]; then
#
#                mkdir -p "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal"
#
#                # We use the device framework as a base
#                cp -r \
#                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphoneos/${framework}.framework/" \
#                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework"
#
#                # The simulator builds are merged in using 'lipo'
#                lipo \
#                    -create "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework/${framework}" \
#                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework/${framework}" \
#                    -output "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework/${framework}"
#
#                echo "Universal framework built"
#            fi
#        fi
#    done
#
#    _POPD
#}

function make_binary {
    _PUSHD

    # Create the log directory
    mkdir -p "${OUTPUT_LOGS_DIR}"

    # Configure what gets built based on environment variables
    set_frameworks
    set_platforms
    set_build_configuration
    debug_env
    
    echo
    echo "Create binary frameworks"
    echo

    # Loop over the frameworks and platforms, and build (universal) binary frameworks if specified

    echo "Building "$BUILD_CONFIGURATION" version for [ ${FRAMEWORKS[@]} ] as binary framework(s) for [ ${PLATFORMS[@]} ]"
    echo

    for framework in ${FRAMEWORKS[@]}; do
        for platform in ${PLATFORMS[@]}; do

            LOGFILE="${OUTPUT_LOGS_DIR}/${BUILD_CONFIGURATION}-${platform}-${framework}"

            echo "Building $framework for ${platform}"
            echo "Logging to: ${LOGFILE}"

            # Create the log file
            touch "${OUTPUT_LOGS_DIR}/${BUILD_CONFIGURATION}-${platform}-${framework}"
            
            set -o pipefail && \
            xcodebuild \
                    -workspace "${WORKSPACE}" \
                    -scheme "${framework}" \
                    -sdk ${platform} \
                    -configuration "${BUILD_CONFIGURATION}" \
                    CONFIGURATION_BUILD_DIR="${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-${platform}" \
                    clean build | \
            tee "${LOGFILE}" | \
            "${XCPRETTY[@]}"
        done

        # Merge frameworks into a universal one if 'all' has been specified as a platform
        if [ "$PLATFORM" = "all" ]; then
            echo "Building ${framework} Universal Framework"

            if [ -d "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework" ] && \
               [ -d "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphoneos/${framework}.framework" ]; then

                echo "We have both simulator and device builds..."

                if [ "${platform}" = "iphonesimulator" ]; then
                    lipo "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework/${framework}" \
                        -remove arm64 \
                        -output "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework/${framework}"
                fi

                mkdir -p "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal"
                
                # We use the device framework as a template
                cp -r \
                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphoneos/${framework}.framework/" \
                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework"
                
                # The simulator builds are merged in using 'lipo'
                UNIVERSAL_FRAMEWORK="${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework/${framework}"
                lipo \
                    -create \
                        "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework/${framework}" \
                        "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework/${framework}" \
                    -output \
                        "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework/${framework}"

                # Copy swiftmodules
                # https://stackoverflow.com/a/58192079
                # https://stackoverflow.com/a/48779486/2431627
                cp -R \
                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-iphonesimulator/${framework}.framework/Modules/${framework}.swiftmodule/." \
                    "${ARTEFACT_DIR}/${BUILD_CONFIGURATION}-universal/${framework}.framework/Modules/${framework}.swiftmodule"
            fi
        fi
    done

    _POPD
}

#--------------------------------------------------------------------------
# Build fat frameworks for our dependencies
#--------------------------------------------------------------------------
function merge_dependencies {
    echo "Merge dependencies"
    
    _PUSHD

    SIM_DIR="${ROOT_DIRECTORY}/Output/Release-iphonesimulator"
    DEVICE_DIR="${ROOT_DIRECTORY}/Output/Release-iphoneos"
    UNIVERSAL_DIR="${ROOT_DIRECTORY}/Output/Release-universal"
    
    DEPENDENCIES=( Alamofire SwiftProtobuf )
    
    for DEPENDENCY in ${DEPENDENCIES[@]}; do
    
        FW_NAME="${DEPENDENCY}.framework"
        FW_SIM_DIR="${SIM_DIR}/${FW_NAME}"
        FW_DEVICE_DIR="${DEVICE_DIR}/${FW_NAME}"
        FW_UNIVERSAL_NAME="${UNIVERSAL_DIR}/${FW_NAME}"
    
        if [[ -d "${FW_DEVICE_DIR}" && \
              -d "${FW_SIM_DIR}" && \
              -d "${UNIVERSAL_DIR}" ]];
        then
        
            echo "Good to go with ${DEPENDENCY}"
        
            if [[ -d "${FW_UNIVERSAL_NAME}" ]]; then
                echo "Removing existing universal framework for ${DEPENDENCY}"
                rm -rf "${FW_UNIVERSAL_NAME}"
            fi
            
            echo "Merging architectures"
            
            # We use the device framework as a template
            cp -r \
                "${FW_DEVICE_DIR}/" \
                "${FW_UNIVERSAL_NAME}"
            
            # Fat frameworks
            lipo \
                -create \
                    "${FW_SIM_DIR}/${DEPENDENCY}" \
                    "${FW_UNIVERSAL_NAME}/${DEPENDENCY}" \
                -output \
                    "${FW_UNIVERSAL_NAME}/${DEPENDENCY}"
            
            echo "Copying swiftmodules"
            
            # Copy swiftmodules
            cp -R \
                "${FW_SIM_DIR}/Modules/${DEPENDENCY}.swiftmodule/." \
                "${FW_UNIVERSAL_NAME}/Modules/${DEPENDENCY}.swiftmodule"
        fi
    
    done
    
    echo "All done"
}


#--------------------------------------------------------------------------
# Run unit tests on specified Living Map SDKs
#--------------------------------------------------------------------------
function test {
    _PUSHD

    # Configure what gets tested based on environment variables
    set_frameworks
    DEVICE=${DEVICE:-SE} # DEVICE defaults to "SE"
    debug_env

    # Loop over the frameworks, platforms and build (universal) binary frameworks

    echo "Running unit tests for [ ${FRAMEWORKS[@]} ]"
    echo

    for framework in ${FRAMEWORKS[@]}; do
        echo "Testing $framework"

        # Extract the id of a simulator device matching a regex
        DEVICE_ID=$( \
            instruments -s devices | \
            grep -i simulator | \
            grep -i iPhone | \
            grep "${DEVICE}" | \
            head -1 | \
            sed -e s'/.*\[\(.*\)\].*/\1/' )

        # Run the unit tests
        xcodebuild \
                -workspace "${WORKSPACE}" \
                -scheme "${framework}" \
                -sdk iphonesimulator \
                -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
                test | \
                "${XCPRETTY[@]}"
    done

    _POPD
}

#--------------------------------------------------------------------------
# Build an ad-hoc .ipa for onward distribution.  Expects $DEMO_APP to be
# sensible: 'AirlineAcceleratorDemo' or 'LivingMapSDKDemo' for instance.
# This is provided by the Make target.
#
# xcodebuild archive and export info from here:
#
#     https://stackoverflow.com/a/19856005/2431627
#
#--------------------------------------------------------------------------
function build_demo_app {
    _PUSHD
    
    debug_env
    
    if [ -z "${DEMO_APP}" ]; then
        echo "Please provide a \$DEMO_APP to build"
        exit
    fi
    
    echo "Building the ${DEMO_APP} .ipa for distribution."
    echo
    
    ##
    ## Archive the app
    ##
    
    xcodebuild \
        -workspace "${WORKSPACE}" \
        -scheme "${DEMO_APP}" \
        -sdk iphoneos \
        -configuration "Release" \
        -archivePath "${ARTEFACT_DIR}/${DEMO_APP}.xcarchive" \
        CONFIGURATION_BUILD_DIR="${ARTEFACT_DIR}/Release-iphoneos" \
        clean archive | \
        "${XCPRETTY[@]}"

    ##
    ## Export the .ipa
    ##
    
    IPA_EXPORT_PATH="${ARTEFACT_DIR}/${DEMO_APP} $(date +"%Y-%m-%d %H-%M-%S")"
    IPA_FILE="${IPA_EXPORT_PATH}/${DEMO_APP}.ipa"
    
    xcodebuild \
        -exportArchive \
        -archivePath "${ARTEFACT_DIR}/${DEMO_APP}.xcarchive" \
        -exportOptionsPlist "${ROOT_DIRECTORY}/ExportOptions.plist" \
        -exportPath "${IPA_EXPORT_PATH}" | \
        "${XCPRETTY[@]}"
    
    echo
    echo "The built ${DEMO_APP} .ipa is here:"
    echo "    ${IPA_FILE}"
    
    _POPD
}

#--------------------------------------------------------------------------
# Deploy a demo app for testing via Firebase.
# Requires the Firebase CLI to be installed.  For details see:
#
#     https://firebase.google.com/docs/cli#install-cli-mac-linux
#
# The Firebase deployment requires a token.  For security reasons this is
# not stored in the repository.  See the Firebase CLI notes, above
# (specifically the CI section), for details on how to generate this token.
# (In short: $ firebase login:ci).  The token text should be placed in a
# 'FirebaseToken.txt' file in the Build System directory.
#
# You may be required to login manually once to accept Ts&Cs.
#
# CLI deployment notes are here:
#
#     https://firebase.google.com/docs/app-distribution/ios/distribute-cli
#
#--------------------------------------------------------------------------
function deploy_demo_app {

    _PUSHD

    debug_env

    if [ -z "${DEMO_APP}" ]; then
        echo "Please provide a \$DEMO_APP to build"
        exit
    fi

    echo "Building the ${DEMO_APP} .ipa for Firebase deployment."
    echo

    ##
    ## Check Firebase CLI is installed and the access token is available
    ##
    
    if [ ! -x "$(which firebase)" ]; then
        echo "The Firebase CLI tools are not installed.  Please see:"
        echo "https://firebase.google.com/docs/cli#install-cli-mac-linux";
        exit
    fi
    
    if [ ! -f "${ROOT_DIRECTORY}/FirebaseToken.txt" ]; then
        echo "Firebase deployment requires a token in ${ROOT_DIRECTORY}/FirebaseToken.txt"
        exit
    fi
    
    FIREBASE_TOKEN="$( head -1 "${ROOT_DIRECTORY}/FirebaseToken.txt" )"
    
    build_demo_app

    echo ${IPA_FILE}

    _POPD
}

#--------------------------------------------------------------------------
# A convenience wrapper to get our Cocopods house in order
#--------------------------------------------------------------------------
function update_pods {
    _PUSHD

    echo
    echo "Reinstall Pod dependencies"
    echo

    debug_env

    pod deintegrate
    pod update
    pod install

    _POPD
}

#--------------------------------------------------------------------------
# Show the bundle ("CFBundleShortVersionString") versions of all projects
#--------------------------------------------------------------------------
function show_versions {
    _PUSHD
    
    debug_env
    
    echo
    echo "Living Map iOS Project Versions:"
    echo
    
    LIVINGMAPSDKDEMO_VERSION=$( /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
        "${ROOT_DIRECTORY}/../../LivingMapSDKDemo/LivingMapSDKDemo/Misc/Info.plist" )
    AIRLINEACCELERATORDEMO_VERSION=$( /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
        "${ROOT_DIRECTORY}/../../AirlineAcceleratorDemo/AirlineAcceleratorDemo/Misc/Info.plist" )
    LIVINGMAPSDK_VERSION=$( /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
        "${ROOT_DIRECTORY}/../../LivingMapSDK/LivingMapSDK/Info.plist" )
    LIVINGMAPLIVESDK_VERSION=$( /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
        "${ROOT_DIRECTORY}/../../LivingMapLiveSDK/LivingMapLiveSDK/Info.plist" )
    AIRLINEACCELERATOR_VERSION=$( /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
        "${ROOT_DIRECTORY}/../../AirlineAccelerator/AirlineAccelerator/Info.plist" )

    echo "LivingMapSDKDemo       : ${LIVINGMAPSDKDEMO_VERSION}"
    echo "AirlineAcceleratorDemo : ${AIRLINEACCELERATORDEMO_VERSION}"
    echo "ivingMapSDK            : ${LIVINGMAPSDK_VERSION}"
    echo "LivingMapLiveSDK       : ${LIVINGMAPSDK_VERSION}"
    echo "AirlineAccelerator     : ${AIRLINEACCELERATOR_VERSION}"
    echo
    
    _POPD
}
#==========================================================================
#
# MARK: Helper functions
#
#==========================================================================

#--------------------------------------------------------------------------
# Convenience wrappers for pushd/popd
#--------------------------------------------------------------------------

function _PUSHD {
    pushd "${ROOT_DIRECTORY}/.." > /dev/null
}

function _POPD {
    popd > /dev/null
}

#--------------------------------------------------------------------------
# Diagnostics
#--------------------------------------------------------------------------

function debug_env {
    echo Living Map Build Scripts Configuration:
    echo
    echo "    SDK=${SDK}"
    echo "    PLATFORM=${PLATFORM}"
    echo "    CONFIG=${CONFIG}"
    echo "    ROOT_DIRECTORY=${ROOT_DIRECTORY}"
    echo "    DEVICE=${DEVICE}"
    echo "    XCPRETTY=${XCPRETTY}"
    echo "    ARTEFACT_DIR=${ARTEFACT_DIR}"
    echo "    DEMO_APP=${DEMO_APP}"
    echo
}

#--------------------------------------------------------------------------
# Helper functions to translate passed-in environment variables into the
# correct values
#--------------------------------------------------------------------------

function set_frameworks {
    FRAMEWORKS=( LivingMapSDK LivingMapLiveSDK AirlineAccelerator )
    case $SDK in
    "sdk")
        FRAMEWORKS=( LivingMapSDK ) ;;
    "live")
        FRAMEWORKS=( LivingMapLiveSDK ) ;;
    "aa")
        FRAMEWORKS=( AirlineAccelerator ) ;;
    "sdkdemo")
        FRAMEWORKS=( LivingMapSDKDemo ) ;;
    "aademo")
        FRAMEWORKS=( AirlineAcceleratorDemo ) ;;
    esac
}

function set_platforms {
        PLATFORMS=( iphoneos iphonesimulator )
    case $PLATFORM in
    "phone")
        PLATFORMS=( iphoneos ) ;;
    "simulator")
        PLATFORMS=( iphonesimulator ) ;;
    esac
}

function set_build_configuration {
    # Not the most effeicient, but uniform
    BUILD_CONFIGURATION=Debug
    case $CONFIG in
    "release")
        BUILD_CONFIGURATION=Release ;;
    "debug")
        BUILD_CONFIGURATION=Debug ;;
    esac
}
