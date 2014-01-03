#!/bin/sh

PATH="/bin:/usr/bin:/usr/libexec"
VERSION=`git tag | sort -r | sed -n '1p'`
SDK="6.1"
TARGET="MapView"
FW_NAME="Mapbox"
FW_FOLDER="build/$FW_NAME.framework"

#
# clean old version
#
if [ -d $FW_FOLDER ]; then
  echo "Removing old build..."
  rm -rf MapView/build
  rm -rf build
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
cp -v framework.plist $FW_FOLDER/Versions/A/Resources/Info.plist
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
lipo -create MapView/build/Debug-iphoneos/lib${FW_NAME}.a   MapView/build/Debug-iphonesimulator/lib${FW_NAME}.a   -o $FW_FOLDER/${FW_NAME}Debug
lipo -create MapView/build/Release-iphoneos/lib${FW_NAME}.a MapView/build/Release-iphonesimulator/lib${FW_NAME}.a -o $FW_FOLDER/${FW_NAME}

#
# copy headers
#
for header in `ls MapView/Map/*.h | grep -v $FW_NAME.h`; do
  cp -v $header $FW_FOLDER/Versions/A/Headers
done

cp -v MapView/Map/$FW_NAME.h $FW_FOLDER/Versions/A/Headers

#
# copy resource bundle
#
cp -r -v MapView/build/Release-iphoneos/$FW_NAME.bundle $FW_FOLDER/Versions/A/Resources