## 1.3.1

- Updated SGHTTPRequest dependency

## 1.3.0

- Added support for setting client secret
- Improved caching system
- Improved compatibility with App Extensions
- Reworked query parameter and filter building to use NSURLQueryItem, bumped min deployment target to iOS 8
- Add ability to clear location on queries
- Added a way to get the total number of items in an SGItemSet
- Added some nullability hints for swift

## 1.2.0

- Added support for WatchOS 2
- Removed SGImageCache Dependency
- Added swift nullable hits to some methods
- Added ability to cache SGItemSet results to disk
- Miscellaneous bug fixes

## 1.1.1

- Fixed a bug that could happen with null data
- Added from and to date parameters for SGQuery to fetch results with date ranges (where supported)
- Added some keywords to make SGItemSet play nicer with swift 1.2

## 1.1.0

- Stricter type checking/casting of response values
- Added `requestHeaders` dictionary to SGQuery
- Misc minor bug fixes and performance improvements

## 1.0.3

Leave console logging up to SGHTTPRequest

## 1.0.2

Response dict null cleansing fix

## 1.0.1

Added aid and rid properties to SGQuery

## 1.0.0

Initial release
