# Weather Widget

A macOS menu bar app for showing the weather on your lock screen. Built with SwiftUI and AppKit, using CoreLocation for your location and Open-Meteo for weather data.

This is a work in progress and is macOS-only. The lock screen integration is experimental and uses private macOS window APIs.

## What's included

- Current temperature, conditions, location, and daily highs and lows.
- Standard, compact, circular, and detailed widget layouts.
- Position controls and a widget preview from the menu bar.
- A manual weather refresh button.

Weather is based on your device's location. If location access is denied or fails, the app falls back to San Francisco. No weather API key is needed.

## Run locally

The Xcode project targets macOS 14 Sonoma or later. You'll need Xcode with the macOS SDK installed.

1. Clone the repository:

   ```bash
   git clone https://github.com/CharlieJBlack/Weather-Widget.git
   ```

2. Open `Weather-Widget/LockScreenWeather.xcodeproj` in Xcode.
3. Select the `LockScreenWeather` target and choose your development team under Signing & Capabilities.
4. Choose My Mac as the run destination, then build and run.
5. Allow location access when prompted to get weather for your area.

The app runs in the menu bar, without a Dock icon. Click the weather icon to preview the widget, change its layout or position, refresh the weather, or quit.
