All stories follow the standard format:

> As a [role], I want to [action], so I can [result].

Each story includes clear, testable acceptance criteria focused on **design, usability, and visual consistency**.

---

## 1. Create a Challenge (Bet)

**Story**
As a user, I want to create a new workout challenge, so I can start a clear and structured daily habit.

**Acceptance Criteria**

* Creation screen uses a clean, minimal layout with clear input fields.
* User can select exercise type (e.g., push-ups, squats).
* User can set repetitions per day and challenge duration.
* Primary action button is visually emphasized and disabled until inputs are valid.
* After creation, the challenge appears in the Home screen list with an “In Progress” status.

---

## 2. View Active Challenges

**Story**
As a user, I want to view my active challenges, so I can quickly understand my current progress.

**Acceptance Criteria**

* Active challenges are displayed as cards on the Home screen.
* Each card shows:

  * Challenge title
  * Daily progress indicator
  * Current day and total days
  * Visual progress bar
* Card layout is consistent and readable across different screen sizes.
* Tapping a card opens the challenge details screen with a smooth transition.

---

## 3. Track Today’s Progress

**Story**
As a user, I want to log my completed repetitions for today, so I can visually track my daily progress.

**Acceptance Criteria**

* Progress input uses clear, touch-friendly controls.
* Today’s progress updates immediately after user interaction.
* Progress indicator animates smoothly when values change.
* Daily progress cannot exceed the defined daily target.
* When the target is reached, the day is visually marked as completed.

---

## 4. Daily Deadline Indicator

**Story**
As a user, I want to see how much time remains in the current day, so I can complete the challenge on time.

**Acceptance Criteria**

* Remaining time is displayed as a countdown to the daily deadline.
* Countdown updates smoothly without distracting animations.
* Visual state changes when the deadline passes.
* If the day is not completed before the deadline, the UI reflects a failed day state.

---

## 5. Weekly Progress Visualization

**Story**
As a user, I want to see a weekly progress chart, so I can easily understand my performance over time.

**Acceptance Criteria**

* Weekly chart displays recent days in chronological order.
* Completed and missed days are visually distinct.
* Chart uses consistent colors and spacing aligned with the app design system.
* Chart remains readable on smaller screens.

---

## 6. Streak Visualization

**Story**
As a user, I want to see my current streak, so I feel motivated to stay consistent.

**Acceptance Criteria**

* Current streak is prominently displayed on the Home screen.
* Streak value updates immediately after completing a day.
* Visual emphasis (color or icon) highlights active streaks.
* Streak resets visually when a day is missed.

---

## 7. Challenge History

**Story**
As a user, I want to view my completed and failed challenges, so I can review my past activity.

**Acceptance Criteria**

* Finished challenges appear in a dedicated History screen.
* Each item displays:

  * Challenge title
  * Duration
  * Daily target
  * Final status (Completed or Failed)
* Status is visually encoded using color or iconography.
* History persists after app restarts.

---

## 8. Undo Challenge Deletion

**Story**
As a user, I want to undo accidental challenge deletion, so I do not lose progress unintentionally.

**Acceptance Criteria**

* Swipe gesture deletes a challenge from the active list.
* A temporary notification appears with an Undo action.
* Tapping Undo restores the challenge to its previous position.
* If Undo is not used, the challenge remains marked as failed in History.

---

## 9. Profile Avatar Customization

**Story**
As a user, I want to set a profile avatar, so I can personalize the app experience.

**Acceptance Criteria**

* User can select an image from device storage.
* Avatar is displayed in the Home screen header.
* Avatar is cropped and scaled consistently.
* Selected avatar persists after app restart.

---

## 10. Challenge Header Design

**Story**
As a user, I want a visually rich challenge header, so navigating the challenge feels intuitive and engaging.

**Acceptance Criteria**

* Header includes a background image spanning full width.
* Gradient overlay improves text readability.
* Header displays challenge title and current day information clearly.
* Layout adapts correctly to different device sizes.

---

## 11. Challenge Calendar View

**Story**
As a user, I want to see a calendar-style overview of my challenge days, so I can easily track completed and missed days.

**Acceptance Criteria**

* Calendar displays all days of the challenge.
* Completed days are marked with a clear visual indicator.
* Current day is highlighted.
* Future days appear in a neutral state.

---

## 12. Clear History

**Story**
As a user, I want to clear my challenge history, so I can remove outdated or irrelevant data.

**Acceptance Criteria**

* Clear History action is visually separated from primary actions.
* Confirmation dialog is displayed before deletion.
* History is cleared only after confirmation.
* Action is irreversible and clearly communicated to the user.

---

## End of Document

---
