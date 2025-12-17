Product Requirements Document (PRD) — Fitly MVP (iOS)
Overview
This document describes the Fitly Minimal Viable Product (MVP) from a business and user perspective. It defines the product goal, problem statement, target audience, primary user roles, core user scenarios, functional and non-functional requirements, the scope for version 0.2, out-of-scope items, and acceptance criteria for each required feature.
All requirements are expressed in a clear, verifiable, and testable manner. This PRD applies to the iOS implementation of the Fitly MVP.
1. Product Goal
Enable users to form consistent daily exercise habits by providing a simple, low-friction iOS application that allows users to create short daily challenges (“bets”), mark daily completion, and monitor progress and streaks.
The MVP focuses on habit formation through:
Clear daily goals
Immediate visual feedback
Reliable local data persistence
2. Problem Statement
Many users fail to maintain fitness routines due to:
Lack of a simple daily structure
Overly complex fitness applications that create cognitive overload
Insufficient immediate feedback for small, repeatable actions
Fitly addresses this problem by offering a minimal, focused system for defining very specific daily exercise goals and tracking consistency through streaks and progress indicators.
3. Target Audience
Primary:
Individuals new to fitness who need a simple and structured approach to daily exercise
Users seeking a lightweight tool for short, repeatable daily fitness tasks
Secondary:
Users who prefer privacy and local-only data storage
Users motivated by visual progress tracking and streak mechanics
4. User Roles
End User
A person using the iOS application to create bets, mark daily completions, and view progress history
Maintainer / Developer
Responsible for maintaining the codebase, distributing updates, and managing the repository
Not a runtime role within the application
Note: The MVP does not include authentication. All users are local device users without accounts.
5. Core User Scenarios
Each scenario is written in Given / When / Then format to ensure testability.
5.1 First-time setup and create bet
Given a fresh app installation
When the user opens the app and creates a bet by entering a name, daily repetitions, and duration
Then the bet appears in the active bets list and is persisted locally
5.2 Mark daily completion
Given an active bet for the current day
When the user marks the bet as completed
Then the app records the completion, updates progress indicators, and increments the streak if applicable
5.3 Miss a day and break streak
Given an active bet with an existing streak
When the user does not mark completion before the end of the day
Then the streak resets according to defined rules and the missed day is recorded
5.4 View progress and history
Given one or more bets with recorded history
When the user opens bet details
Then the app displays per-day completion status, current streak, and overall completion percentage
5.5 App restart and persistence
Given existing bets and progress data
When the app is terminated and relaunched
Then all data is restored exactly as before
5.6 Edit or delete a bet
Given an existing bet
When the user edits or deletes the bet
Then the changes are reflected in the UI and persisted locally
6. Functional Requirements
The system must:
FR-01: Allow users to create, edit, and delete bets (name, daily target, duration)
FR-02: Allow users to mark daily completion for a bet and record the completion date
FR-03: Display current streak, daily completion history, and overall completion percentage
FR-04: Persist all user data locally and restore it after app restart
FR-05: Allow optional export of bet history in JSON or CSV format
FR-06: Support configurable start-of-day boundary (e.g., midnight or custom hour)
7. Non-Functional Requirements
NFR-01: The app must launch and display the home screen within 2 seconds on a mid-range iOS device
NFR-02: All data operations must be executed off the main UI thread
NFR-03: Application state must be deterministic to support reliable unit testing
NFR-04: The app must support iOS 16 and later
NFR-05: No silent data loss is allowed during app restarts or unexpected termination
8. Technical Stack & Architecture (iOS)
To ensure maintainability, testability, and clean separation of concerns, the following implementation constraints apply:
Language & UI
Swift
SwiftUI
Architecture
MVVM (Model–View–ViewModel)
ViewModels expose observable state to SwiftUI views using Combine or Swift Concurrency
Concurrency
Swift Concurrency (async/await) for background operations
All UI updates must occur on the main thread
Data Layer
Core Data or SQLite-based persistence for structured local storage
Repository pattern used as a single source of truth
Lightweight settings stored using UserDefaults
Dependency Management
Dependency injection implemented via initializer injection or lightweight DI mechanisms
All dependencies must be replaceable with mocks or fakes for testing
Testing
ViewModels and repositories must be unit-testable
Persistence layer should support in-memory testing configurations
Rationale: This stack follows modern iOS best practices and enables a clean, testable, and maintainable MVP implementation.
9. Acceptance Criteria
AC-CreateBet
Given valid bet data, when the user creates a bet, then it appears immediately in the UI and is persisted locally
AC-MarkCompletion
When a bet is marked as complete, then the updated state is published by the ViewModel within 500ms
AC-PersistenceOnRestart
After app termination and relaunch, all bets and history are restored without data loss
AC-Testability
ViewModels and repositories can be tested independently using mocked dependencies
AC-DataIntegrity
Concurrent updates to different bets do not cause crashes or corrupted data
10. MVP Scope (v0.2)
In Scope
Create, edit, delete bets
Mark daily completion
View progress and streaks
Local persistence
Unit tests for core logic
Out of Scope
User accounts and authentication
Cloud sync
Social features
Payments or subscriptions
11. Risks and Mitigations
Risk: Tight coupling between UI and persistence
Mitigation: Enforce MVVM and repository pattern
Risk: Data loss during model changes
Mitigation: Use migrations and test persistence changes
12. Implementation Notes
Recommended package structure:
Core/Data — persistence models, repositories
Core/Domain — domain models and use cases
Core/DI — dependency configuration
Features/* — SwiftUI views and ViewModels per feature
13. Acceptance and Sign-off
This PRD version 0.2 is approved for implementation of the Fitly iOS MVP as specified above.
