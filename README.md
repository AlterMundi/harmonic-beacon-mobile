# Harmonic Beacon Mobile

The mobile experience for Harmonic Beacon, built with React Native and Expo.

## Prerequisites

- Node.js 20+
- [Expo Go](https://expo.dev/client) app installed on your phone (iOS or Android)
- OR Android Studio / Xcode for simulators

## Getting Started

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Run the app**:
   ```bash
   # Start the development server (best for testing on physical device via Expo Go)
   npm start
   
   # Run on Android Emulator
   npm run android
   
   # Run on iOS Simulator (macOS only)
   npm run ios
   ```

## Project Structure

- `app/`: File-based routing (Expo Router)
  - `(tabs)/`: Main tab navigation (Live, Meditate, Sessions)
  - `(auth)/`: Authentication screens (Login, Signup)
- `components/`: Reusable UI components
- `constants/`: Design system tokens (Colors.ts)
- `context/`: Application state (AuthContext)
- `assets/design/`: Brandbook and design files

## Features

- **Live**: Main streaming interface
- **Meditate**: Library of guided sessions playing over the beacon
- **Sessions**: Health tracking (Heart Rate, HRV) integration
- **Authentication**: User accounts and session management
