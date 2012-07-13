MapBox iOS SDK
--------------

Based on the Route-Me iOS map library (Alpstein fork) with custom [MapBox][mapbox] additions. 

Requires iOS 5 and Xcode 4.3 or greater. Does not yet support ARC. 

Undergoing rapid development, so the `develop` branch is currently recommended. 

Major differences from [Alpstein fork of Route-Me](https://github.com/Alpstein/route-me): 

 * Requires iOS 5.0 and above. 
 * Canonical source for [MapBox](http://mapbox.com) & [MBTiles](http://mbtiles.org) tile source integration code. 
 * [UTFGrid interactivity](http://mapbox.com/mbtiles-spec/utfgrid/). 
 * [User location services](http://mapbox.com/blog/ios-user-location-services/). 
 * Removal of two-finger double-tap gesture for zoom out (to speed up two-finger single-tap recognition like MapKit). 
 * Different default starting location for maps. 
 * Built-in attribution view controller with button on map views & default OpenStreetMap attribution. 
 * [MapBox Markers](http://mapbox.com/blog/markers/) support. 
 * Prepackaged [binary framework](http://mapbox.com/blog/ios-sdk-framework/). 

[mapbox]: http://mapbox.com

Route-Me
--------

Route-Me is an open source map library that runs natively on iOS.  It's designed to look and feel much like the built-in iOS map library, but it's entirely open, and works with any map source.

Currently, [OpenStreetMap][1], [OpenCycleMap][2], [OpenSeaMap][3], [MapQuest OSM][4], [MapQuest Open Aerial][5], [MapBox Hosting][6]/[TileStream][7], and two offline-capable, database-backed formats (DBMap and [MBTiles][8]) are supported as map sources.

Please note that you are responsible for getting permission to use the map data, and for ensuring your use adheres to the relevant terms of use.

   [1]: http://www.openstreetmap.org/index.html
   [2]: http://www.opencyclemap.org/
   [3]: http://www.openseamap.org/
   [4]: http://developer.mapquest.com/web/products/open/map
   [5]: http://developer.mapquest.com/web/products/open/map
   [6]: http://mapbox.com/hosting/api/
   [7]: https://github.com/mapbox/tilestream
   [8]: http://mbtiles.org

Installing
----------

**New:** Try the [prepackaged framework](https://github.com/mapbox/mapbox-ios-sdk/downloads). Use like regular frameworks, linking it in your project, adding `#import <MapBox/MapBox.h>`, and additionally, including the `-ObjC` linker flag. 

As the SDK is undergoing some significant changes, the recommended course of action is to clone a copy of the repository:

      git://github.com/mapbox/mapbox-ios-sdk.git

Or, [download the trunk][dl].

The two main branches are pretty self-explanatory: `release` and `develop`. When we tag a [release](https://github.com/mapbox/mapbox-ios-sdk/tags), we also merge `develop` over to `release`. 

Then, update the submodules:

      git submodule update --init

Example app showing usage:

      https://github.com/mapbox/mapbox-ios-example

More documentation is available: 

      http://mapbox.com/mobile/docs/sdk


There are two subdirectories - MapView and Proj4. Proj4 is a support library used to do map projections. The MapView project contains only the Route-Me map library. 

See License.txt for license details. In any app that uses the Route-Me library, include the following text on your "preferences" or "about" screen: "Uses Route-Me map library, (c) 2008-2012 Route-Me Contributors". Your data provider will have additional attribution requirements.

   [dl]: https://github.com/mapbox/mapbox-ios-sdk/zipball/develop

News, Support and Contributing
------------------------------

The MapBox iOS SDK has a [support resource][support] where you can open cases and browse other developers' discussions about use of the SDK. 

We have a [basic technical overview][docs] along with the installation instructions. 

MapBox has an IRC channel on `irc.freenode.net` in `#mapbox`. 

The main Route-Me project has a [mailing list][list] for news and to communicate with project members and other users. 

To report bugs and help fix them, please use the [issue tracker][tracker]. 

[support]: http://support.mapbox.com/discussions/mapbox-ios-sdk
[docs]: http://mapbox.com/mobile/docs/sdk
[list]: http://groups.google.com/group/route-me-map
[tracker]: https://github.com/mapbox/mapbox-ios-sdk/issues
