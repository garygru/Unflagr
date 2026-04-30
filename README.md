# Unflagr

A macOS utility for inspecting and removing extended attributes (xattrs) from files and apps — including the quarantine flag that triggers Gatekeeper warnings.

## What it does

Drop any file or app onto Unflagr to see its extended attributes. You can remove the quarantine attribute (`com.apple.quarantine`) with one click, or strip all xattrs at once.

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
