# App Review response — LeSgo Affiliates 1.1.7 (20)

Reply to Guideline 2.1 "Information Needed". Paste the section below into the
App Store Connect reply AND into App Review Information → Notes.
Replace every `[[...]]` placeholder first.

---

Hello App Review Team,

Thank you for reviewing LeSgo Affiliates. Below is the requested information.

**1. Screen recording**

Recorded on a physical [[iPhone model]] running iOS [[latest version]]: [[link to recording, or attached]]

The recording shows, in this order:
- Launching the app and the start screen
- Rider registration (phone number + OTP, personal info, documents, terms)
- Rider login, going online, receiving and accepting a delivery, navigation, status updates, completing the delivery, earnings/wallet
- Rider chat with a customer about an active order, including the content-safety tools: long-press a customer message → **Report message**; chat menu (⋮) → **Report customer** / **Block customer**; the blocked state; and **Unblock**
- Merchant login, receiving an order, accepting/preparing it, managing menu items, sales report
- Paid features: registration fee / package tier payment through PayMongo (GCash/Maya/card)
- Account deletion for a rider (Profile → Settings → Delete account) and for a merchant (Profile → Settings & Support → Delete account)

**2. Purpose and target audience**

LeSgo Affiliates is the partner app for LeSgo, an on-demand delivery and booking platform in the Philippines. LeSgo customers use a separate app (LeSgo) to order food, goods and rides. LeSgo Affiliates serves the two kinds of partners who fulfil those orders:

- **Riders** (independent delivery drivers) register, verify their identity and vehicle, go online, accept delivery and booking jobs, navigate to pickup and drop-off, chat with the customer about the active order, and track earnings and payouts.
- **Merchants** (restaurants and stores) receive and manage incoming orders, maintain their menu and prices, print receipts, manage staff accounts, and view sales and withdrawals.

The app is open to the public: anyone in our service area can apply to become a rider or merchant, so it is not limited to a single company's employees. It gives small local merchants and independent riders a way to earn through a local delivery platform.

**3. Setup and demo accounts**

Demo accounts are pre-approved, so no admin approval or registration fee is needed and the OTP step is skipped:

| Account type | Login | Password / OTP |
|---|---|---|
| Rider | [[phone or email]] | [[password]] [[fixed OTP if needed, e.g. 123456]] |
| Merchant (store owner) | [[email]] | [[password]] |

How to test the main features:
1. Open the app, tap **[[Login button label]]** and sign in with the rider account.
2. Allow location access and go **Online** from the home screen.
3. To get a delivery request, place an order in the LeSgo customer app ([[App Store link or test customer account]]), or [[describe how you will keep test orders flowing during review, e.g. "we will send test orders to the demo rider during your review window"]].
4. Accept the job, follow the map to the pickup and drop-off points, update the status and complete the delivery. Earnings appear under **Earnings / Wallet**.
5. Sign out and sign in with the merchant account to see incoming orders, the **Menu** editor and **Sales Report**.
6. Account deletion: Rider → Profile → Settings → **Delete account**. Merchant → Profile → Settings & Support → **Delete account**. Type DELETE to confirm. The account is deleted permanently.

A new rider or merchant registers inside the app. After registering they pay a one-time platform registration fee, and an admin reviews their documents before activating the account.

**User-generated content safeguards (Guideline 1.2)**

The only user-generated content is the in-app chat between a rider and the customer of an active order. It includes:
- **Filtering:** common profanity and slurs in English and Filipino are masked automatically before a message is saved or delivered.
- **Reporting:** long-press any message, or use the chat menu, to report it with a reason. Each report creates a high-priority ticket for our moderation team, and we act on reports within 24 hours by removing content and suspending or deactivating offending accounts.
- **Blocking:** the chat menu lets a user block the other person. Once blocked, neither side can send messages. Blocks can be undone.
- **Terms:** riders agree to a zero-tolerance policy for objectionable content and abusive users when they register (Terms → "In-App Communications").
- **Contact:** [[support email]] and the in-app Admin support chat.

**4. External services**

- Laravel Cloud: hosts our backend API and database
- Laravel Reverb (Pusher protocol): real-time order and chat updates
- Firebase Cloud Messaging: push notifications for new orders
- Firebase Crashlytics: crash reporting
- Google Maps Platform (Maps SDK, Geocoding) for maps and routing, with an optional hand-off to Google Maps or Waze for turn-by-turn navigation
- PayMongo (GCash, Maya, cards) and [[Xendit, if used in production]]: payment processing for registration fees, package tiers and wallet top-ups. These pay for real-world delivery services and platform access, not for digital content.
- Google Gemini API: drafts replies in the in-app support chat; a human admin can take over the conversation
- SMS OTP provider for phone verification: [[provider name]]
- Bluetooth thermal printers (merchant receipts, optional)

**5. Regional differences**

LeSgo currently operates only in the Philippines ([[cities/areas served]]). The app works the same way everywhere, but deliveries and payments only work inside our service area. The app is available in English and Filipino.

**6. Regulated industry / documentation**

LeSgo is operated by [[registered company name]], registered with [[DTI/SEC registration no.]]. [[Attach the business registration certificate and any LGU/mayor's permit. If you also run ride-hailing / passenger transport, attach the LTFRB accreditation or state that only goods delivery is offered.]] Payments are processed by PayMongo, a BSP-regulated payment provider; LeSgo does not store card data.

Thank you,
[[Name]], LeSgo

---

## Before you reply (internal checklist, don't paste)

- [ ] **Deploy the backend first**, then run `php artisan migrate --force` (creates `chat_reports` and `user_blocks`).
      The deploy includes the chat report/block endpoints and the merchant-deletion code in `AccountDeletionService`.
- [ ] Build and upload **1.1.7 (20)**. It includes merchant Delete account, chat Report/Block, the profanity filter, and the zero-tolerance clause in the rider terms.
- [ ] Have someone monitor the support-ticket queue during review. Chat reports appear as high-priority
      tickets with the subject "Chat report: …". Apple may file a test report.
- [ ] Customer app (FRONTEND) still lacks report/block UI. It isn't required for this rider submission, but the
      customer app's own review will need it.
- [ ] Demo rider + merchant accounts: approved, fee waived, OTP bypass, can delete and recreate them
      (deleting during review destroys them, so have spares).
- [ ] A way for the reviewer to actually receive an order.
- [ ] Screenshots in App Store Connect show the real app in use, not the login or splash screen (2.3.3).
- [ ] Record on a physical iPhone on the latest iOS, starting from the home-screen tap.
