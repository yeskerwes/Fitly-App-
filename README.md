---

# Fitly — Minimal Viable Product (MVP) (iOS)

Fitly is a lightweight **iOS application** that helps users build consistent daily fitness habits through short, repeatable exercise challenges (“bets”). Each challenge defines a clear daily goal for a fixed period. The app tracks daily completion, maintains streaks, and stores all progress locally on the device.

The MVP focuses on simplicity, reliability, and habit formation rather than complex fitness planning or social features.

---

## Product Overview

Fitly enables users to:

* Create short daily exercise challenges (“bets”)
* Mark daily completion
* Track streaks and progress history

The application is intentionally minimal and optimized for fast daily interaction.

---

## Problem and Proposed Solution

**Problem:**
Many users fail to maintain fitness routines due to a lack of structure and immediate feedback. Complex fitness apps often overwhelm users and reduce consistency.

**Solution:**
Fitly provides a minimal challenge-based system where users define simple daily goals and receive instant visual feedback through streaks and progress indicators. All data is stored locally to ensure privacy and reliability.

---

## Target Users

* Users new to fitness who need a simple daily routine
* Users motivated by streaks and visual progress
* Individuals who prefer minimal, distraction-free mobile apps

---

## Technology Stack

* Platform: iOS
* Language: Swift
* UI Framework: UIKit
* Layout: SnapKit
* Architecture: Layered UIKit architecture with feature-based organization
* Persistence: Core Data (local storage)
* Tooling: Xcode
* Testing: XCTest (unit tests)

---

## Project Structure

High-level overview of the repository structure:

```
Fitly App
├─ assets
├─ Controller
│  ├─ MainTabBarController
│  └─ SplashViewController
├─ Data
│  ├─ Entity
│  └─ CoreDataManager
├─ Delegates
│  ├─ AppDelegate
│  └─ SceneDelegate
├─ Features
│  ├─ Home Page
│  ├─ History Page
│  ├─ Profile Page
│  └─ Search Page
├─ Assets
├─ Info
└─ LaunchScreen
```

* **Controller** — root navigation and lifecycle controllers
* **Features** — feature-specific UI and logic, organized by screen
* **Data** — Core Data entities and persistence management
* **Delegates** — application and scene lifecycle
* **Assets / LaunchScreen** — UI resources and launch configuration

---

## How to Run the Project Locally

### System Requirements

* macOS with Xcode 15 or newer
* iOS Simulator or physical iOS device
* Minimum supported iOS version: iOS 16

### Installation and Run

1. Clone the repository:

   ```bash
   git clone https://github.com/yeskerwes/Fitly-App-.git
   cd Fitly-App-
   ```

2. Open the project in Xcode:

   ```bash
   open Fitly.xcodeproj
   ```

3. Select an iOS simulator or connected device.

4. Build and run the application:

   * From Xcode: **Product → Run (⌘R)**

No environment variables or additional configuration are required.

---

## How to Run Tests

* Run all unit tests:

  * **Product → Test (⌘U)** in Xcode

Tests are written using XCTest and focus on core logic and data handling.

---

## Repository Documents

Additional documentation included in this repository:

* `PRD.md` — Product Requirements Document
* `Architecture.md` — System architecture (iOS)
* `API.md` — API specification (reserved for future extensions)
* `User_Stories.md` — User stories and acceptance criteria

---

## Notes

* This MVP uses **local-only persistence**.
* No authentication or network communication is implemented.
* The architecture is intentionally simple and optimized for MVP scope.

---

## Contact

Repository maintainer: yeskerwes
Repository URL: [https://github.com/](https://github.com/)yeskerwes/Fitly-App-

---
