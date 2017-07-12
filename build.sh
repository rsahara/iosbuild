#!/bin/bash

# ===
# Copyright 2017 Runo Sahara
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ===

set -e

# === QUICK SETTINGS

#BUILD_USEQUICKSETTINGS="YES" # Uncomment this line if you want to use the quick settings below.

[ -z "$BUILD_USEQUICKSETTINGS" ] || {

# - Required settings.

# Source to build, specified by a git url and branch name (recommended),
BUILD_GIT_URL="https://github.com/rsahara/project.git"
BUILD_GIT_BRANCH="master"

# or directly by a script to deploy the source in $BUILD_SRC_DIR of the current directory.
#BUILD_DEPLOYSCRIPT='git clone -b "$BUILD_GIT_BRANCH" "$BUILD_GIT_URL" "$BUILD_SRC_DIR"'

# Xcode configuration (Debug, Release, etc...).
BUILD_XCODE_CONFIGURATION="Debug"

# Path to a plist file containing the export options, relative to the root of the repository.
BUILD_EXPORTOPTIONS_PATH="build/exportOptions.plist"

# The project files can be specified by the project name (recommended),
BUILD_PROJECTNAME="testproject"

# or with the actual file paths and scheme.
#BUILD_WORKSPACE_PATH="$BUILD_PROJECTNAME.xcworkspace"
#BUILD_ARCHIVE_PATH="$BUILD_PROJECTNAME.xcarchive"
#BUILD_IPA_PATH="$BUILD_PROJECTNAME.ipa"
#BUILD_XCODE_SCHEME="$BUILD_PROJECTNAME"

# - The output file. (Optional)

# #VERSION# will be replaced with the app version, #DATETIME# with the current datetime.
#BUILD_OUTPUT_FORMAT="${BUILD_PROJECTNAME}_#VERSION#_#DATETIME#.ipa"

# Path to the Info.plist file of the project. Required if #VERSION# is used in BUILD_OUTPUT_FORMAT.
#BUILD_INFOPLIST_PATH=""

# - Other settings. (Optional)

# Pre-build script to be executed right before the build command, in the source directory.
#BUILD_PREBUILDSCRIPT="pod update; security unlock-keychain -p password"

# Post-build script to be executed after the build is done, in the source directory. (${BUILD_SUCCEEDED} is set to "YES" if the build succeeded.)
#BUILD_POSTBUILDSCRIPT=""

# Verify that the correct version of Xcode is being used.
#BUILD_XCODE_VERSION="8.0"

# Additional parameter to be added to the build command line of xcodebuild.
#BUILD_XCODE_PARAM="DEBUG_TEST=1"

# Show the result in JSON dictionary like format.
#BUILD_JSONRESULT="YES"

# Print the settings and don't build.
#BUILD_PRINTSETTINGSONLY="YES"

# Specify the build directory, rather than letting the script use a random temporary directory.
#BUILD_DIR_ABSOLUTEPATH="/tmp/build"

# Specify the timeout in seconds. (Default: 1000 seconds)
#BUILD_TIMEOUT="1000"

}

# === LOAD SETTINGS

BUILD_JSONRESULTEMPTY="YES"
BUILD_SUCCEEDED="NO"
function build_print() {
	if [ "$BUILD_JSONRESULT" = "YES" ]; then
		if [ "$BUILD_JSONRESULTEMPTY" = "YES" ]; then
			printf "\"$1\":\"$2\""
			BUILD_JSONRESULTEMPTY="NO"
		else
			printf ",\n\"$1\":\"$2\""
		fi
	else
		echo "$1: $2"
	fi
}

function build_setting_require() {
	[ ! -z "${!1}" ] || { echo "$1 not set" >&2 && exit 1; }
}
function build_setting_default() {
	local default=$2
	[ ! -z "${!1}" ] || eval "$1"=\"\$default\"
}
function build_setting_print() {
	build_print "$1" "${!1}"
}

build_setting_default BUILD_JSONRESULT "NO"

if [ -z "$BUILD_GIT_URL" ]; then
	build_setting_require BUILD_DEPLOYSCRIPT
