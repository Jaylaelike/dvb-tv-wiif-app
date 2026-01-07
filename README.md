# DVB-T2 Portable WiFi Streaming App

A cross-platform Flutter application for streaming DVB-T2 digital television content over portable WiFi. Watch live TV on your mobile device by scanning a QR code to connect to your DVB-T2 WiFi adapter.

## Features

- **QR Code Scanning**: Quickly connect to your DVB-T2 WiFi device by scanning a QR code
- **Cross-Platform Support**: Native iOS and Android mobile applications
- **Live TV Streaming**: Watch DVB-T2 digital television broadcasts in real-time
- **WiFi Direct Connection**: Connect directly to your portable DVB-T2 WiFi adapter
- **User-Friendly Interface**: Clean, intuitive mobile interface for easy navigation
- **Channel Management**: Browse and switch between available TV channels
- **Multi-Device Support**: Works with various DVB-T2 portable WiFi adapters

## Hardware Requirements

- DVB-T2 Portable WiFi Adapter (USB or standalone device)
- Mobile device running iOS 12.0+ or Android 5.0+
- Active DVB-T2 signal in your area

## Screenshots

<table>
  <tr>
    <td><img src="https://56fwnhyzti.ufs.sh/f/aK4w8mNL3AiPv4M0J0POpH0Xvsh1zmwoYGdrn5aEZ4iP7gMQ" alt="Home Screen" width="200"/></td>
    <td><img src="https://56fwnhyzti.ufs.sh/f/aK4w8mNL3AiPcnEpHxN5IxbAyNMkvfW9aX6s1SB0K7wcQdYu" alt="QR Scanner" width="200"/></td>
    <td><img src="https://56fwnhyzti.ufs.sh/f/aK4w8mNL3AiPbtMKqj2pYTMgVenQFZajfRIEm9A73kXGlq6y" alt="Channel List" width="200"/></td>
  </tr>
  <tr>
    <td align="center">Mobile App Interface</td>
    <td align="center">DVB-T2 Device</td>
    <td align="center">Portable WiFi Adapter</td>
  </tr>
</table>
Web Browser Interface
<p align="center">
  <img src="https://56fwnhyzti.ufs.sh/f/aK4w8mNL3AiPBQZeWm59GueIrkpJMCUPQOxXH5jvmzc0TVnh" alt="Web Browser Interface" width="600"/>
</p>

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Xcode 13+ (for iOS development)
- Android Studio with Android SDK (for Android development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Jaylaelike/dvb-tv-wiif-app.git
cd dvb-t2-wifi-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

## How to Use

1. **Power on your DVB-T2 WiFi adapter** and ensure it's broadcasting a WiFi network
2. **Open the app** on your mobile device
3. **Tap "Scan QR Code"** to activate the camera
4. **Scan the QR code** displayed on your DVB-T2 device or in its manual
5. **Wait for connection** - the app will automatically connect to the WiFi network
6. **Browse channels** and start watching live TV

## Platform-Specific Setup

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan QR codes</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Network access is required to connect to DVB-T2 device</string>
```

### Android

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Building for Production

### Android APK

```bash
flutter build apk --release
```

### iOS IPA

```bash
flutter build ios --release
```

## Troubleshooting

**Connection Issues**
- Ensure your DVB-T2 device is powered on and broadcasting WiFi
- Check that WiFi is enabled on your mobile device
- Verify the QR code contains valid connection information

**No Video Playback**
- Confirm DVB-T2 signal strength in your area
- Check that the streaming port is not blocked
- Try switching to a different channel

**QR Scanner Not Working**
- Grant camera permissions to the app
- Ensure adequate lighting when scanning
- Hold the device steady and at the correct distance

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## Acknowledgments

- Flutter team for the amazing cross-platform framework
- DVB-T2 standard contributors
- Open source community for various packages used

---

**Note**: This app requires a compatible DVB-T2 portable WiFi adapter. Ensure your device supports WiFi streaming before use.