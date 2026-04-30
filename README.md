
<p align="center"><img src="Unflagr/Assets.xcassets/AppIcon.appiconset/slot-512-2x.png" width="128" alt="Unflagr icon"></p>

# Unflagr

Get rid of the **"This app is damaged and can't be opened"** dialog on macOS.

## What it does

Drop any app onto Unflagr and remove the quarantine flag that makes macOS block it — one click and it opens normally. You can also inspect and remove any other extended attributes on files and folders. 
This is actually the same like typing *xattr -d com.apple.quarantine appname* into the Terminal.

## Installation

Download the latest release from the [GitHub Releases](https://github.com/garygru/Unflagr/releases) page.

## Requirements

- macOS 14 or later
- Xcode 16

## Building

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project.

```sh
brew install xcodegen
xcodegen generate
open Unflagr.xcodeproj
```

