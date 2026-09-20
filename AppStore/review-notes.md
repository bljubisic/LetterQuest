# App Review Notes

Paste into App Store Connect's "Notes" field under App Review Information.

```
LetterQuest has no login, no account system, and no server backend — there is nothing to configure or unlock for review. The app works fully offline.

HOW TO TEST
1. On first launch, the onboarding screens can be skipped via the "Skip" button, or walked through via the page dots.
2. On the Home screen, tap letter "A" (the only letter unlocked at first) to open the "Watch me draw" demonstration, then tap "Let's practice!".
3. Draw the letter inside the guide lines using a finger or Apple Pencil, then tap "Check!" to see the scoring feedback (stroke order, shape, proportion, smoothness).
4. A passing score (the required score depends on the difficulty level set in Settings — Easy/Standard/Challenge) unlocks the next letter and shows a celebration screen.
5. The chart icon in the top-right opens the Progress screen (achievement badges, per-letter history). The gear icon opens Settings (sound/haptics toggles, difficulty, and a "Reset All Progress" option for re-testing from a clean state).
6. Word practice mode (a book icon appears in the toolbar) unlocks only after all 26 uppercase and all 26 lowercase letters are completed — this is a long path to reach manually; let us know if you'd like a way to fast-track this for review and we can provide one.
7. The cart icon in the top-right opens the Alphabet Store, listing owned and purchasable alphabet packs. The Serbian Cyrillic pack (product id com.persukibo.letterquest.alphabet.cyrillic_sr) is a one-time non-consumable purchase — use a Sandbox Apple ID to buy it, then confirm it appears as owned and can be selected as the active alphabet from the globe icon's "Switch Alphabet" screen. "Restore Purchases" in the Alphabet Store re-syncs entitlements, useful for testing on a fresh install signed into the same Sandbox Apple ID.

DATA & PRIVACY
All progress is stored locally on-device via UserDefaults; nothing is transmitted anywhere. There is no camera, microphone, location, or contacts access requested anywhere in the app. In-app purchases are processed entirely by Apple via StoreKit 2 — LetterQuest never sees or stores payment information.

ACCESSIBILITY
The app supports VoiceOver (every interactive element has a label/hint, and the drawing canvas announces "Drawing canvas, double-tap to begin drawing") and Dynamic Type.
```
