## Table Of Contents

* [2.0.3](#2.0.3)
* [2.0.2](#2.0.2)
* [2.0.1](#2.0.1)
* [2.0.0](#2.0.0)
* [1.0.5](#1.0.5)
* [1.0.4](#1.0.4)
* [1.0.3](#1.0.3)
* [1.0.2](#1.0.2)
* [1.0.1](#1.0.1)
* [1.0.0](#1.0.0)
* [0.5.0](#0.5.0)
* [0.1.0](#0.1.0)

## 2.0.3

- Fixed bug when only headers are received, this is no longer considered an error. 

## 2.0.2

- Bug fixing

## 2.0.1

- Improved `mark` styling
- Amended objc signature for `registerStack`

## 2.0.0

- Swift implementation
- Unit testing
- Improved README

## 1.0.5

- Swift compatible initializer
- Stacks are inserted as dependency and apps can have as many as needed.
- Added signature for using requests instead of URL.
- Added signature using a unique completion block instead of success/failure.
- Added Cancel download by downloadId

## 1.0.4

- Removed location from callback.

## 1.0.3

- MultiDownload bugs.
- Restoring the completion blocks on the operation they were originally created in.

## 1.0.2

- Multidownload bug fixed.

## 1.0.1

- Added umbrella to remove xcode warning.
- Added EDSDebug macro to show let developers choose whether to show non error logs.
- Removed DATA session wrapping.

## 1.0.0

- Listen to memory warnings and release the NSData stored.

## 0.5.0

- Added Success Block.
- Added Progress Block.
- Added Failure Block.

## 0.1.0

- Download task that can be paused and resumed.
- Session can be configured to allow multiple concurrent downloads.

