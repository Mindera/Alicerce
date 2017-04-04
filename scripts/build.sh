#!/bin/bash

BUILD_DIRECTORY="build"

if [[ -z $TRAVIS_XCODE_PROJECT ]]; then
    echo "Error: \$TRAVIS_XCODE_PROJECT is not set."
    exit 1
fi

if [[ -z $TRAVIS_XCODE_SCHEME ]]; then
    echo "Error: \$TRAVIS_XCODE_SCHEME is not set!"
    exit 1
fi

if [[ -z $XCODE_ACTION ]]; then
    echo "Error: \$XCODE_ACTION is not set!"
    exit 1
fi

if [[ -z $XCODE_SDK ]]; then
    echo "Error: \$XCODE_SDK is not set!"
    exit 1
fi

set -o pipefail

xcodebuild $XCODE_ACTION -project "$TRAVIS_XCODE_PROJECT" -scheme "$TRAVIS_XCODE_SCHEME" -sdk "$XCODE_SDK" -destination "$XCODE_DESTINATION" -derivedDataPath "${BUILD_DIRECTORY}"
