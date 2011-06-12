#!/bin/sh
# A script to build your iOS app and send it to test flight
# Distributed on an as is and I accept no responsiblity for what it does licence
#

# I'm assuming that your project is in the src directory of your repository
PROJECT_DIRECTORY="${PWD}/src"
# The target we're building
TARGET_NAME="My Project"
# The name for the .app and .ipa files that get created
APP_NAME="myproject"
# I like to have build junk outside my source directory, this is where the output from build will go
PROJECT_BUILDDIR="/tmp/iOSBuild"

# create clean target folder
echo "Setting up current folder"
if [ -d "${PROJECT_BUILDDIR}" ]; then
	rm -rf "${PROJECT_BUILDDIR}"
fi
mkdir "${PROJECT_BUILDDIR}"

# compile project
echo "Building Project"
cd "${PROJECT_DIRECTORY}"
xcodebuild -target "${PROJECT_NAME}" -sdk "iphoneos5.0" -configuration "Ad Hoc" clean CONFIGURATION_BUILD_DIR="${PROJECT_BUILDDIR}"

xcodebuild -target "${PROJECT_NAME}" -sdk "iphoneos5.0" -configuration "Ad Hoc" build CONFIGURATION_BUILD_DIR="${PROJECT_BUILDDIR}"

#Check if build succeeded
if [ $? != 0 ]
then
  exit 1
fi

echo "Building IPA"
/usr/bin/xcrun -sdk "iphoneos5.0" PackageApplication -v "${PROJECT_BUILDDIR}/${APP_NAME}.app" -o "${PROJECT_BUILDDIR}/${APP_NAME}.ipa"

#Check if build succeeded
if [ $? != 0 ]
then
  exit 1
fi

# DISTRIBUTE TEH BUILD

#Get the time for midnight the day before so that we can get all the commit messages
HOURS=`date "+%H"`
MINS=`date "+%M"`
SECS=`date "+%S"`
PREVDAY=`date -v-1d -v-${HOURS}H  -v-${MINS}M -v-${SECS}S`

#Grab the commit messages from git
COMMITMESSAGE=`git log --after="${PREVDAY}" -s --format=%s`
echo "Commit message is: ${COMMITMESSAGE}"

#testflight settings
TF_API_TOKEN="YOUR API TOKEN HERE"
TF_TEAM_TOKEN="YOUR TEAM TOKEN HERE"
TF_DISTRIBUTION_LISTS="Nightly"

echo "Sending to test flight"
curl -F file=@"$PROJECT_BUILDDIR/${APP_NAME}.ipa" -F api_token="${TF_API_TOKEN}" -F team_token="${TF_TEAM_TOKEN}" -F notes="Nightly Build - ${COMMITMESSAGE}" -F notify=True -F distribution_lists="${TF_DISTRIBUTION_LISTS}" "http://testflightapp.com/api/builds.json"
