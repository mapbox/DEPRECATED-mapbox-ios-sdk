#!/bin/sh

PATH="/bin:/usr/bin:/usr/libexec"
VERSION=`git describe --tags | awk -F '-' '{ print $1 }'`
SDK="5.1"
TARGET="MapView"
FW_NAME="MapBox"
FW_FOLDER="build/$FW_NAME.framework"

#
# clean old version
#
if [ -d $FW_FOLDER ]; then
  rm -rf $FW_FOLDER
fi

#
# folder & symlink structure
#
mkdir -p $FW_FOLDER/Versions/A/Headers
mkdir -p $FW_FOLDER/Versions/A/Resources

cd $FW_FOLDER
ln -s Versions/A/Headers Headers
ln -s Versions/A/Resources Resources
cd Versions
ln -s A Current
cd ../../..

#
# Info.plist & version
#
cp framework.plist $FW_FOLDER/Versions/A/Resources/Info.plist
PlistBuddy $FW_FOLDER/Versions/A/Resources/Info.plist -c "Set :CFBundleVersion $VERSION"

#
# build static lib variants
#
xcodebuild -target $TARGET -configuration Debug   -sdk iphonesimulator${SDK}
xcodebuild -target $TARGET -configuration Debug   -sdk iphoneos${SDK}
xcodebuild -target $TARGET -configuration Release -sdk iphonesimulator${SDK}
xcodebuild -target $TARGET -configuration Release -sdk iphoneos${SDK}

#
# make fat binaries
#
lipo -create build/Debug-iphoneos/lib${TARGET}.a   build/Debug-iphonesimulator/lib${TARGET}.a   -o $FW_FOLDER/${FW_NAME}Debug
lipo -create build/Release-iphoneos/lib${TARGET}.a build/Release-iphonesimulator/lib${TARGET}.a -o $FW_FOLDER/$FW_NAME

#
# copy headers & create all-inclusive
#
for header in `ls Map/*.h | grep -v RouteMe.h | sed 's/Map\///'`; do
  cp -v "Map/$header" $FW_FOLDER/Versions/A/Headers
  echo "#import \"$header\"" >> $FW_FOLDER/Versions/A/Headers/$FW_NAME.h
done

#
# copy resources
#
cp -v Map/Resources/*  $FW_FOLDER/Versions/A/Resources