else
	build_setting_default BUILD_GIT_BRANCH "master"
	build_setting_default BUILD_DEPLOYSCRIPT 'git clone -b "$BUILD_GIT_BRANCH" "$BUILD_GIT_URL" "$BUILD_SRC_DIR"'
fi

build_setting_require BUILD_XCODE_CONFIGURATION
build_setting_require BUILD_EXPORTOPTIONS_PATH

build_setting_default BUILD_PREBUILDSCRIPT ""
build_setting_default BUILD_SRC_DIR "build"
[ ! -z "$BUILD_DIR_ABSOLUTEPATH" ] || BUILD_DIR_ABSOLUTEPATH=`mktemp -d`
BUILD_WORKINGDIR_ABSOLUTEPATH="$(pwd)"
build_setting_default BUILD_DATETIME $(date +"%Y%m%d_%H%M")
build_setting_default BUILD_INFOPLIST_PATH ""
build_setting_default BUILD_XCODE_PARAM ""
build_setting_default BUILD_BUILD_PROJECTNAME "projectname"
build_setting_default BUILD_XCODE_SCHEME "$BUILD_PROJECTNAME"
build_setting_default BUILD_WORKSPACE_PATH "$BUILD_PROJECTNAME.xcworkspace"
build_setting_default BUILD_ARCHIVE_PATH "$BUILD_PROJECTNAME.xcarchive"
build_setting_default BUILD_IPA_PATH "$BUILD_PROJECTNAME.ipa"
build_setting_default BUILD_OUTPUT_FORMAT "${BUILD_PROJECTNAME}_#VERSION#_#DATETIME#.ipa"
build_setting_default BUILD_TIMEOUT "1000"
build_setting_default BUILD_PRINTSETTINGSONLY "NO"

build_setting_print BUILD_DIR_ABSOLUTEPATH
build_setting_print BUILD_JSONRESULT
build_setting_print BUILD_WORKINGDIR_ABSOLUTEPATH
build_setting_print BUILD_DATETIME
[ -z "$BUILD_GIT_URL" ] || build_setting_print BUILD_GIT_URL
[ -z "$BUILD_GIT_BRANCH" ] || build_setting_print BUILD_GIT_BRANCH
build_setting_print BUILD_SRC_DIR
build_setting_print BUILD_XCODE_CONFIGURATION
build_setting_print BUILD_XCODE_PARAM
build_setting_print BUILD_INFOPLIST_PATH
build_setting_print BUILD_XCODE_SCHEME
build_setting_print BUILD_WORKSPACE_PATH
build_setting_print BUILD_ARCHIVE_PATH
build_setting_print BUILD_IPA_PATH
build_setting_print BUILD_EXPORTOPTIONS_PATH
build_setting_print BUILD_TIMEOUT

# === BUILD

BUILD_REMAININGTIME="$BUILD_TIMEOUT"

# Prepare build directory.
{
	[ "$BUILD_PRINTSETTINGSONLY" == "YES" ] || {
		rm -fr "$BUILD_DIR_ABSOLUTEPATH"
		rm -f "$BUILD_LOG_ABSOLUTEPATH"
	}

	dirname "$BUILD_LOG" | xargs mkdir -p
	mkdir -p "$BUILD_DIR_ABSOLUTEPATH"
	BUILD_LOG_ABSOLUTEPATH=`mktemp ${BUILD_DIR_ABSOLUTEPATH}/build.${BUILD_DATETIME}.XXXXXX`

} &> /dev/null

build_setting_print BUILD_LOG_ABSOLUTEPATH

