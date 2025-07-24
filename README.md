# Namida Intent Demo

This demo project serves as a proof of concept to showcase configuration passing between Namida and Namida Sync on Android and Windows platforms and will be integrated directly into Namida. The implementation patterns shown here will be used to enable seamless configuration passing between Namida and Namida Sync.

## Overview

This app demonstrates how to reliably pass backup folder and music folder configurations from Namida to Namida Sync using:

- **Android:** Platform channels and explicit intents
- **Windows:** EXE picker and command-line arguments

## Features

- Pick backup folder and music folders
- Launch Namida Sync with the selected configuration
- Store Namida Sync EXE path on Windows
- Cross-platform support (Android/Windows)

## Usage

### Android
1. Install both Namida Intent Demo and Namida Sync
2. Select your backup and music folders paths with Namida Intent Demo
3. Tap "Go to Namida Sync" to pass the configuration

### Windows
1. Select your backup and music folders
2. On first launch, pick the location of `namida_sync.exe`
3. Click "Go Namida Sync" to pass the configuration

## Implementation Details

For technical details about the implementation, see:
- [Intent-Based Config Passing Documentation](https://github.com/010101-sans/namida_sync/blob/main/docs/INTENT_BASED_CONFIG_PASSING.md)

## Development

This app is built with Flutter and demonstrates:
- Platform channels
- Android intent handling
- Windows process management
- Cross-app communication