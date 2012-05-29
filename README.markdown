MapBox iOS SDK
--------------

Based on the Route-Me iOS map library (Alpstein fork) with custom MapBox additions. 

Requires iOS 5 or greater. Does not yet support ARC. 

Undergoing rapid development, so the `develop` branch is currently recommended. 

Major differences from [Alpstein fork of Route-Me](https://github.com/Alpstein/route-me): 

 * Canonical source for [MapBox](http://mapbox.com) & [MBTiles](http://mbtiles.org) tile source integration code
 * [UTFGrid interactivity](http://mapbox.com/mbtiles-spec/utfgrid/)
 * [Composited tile sources](https://github.com/mapbox/mapbox-ios-sdk/blob/develop/MapView/Map/RMCompositeSource.h) (IN DEVELOPMENT)
 * [Use location services](http://mapbox.com/blog/ios-user-location-services/) (IN DEVELOPMENT)
 * Removal of two-finger double-tap gesture for zoom out (to speed up two-finger single-tap recognition like MapKit)
 * Different default starting location for maps

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

As the SDK is undergoing some significant changes, the recommended course of action is to clone a copy of the repository:

      git://github.com/mapbox/mapbox-ios-sdk.git

Or, [download the trunk][dl].

Then, update the submodules:

      git submodule update --init

Example app showing usage:

      https://github.com/mapbox/mapbox-ios-example

More documentation is available: 

      http://mapbox.com/mobile/docs/sdk


There are three subdirectories - MapView, Proj4, and samples. Proj4 is a support class used to do map projections. The MapView project contains only the route-me map library. "samples" contains some ready-to-build projects which you may use as starting points for your own applications, and also some engineering test cases. `samples/SampleMap` and `samples/ProgrammaticMap` are the best places to look, to see how to embed a Route-Me map in your application.

See License.txt for license details. In any app that uses the Route-Me library, include the following text on your "preferences" or "about" screen: "Uses Route-Me map library, (c) 2008-2012 Route-Me Contributors". Your data provider will have additional attribution requirements.


   [dl]: https://github.com/mapbox/mapbox-ios-sdk/zipball/develop
   
   
News, Support and Contributing
------------------------------

To report bugs and help fix them, please use the [issue tracker][tracker]. 

For general help, check out the [support queue][queue]. 

[tracker]: https://github.com/mapbox/mapbox-ios-sdk/issues
[queue]: http://support.mapbox.com/discussions/mapbox-ios-sdk
