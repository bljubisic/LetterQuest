# In-App Purchases — App Store Connect Setup

Step-by-step process for creating a live, purchasable alphabet-pack product
in App Store Connect. Written against the one pack that exists today
(Serbian Cyrillic) but intended to be reused verbatim for every future pack —
follow the same steps, swapping only the alphabet-specific values in the
table below.

This mirrors `LetterQuest/Resources/StoreKitConfiguration.storekit`, which is
the **sandbox** definition of the same product used for local development
and Xcode Preview/simulator testing. The steps below create the matching
**production** product; StoreKit automatically prefers the sandbox config
during local runs and falls back to the real App Store Connect product in
TestFlight/production builds, so both must stay in sync.

## Prerequisites

- An active Apple Developer Program membership with admin or App Manager
  access to the `com.persukibo.letterquest` app record in App Store Connect.
- The app record itself must already exist in App Store Connect (created
  once, the first time the app is submitted).

## Values for the Serbian Cyrillic pack

| Field | Value |
|---|---|
| Type | Non-Consumable |
| Product ID | `com.persukibo.letterquest.alphabet.cyrillic_sr` |
| Reference Name (internal only) | Serbian Cyrillic Alphabet |
| Price tier | Tier 1 ($0.99 USD, localized equivalents elsewhere) |
| Display Name (en_US) | Serbian Cyrillic Alphabet |
| Description (en_US) | Unlock the Serbian Cyrillic alphabet pack for practice (54 chars, App Store Connect's IAP description limit is 55) |
| Family Sharing | Enabled |

## Steps

1. In App Store Connect, open **Apps → LetterQuest → Features/Monetization → In-App Purchases**.
2. Click **+** (Create) and choose **Non-Consumable**.
3. Enter the **Reference Name** and **Product ID** from the table above.
   The Product ID must exactly match the `productId` wired into
   `Alphabet.swift` for that alphabet (see `Alphabet.cyrillicSrProductId`
   for the existing pack) — a mismatch means `StoreKitPurchaseService`
   won't find the product and the Alphabet Store will show it as
   unavailable.
4. Under **Pricing**, select the price tier from the table above.
5. Under **App Store Localization**, add the en_US **Display Name** and
   **Description** from the table above (add further locales later if the
   app is localized).
6. Under **Review Information**, upload a screenshot showing the purchase in
   context — a screenshot of the Alphabet Store screen with this pack's
   card visible is sufficient. This is required before the product can be
   submitted for review.
7. Save the product. Its initial status is **Ready to Submit** — non-consumable
   IAPs are reviewed together with the next app version submission (or via
   **Submit for Review** individually, e.g. to add a pack to an app that's
   already live).
8. Once Apple approves it, the product's status becomes **Approved** — it's
   then live and purchasable for anyone running a build whose bundle ID and
   version were included in that submission.

## Adding a future alphabet pack

Repeat the steps above with the new alphabet's own values, following the
same `com.persukibo.letterquest.alphabet.<alphabet-id>` Product ID pattern
(match whatever `<alphabet-id>` the new `Alphabet` model uses — e.g. the
Cyrillic pack uses `cyrillic-sr` → `cyrillic_sr` for the product ID, since
Apple's product IDs only allow letters, digits, underscores, and periods).
Also add the equivalent product entry to
`LetterQuest/Resources/StoreKitConfiguration.storekit` (same Product ID,
type, and localization) so local development and simulator testing exercise
the same product before it's live.

## Verifying before submission

- The `AlphabetStoreViewModel` fetches products by ID via
  `PurchaseServiceProtocol.fetchProducts(ids:)`; if a Product ID here
  doesn't match the one baked into `Alphabet.swift`, that alphabet silently
  won't show a price/purchase button in the Alphabet Store — check the Store
  screen against a TestFlight build (not just the simulator, which always
  uses the local `.storekit` sandbox file) before submitting.
- Use a **Sandbox Apple ID** (App Store Connect → Users and Access →
  Sandbox Testers) to test the real product end to end in TestFlight, since
  the local `.storekit` file only exercises Xcode's simulated StoreKit
  environment, not the live App Store Connect product.
