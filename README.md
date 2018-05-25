# Alicerce 🏗

> from Portuguese:
>
> _noun_ • [ masculine ] /ali’sɛɾsɪ/
> 
> **groundwork**, **foundation**, **basis**

[![license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/Mindera/Alicerce/blob/master/LICENSE)
[![release](https://img.shields.io/github/release/Mindera/Alicerce.svg)](https://github.com/Mindera/Alicerce/releases)
![platforms](https://img.shields.io/badge/platforms-iOS-lightgrey.svg)
[![Swift 4.0](https://img.shields.io/badge/Swift-4-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/Alicerce.svg)](https://cocoapods.org/)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager)
[![Build Status](https://travis-ci.org/Mindera/Alicerce.svg?branch=master)](https://travis-ci.org/Mindera/Alicerce)
[![codecov](https://codecov.io/gh/Mindera/Alicerce/branch/master/graph/badge.svg)](https://codecov.io/gh/Mindera/Alicerce)

## What is it? 🤔

Ever felt that you keep repeating yourself every time you start a new project? That you would like to have all those useful utils and helpers you love already available? We felt that way too! Thus, Alicerce was born. 🏗

Alicerce is a framework that aims to serve as a starting point for iOS applications, by providing the foundations for many of the common functionalities a modern application requires, as well as be a repository for those small utils and helpers that make our life easier.

It is designed with an MVVM architecture in mind, but you'll find most components are architecture agnostic.

## Main features ✨

1. **[Analytics][] 🔍**
1. **[Deep Linking][DeepLinking] 🔗**
1. **[Logging][] 📝**
1. **[Network][] 🌍**
1. **[Persistence][] 💾**
1. **[Performance Metrics][PerformanceMetrics] 📈**
1. **[Utils][] ⚙️**
1. **[UI][UIKit] 📲**

## Examples 👀

TODO

## Installation 🔧

Alicerce supports iOS 9.0+ and requires Xcode 9+.

#### Important note regarding `CommonCrypto` ⚠️

Since Apple's `CommonCrypto` isn't directly importable from Swift yet, Alicerce uses a dummy `CCommonCrypto` framework defined in a custom [modulemap](https://github.com/Mindera/Alicerce/blob/master/Sources/DummyFrameworks/CCommonCrypto/module.modulemap). 

This modulemap requires that the header `/usr/include/CommonCrypto/CommonCrypto.h` is available, so please ensure it is present on your machine/CI environment. If not, you should run `xcode-select --install` to install it.

### CocoaPods

If you use [CocoaPods][] to manage your dependencies, simply add Alicerce to your `Podfile`:

```ruby
pod 'Alicerce', '~> 0.2'
```

### Carthage

If you use [Carthage][] to manage your dependencies, simply add Alicerce to your `Cartfile`:

```
github "Mindera/Alicerce" ~> 0.2
```

If you use Carthage to build your dependencies, make sure you have added `Alicerce.framework` to the 
"_Linked Frameworks and Libraries_" section of your target, and have included them in your Carthage framework copying build 
phase.

### Swift Package Manager

If you use Swift Package Manager, simply add ReactiveSwift as a dependency of your package in `Package.swift`:

```swift
.Package(url: "https://github.com/Mindera/Alicerce.git", majorVersion: 0, minor: 2),
```

### git Submodule

1. Add this repository as a [submodule][].
1. Drag Alicerce.xcodeproj into your project or workspace.
1. Link your target against Alicerce.framework.
1. If linking against an Application target, ensure the framework gets copied into the bundle. If linking against a Framework target, 
the application linking to it should also include Alicerce.

## Contributing 🙌

See [CONTRIBUTING](https://github.com/Mindera/Alicerce/blob/master/CONTRIBUTING.md).

### With ❤️ from [Mindera](https://www.mindera.com) 🤓

[Analytics]: https://github.com/Mindera/Alicerce/tree/master/Sources/Analytics
[DeepLinking]: https://github.com/Mindera/Alicerce/tree/master/Sources/DeepLinking
[Logging]: https://github.com/Mindera/Alicerce/tree/master/Sources/Logging
[Network]: https://github.com/Mindera/Alicerce/tree/master/Sources/Network
[Persistence]: https://github.com/Mindera/Alicerce/tree/master/Sources/Persistence
[PerformanceMetrics]: https://github.com/Mindera/Alicerce/tree/master/Sources/PerformanceMetrics
[QuartzCore]: https://github.com/Mindera/Alicerce/tree/master/Sources/QuartzCore
[Resource]: https://github.com/Mindera/Alicerce/tree/master/Sources/Resource
[Stores]: https://github.com/Mindera/Alicerce/tree/master/Sources/Stores
[UIKit]: https://github.com/Mindera/Alicerce/tree/master/Sources/UIKit
[Utils]: https://github.com/Mindera/Alicerce/tree/master/Sources/Utils
[View]: https://github.com/Mindera/Alicerce/tree/master/Sources/View

[Carthage]: https://github.com/Carthage/Carthage/#readme
[CocoaPods]: https://cocoapods.org/
[submodule]: https://git-scm.com/docs/git-submodule

