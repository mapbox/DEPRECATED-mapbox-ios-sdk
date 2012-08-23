#!/bin/sh

PATH="/bin:/usr/bin:/usr/libexec"
VERSION=`git tag | sort -r | sed -n '1p'`
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
xcodebuild -project MapView/MapView.xcodeproj -target $TARGET -configuration Debug   -sdk iphonesimulator${SDK}
xcodebuild -project MapView/MapView.xcodeproj -target $TARGET -configuration Debug   -sdk iphoneos${SDK}
xcodebuild -project MapView/MapView.xcodeproj -target $TARGET -configuration Release -sdk iphonesimulator${SDK}
xcodebuild -project MapView/MapView.xcodeproj -target $TARGET -configuration Release -sdk iphoneos${SDK}

#
# make fat binaries
#
lipo -create MapView/build/Debug-iphoneos/lib${TARGET}.a   MapView/build/Debug-iphonesimulator/lib${TARGET}.a   -o $FW_FOLDER/${FW_NAME}Debug
lipo -create MapView/build/Release-iphoneos/lib${TARGET}.a MapView/build/Release-iphonesimulator/lib${TARGET}.a -o $FW_FOLDER/$FW_NAME

#
# copy headers & create all-inclusive
#
for header in `ls MapView/Map/*.h | grep -v RouteMe.h | sed 's/MapView\/Map\///'`; do
  cp -v "MapView/Map/$header" $FW_FOLDER/Versions/A/Headers
  echo "#import \"$header\"" >> $FW_FOLDER/Versions/A/Headers/$FW_NAME.h
done

#
# copy resources
#
cp -v MapView/Map/Resources/*  $FW_FOLDER/Versions/A/Resources