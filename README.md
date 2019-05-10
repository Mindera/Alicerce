# Alicerce 🏗

> from Portuguese:
>
> _noun_ • [ masculine ] /ali’sɛɾsɪ/
> 
> **groundwork**, **foundation**, **basis**

[![license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/Mindera/Alicerce/blob/master/LICENSE)
[![release](https://img.shields.io/github/release/Mindera/Alicerce.svg)](https://github.com/Mindera/Alicerce/releases)
![platforms](https://img.shields.io/badge/platforms-iOS-lightgrey.svg)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/Alicerce.svg)](https://cocoapods.org/)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager)
[![Build Status](https://travis-ci.org/Mindera/Alicerce.svg?branch=master)](https://travis-ci.org/Mindera/Alicerce)
[![codecov](https://codecov.io/gh/Mindera/Alicerce/branch/master/graph/badge.svg)](https://codecov.io/gh/Mindera/Alicerce)
[![Join the chat at https://gitter.im/Mindera/Alicerce](https://badges.gitter.im/Mindera/Alicerce.svg)](https://gitter.im/Mindera/Alicerce?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

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

## Documentation 📄

All the documentation can be found in the [Documentation folder](./Documentation):

1. **[Network](./Documentation/Network.md)**
1. _more coming soon..._

## Examples 👀

TODO

## Compatibility ✅

### `master` (latest)

- iOS 10.0+
- Xcode 10.2
- Swift 5.0

### `0.6.0` (latest)

- iOS 9.0+
- Xcode 10.2
- Swift 5.0

### `0.4.0` ... `0.5.0`

- iOS 9.0+  
- Xcode 10
- Swift 4.2

### `0.2.x` ... `0.3.0`

- iOS 9.0+  
- Xcode 9.3
- Swift 4.1

### `0.1.0`

- iOS 9.0+  
- Xcode 9
- Swift 4.0

### CocoaPods

If you use [CocoaPods][] to manage your dependencies, simply add Alicerce to your `Podfile`:

```ruby
pod 'Alicerce', '~> 0.6'
```

### Carthage

If you use [Carthage][] to manage your dependencies, simply add Alicerce to your `Cartfile`:

```
github "Mindera/Alicerce" ~> 0.6
```

If you use Carthage to build your dependencies, make sure you have added `Alicerce.framework` to the 
"_Linked Frameworks and Libraries_" section of your target, and have included them in your Carthage framework copying build 
phase.

### Swift Package Manager

If you use Swift Package Manager, simply add Alicerce as a dependency of your package in `Package.swift`:

```swift
.package(url: "https://github.com/Mindera/Alicerce.git", from: "0.6.0"),
```

### git Submodule

1. Add this repository as a [submodule][].
1. Drag Alicerce.xcodeproj into your project or workspace.
1. Link your target against Alicerce.framework.
1. If linking against an Application target, ensure the framework gets copied into the bundle. If linking against a Framework target, 
the application linking to it should also include Alicerce.

## Setup 🛠

Setting up the project for development is simple:

1. Clone the repository.
1. Open `Alicerce.xcworkspace`
1. Build `Alicerce` scheme

## Contributing 🙌

See [CONTRIBUTING].

## License ⚖️

Alicerce is Copyright (c) 2016 - present Mindera and is available under the MIT License. It is free software, and may be redistributed under the terms specified in the [LICENSE] file.

## About 👥

With ❤️ from [Mindera](https://www.mindera.com) 🤓

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

[LICENSE]: ./LICENSE
[CONTRIBUTING]: ./CONTRIBUTING.md
