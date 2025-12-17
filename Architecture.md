---

# Architecture — Fitly MVP (iOS)

---

## 1. Overview

This document describes the technical architecture of the Fitly iOS MVP.
Fitly is a **local-first iOS application** built using UIKit and Core Data. The architecture prioritizes simplicity, clarity, and reliable local persistence suitable for an MVP stage.

The system is implemented as a single iOS application without server communication, authentication, or cloud synchronization.

Goals:

* Simple and predictable user experience.
* Clear separation between UI, features, and data persistence.
* Reliable local data storage using Core Data.
* Architecture suitable for future extensions.

---

## 2. Overall Architecture Style

**Architecture style:**
Client-centric, local-first iOS application with a layered structure.

Characteristics:

* Single iOS application bundle.
* UIKit-based UI layer.
* Feature-oriented screen organization.
* Centralized Core Data persistence.
* No backend dependency in MVP scope.

The architecture is intentionally lightweight and avoids unnecessary abstraction.

---

## 3. Main Components

High-level component structure:

```
+-----------------------+
| iOS Platform          |
+----------+------------+
           |
           v
+--------------------------------+
| Fitly iOS Application          |
|                                |
|  +--------------------------+  |
|  | UIKit Controllers        |  |
|  | (ViewControllers)        |  |
|  +------------+-------------+  |
|               |                |
|  +------------v-------------+  |
|  | Feature Modules          |  |
|  | (Home, History, Profile) |  |
|  +------------+-------------+  |
|               |                |
|  +------------v-------------+  |
|  | CoreDataManager          |  |
|  +------------+-------------+  |
|               |                |
|  +------------v-------------+  |
|  | Core Data Stack          |  |
|  | (Entities & Persistence)|  |
|  +--------------------------+  |
+--------------------------------+
```

---

## 4. Component Descriptions

### 4.1 Presentation Layer (UI)

* Implemented using UIKit.
* Each screen is represented by a `UIViewController`.
* Navigation is managed via `MainTabBarController`.

Key controllers:

* `SplashViewController` — initial loading and entry screen.
* `MainTabBarController` — root navigation container.

Controllers are responsible for:

* Handling user input.
* Updating UI.
* Requesting data from the data layer.

---

### 4.2 Feature Modules

UI logic is organized by feature to improve readability and scalability.

Feature folders:

* **Home Page** — active challenges overview.
* **History Page** — completed days and progress history.
* **Profile Page** — user preferences and app settings.

Each feature contains its own controllers and UI logic.

---

### 4.3 Data Layer

Local persistence is implemented using **Core Data**.

Components:

* **CoreDataManager**

  * Initializes Core Data stack.
  * Manages context lifecycle.
  * Provides CRUD operations.
* **Entity**

  * Core Data entity definitions.

All data is stored locally on the device.
The MVP does not include networking or cloud sync.

---

## 5. Selected Technologies

* **Swift** — native iOS language.
* **UIKit** — stable and well-supported UI framework.
* **SnapKit** — programmatic Auto Layout constraints.
* **Core Data** — structured local persistence.
* **Xcode** — development and debugging.
* **XCTest** — unit testing framework.

Rationale:
These technologies are stable, widely used, and suitable for building a maintainable MVP with minimal overhead.

---

## 6. Database Structure (Core Data Schema)

The Core Data model defines the following entities:

---

### 6.1 ChallengeEntity

Represents a daily exercise challenge (“bet”).

**Attributes:**

* `id` (UUID) — unique identifier
* `title` (String) — challenge name
* `imageName` (String) — associated image
* `quantityPerDay` (Integer 16) — daily target amount
* `days` (Integer 16) — challenge duration in days
* `completedDays` (Integer 16) — number of completed days
* `doneToday` (Integer 16) — completion flag for current day
* `status` (String) — current challenge status
* `createdAt` (Date) — creation timestamp

---

### 6.2 PushupSession

Represents individual activity or completion sessions associated with challenges.

(Used for tracking detailed activity history if required.)

---

### 6.3 Settings

Stores application-level settings and user preferences.

Example use cases:

* Start-of-day configuration
* UI preferences

---

## 7. Data Flow

### A) Create Challenge

1. User creates a challenge via UI.
2. ViewController validates input.
3. CoreDataManager creates a `ChallengeEntity`.
4. Entity is saved to Core Data.
5. UI updates to display the new challenge.

---

### B) Mark Daily Completion

1. User marks a challenge as completed for the day.
2. ViewController updates `doneToday` and increments `completedDays`.
3. Changes are saved via CoreDataManager.
4. UI reflects updated streak and progress.

---

### C) App Restart

1. App launches.
2. Core Data stack is initialized.
3. Existing entities are fetched.
4. UI displays previously stored data without loss.

---

## 8. Error Handling & Data Integrity

* All Core Data operations are wrapped in safe save contexts.
* Errors are logged and handled gracefully.
* No silent data loss is allowed.
* The app relies on Core Data transactional guarantees.

---

## 9. Future Extensions

Potential future improvements:

* Introduce ViewModel layer (MVVM).
* Add repository abstraction.
* Cloud sync and user accounts.
* Analytics and progress insights.
* Background tasks for reminders.
* Migration to SwiftUI if needed.

---

## 10. Summary

The Fitly iOS MVP architecture is:

* Simple and understandable.
* Local-first and reliable.
* Well-suited for MVP delivery.
* Ready for future evolution without major refactoring.

---
