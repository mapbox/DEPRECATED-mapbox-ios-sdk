#!/bin/sh

PATH='/bin:/usr/bin:/usr/libexec'
VERSION=`git tag | sort -r | sed -n '1p'`
SDK=`xcodebuild -showsdks | grep iphoneos | awk '{ print $2 }'`
TARGET='MapView'
LIB_NAME='Mapbox'
OUTPUT='dist'

#
# clean old version
#
echo 'Removing old build...'
rm -rf MapView/build
rm -rf build
rm -rf $OUTPUT
mkdir -p $OUTPUT

#
# build static lib variants
#
xcodebuild -project MapView/MapView.xcodeproj -target $TARGET -configuration Release \
    -sdk iphonesimulator${SDK}
xcodebuild -project MapView/MapView.xcodeproj -target $TARGET -configuration Release \
    -sdk iphoneos${SDK}

#
# make fat binary
#
lipo -create MapView/build/Release-iphoneos/lib${LIB_NAME}.a \
             MapView/build/Release-iphonesimulator/lib${LIB_NAME}.a \
             -o "${OUTPUT}/lib${LIB_NAME}.a"

#
# copy headers
#
mkdir "${OUTPUT}/Headers"
for header in `ls MapView/Map/*.h`; do
  cp -v $header "${OUTPUT}/Headers" # rename main header
done

#
# copy resource bundle
#
cp -r -v MapView/build/Release-iphoneos/${LIB_NAME}.bundle $OUTPUT/${LIB_NAME}.bundle
