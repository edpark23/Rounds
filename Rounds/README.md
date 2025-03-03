# Rounds - Golf Match Making App

A SwiftUI-based iOS application that matches golfers based on their ELO ratings and facilitates score tracking through OCR technology.

## Features

- User authentication with Email and Apple ID
- ELO-based ranking system
- Real-time leaderboard
- Smart matchmaking system
- Golf scorecard OCR scanning
- Match history tracking

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- CocoaPods or Swift Package Manager
- Firebase account

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/Rounds.git
cd Rounds
```

2. Install dependencies
```bash
pod install
```
or if using Swift Package Manager, open the project in Xcode and wait for package resolution.

3. Configure Firebase
- Create a new Firebase project
- Download `GoogleService-Info.plist` and add it to the project
- Enable Authentication and Firestore in Firebase Console

4. Open the project
```bash
open Rounds.xcworkspace
```
or open `Rounds.xcodeproj` if using Swift Package Manager

## Architecture

The app follows a clean architecture pattern with MVVM:

- Views: SwiftUI views
- ViewModels: Business logic and state management
- Models: Data models and entities
- Services: Network, authentication, and other services

## License

[Your chosen license] 