# Build on another process.
BUILD_BEGINTIME=$(date +%s)
{
	[ -z "$BUILD_XCODE_VERSION" ] || {
		[ "Xcode $BUILD_XCODE_VERSION" = "`xcodebuild -version | head -n 1`" ] || { echo "Xcode version mismatch" >&2 && exit 1; }
	}

	[ "$BUILD_PRINTSETTINGSONLY" != "YES" ] || exit 0

	cd "$BUILD_DIR_ABSOLUTEPATH"
	eval "$BUILD_DEPLOYSCRIPT"

	cd "$BUILD_DIR_ABSOLUTEPATH/$BUILD_SRC_DIR"
	[ -z "$BUILD_PREBUILDSCRIPT" ] || eval "$BUILD_PREBUILDSCRIPT"

	cd "$BUILD_DIR_ABSOLUTEPATH/$BUILD_SRC_DIR"
	eval xcodebuild -workspace "$BUILD_WORKSPACE_PATH" \
-scheme "$BUILD_XCODE_SCHEME" \
-configuration "$BUILD_XCODE_CONFIGURATION" \
archive \
-archivePath "$BUILD_ARCHIVE_PATH" \
"$BUILD_XCODE_PARAM"

	eval xcodebuild -exportArchive \
-archivePath "$BUILD_ARCHIVE_PATH" \
-exportPath "$BUILD_DIR_ABSOLUTEPATH" \
-exportOptionsPlist "$BUILD_EXPORTOPTIONS_PATH" \
"$BUILD_XCODE_PARAM"

} >> "$BUILD_LOG_ABSOLUTEPATH" 2>&1 &

BUILD_WAITINGPROCESSID=$!
while [ $BUILD_REMAININGTIME -gt 0 ]; do
	sleep 1
	kill -0 $BUILD_WAITINGPROCESSID &> /dev/null || break
	BUILD_REMAININGTIME=$(($BUILD_REMAININGTIME - 1))
done

# Get build results.
if [ -f "$BUILD_DIR_ABSOLUTEPATH/$BUILD_IPA_PATH" ]; then

	{
		BUILD_VERSION="unknown"
		if [ ! -z "$BUILD_INFOPLIST_PATH" ]; then
			BUILD_INFOPLIST_ABSOLUTEPATH="$BUILD_DIR_ABSOLUTEPATH/$BUILD_SRC_DIR/$BUILD_INFOPLIST_PATH"
			BUILD_VERSION=$(defaults read "${BUILD_INFOPLIST_ABSOLUTEPATH%.plist}" CFBundleShortVersionString)
		fi

		BUILD_OUTPUT="$BUILD_OUTPUT_FORMAT"
		BUILD_OUTPUT="${BUILD_OUTPUT//#VERSION#/$BUILD_VERSION}"
		BUILD_OUTPUT="${BUILD_OUTPUT//#DATETIME#/$BUILD_DATETIME}"
		cp "$BUILD_DIR_ABSOLUTEPATH/$BUILD_IPA_PATH" "$BUILD_WORKINGDIR_ABSOLUTEPATH/$BUILD_OUTPUT"

		BUILD_SUCCEEDED="YES"
	} &> /dev/null

	build_setting_print BUILD_VERSION
	build_setting_print BUILD_OUTPUT

fi

# Post-build script on another process.
if [ $BUILD_REMAININGTIME -gt 0 ] && [ ! -z "$BUILD_POSTBUILDSCRIPT" ]; then

	{
		cd "$BUILD_DIR_ABSOLUTEPATH/$BUILD_SRC_DIR"
		eval "$BUILD_POSTBUILDSCRIPT"
	} >> "$BUILD_LOG_ABSOLUTEPATH" 2>&1 &

	BUILD_WAITINGPROCESSID=$!
	while [ $BUILD_REMAININGTIME -gt 0 ]; do
		sleep 1
		kill -0 $BUILD_WAITINGPROCESSID &> /dev/null || break
		BUILD_REMAININGTIME=$(($BUILD_REMAININGTIME - 1))
	done

fi

# Check timeout.
if [ ! $BUILD_REMAININGTIME -gt 0 ]; then
	kill -s SIGKILL $BUILD_WAITINGPROCESSID &> /dev/null
	echo "Timed out" >> "$BUILD_LOG_ABSOLUTEPATH"
fi

# === RESULT
build_setting_print BUILD_SUCCEEDED

BUILD_ENDTIME=$(date +%s)
BUILD_TIME=$(($BUILD_ENDTIME - $BUILD_BEGINTIME))
build_print "BUILD_TIME" "$BUILD_TIME"

[ "$BUILD_JSONRESULT" != "YES" ] || echo
