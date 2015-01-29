# Releasing

## GitHub

1. Choose a version number per [Semantic Versioning](http://semver.org/). Let's call it `x.y.z`. 
1. If appropriate, update `screenshot.png` in the `packaging` branch. 
1. Switch to `release` at a point where the release code is ready to go. 
1. Update `CHANGELOG.md` with change notes for the version. 
1. Update `README.markdown` as appropriate. Note that it references the screenshot mentioned above. 
1. Update `Mapbox.podspec` with the version and any other necessary changes. 
    - The local spec should reference the version above, not a branch. 
    - Be sure to lint the spec with `pod spec lint`. 
1. Create a tag with `x.y.z` in `release` and push the tag. 

## www.mapbox.com

1. Update the website docs in the `mb-pages` branch as appropriate. Be sure to update `version` in `_config.yml` and `_config.mb-pages.yml` with `x.y.z`. These docs might also reference `screenshot.png` if it was updated above, so be sure to check context. 
1. Copy the `update_docs.sh` script from the `packaging` branch into `release` and run it to update `./api` with HTML documentation output. 
1. Copy `./api` over to `mb-pages` for publishing on the site under `/api`. 

## CocoaPods

1. Release on CocoaPods via `pod trunk push`. 

## Binary download

1. Switch to `packaging` and copy aside the `package.sh` script. 
1. Switch back to `release`, copy in `package.sh`, and run it. 
1. Zip up the product in `./dist` in a folder named `Mapbox-iOS-SDK-x.y.z` and update [S3](http://mapbox-ios-sdk.s3.amazonaws.com/index.html) with:

```bash
mapbox auth production
aws s3 cp --acl public-read Mapbox-iOS-SDK-x.y.z.zip s3://mapbox-ios-sdk/Mapbox-iOS-SDK-x.y.z.zip.
aws s3 cp s3://mapbox-ios-sdk/index.html index.html
<edit index.html>
aws s3 cp --acl public-read index.html s3://mapbox-ios-sdk/index.html
```
