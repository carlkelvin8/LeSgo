# Merchant frontend and backend audit — September 15, 2026

## Scope and result

Reviewed the current RIDERSIDE merchant app and the API checkout at
BACKEND/lesgo-api-partner-fee, based on the pushed feature/auth commit f4b05de.
Existing unrelated edits in the main workspace were preserved.

The fixes below are local and have not been pushed or deployed.

## Confirmed bugs fixed

| Area | Before | Fix |
| --- | --- | --- |
| Staff privacy | Any authenticated customer could read staff names/emails for an active store because staff endpoints used the public partner-view policy. | Staff listing and details now require store-management authorization. |
| Inventory menu | App requested a GET menu-items route that did not exist, swallowed the error, and fell back to the customer menu. Sold-out items and hidden categories disappeared from management. | Added authorized full merchant-menu and menu-items endpoints. App uses the full merchant menu and surfaces errors. |
| Category deletion | Backend called nonexistent MenuCategory::menuItems(), causing a server error. | Uses items()->exists(); empty categories can be deleted and categories containing hidden items remain protected. |
| Store/menu cache | Store toggling and category deletion did not invalidate cached partner/menu data. | Added partner cache invalidation after both changes. |
| Staff loading/account changes | Failed update/delete or missing partner ID left loading enabled. Cached partner ID and provider state could survive account changes. | Error paths clear loading; requests resolve the current partner; provider resets when user changes; disposed requests do not update state. |
| Order history and sales totals | App fetched only the first 100 orders, then calculated reports from that incomplete list. | Follows all returned pages, supports both pagination shapes, deduplicates IDs, and surfaces later-page errors. |
| Menu lifecycle | Stock-update error handler used a list item's context after an asynchronous operation, guarded only by the parent state's mounted flag. | Checks the actual context's mounted flag. |

## Remaining product gap

**The current merchant app has a registration-fee notice but no registration-fee
checkout/verification screen.** Searching the app found no calls to
/v1/registration-fee/status, /checkout, or /verify. The backend supports these
endpoints and restricts operational features pending payment/waiver and approval.
Merchants therefore need the payment/status UI connected to those endpoints to
complete the payment flow in this app.

This audit did not perform a live PayMongo charge, use a production merchant
account, or inspect authenticated production logs. Passing local tests does not
confirm a deployed merchant payment flow.

## Validation

- Flutter: 38 tests passed across merchant_complete_test.dart and the new
  merchant_api_regression_test.dart.
- API: 46 tests passed across merchant regressions, annual fees, registration
  payments, orders, authorization, and wallets, using the local PostgreSQL
  lesgo_test database with mocked payment responses.
- Targeted Dart analysis of changed data source, staff provider, and regression
  tests: no issues.
- Initial wider merchant analysis: no compile errors; 55 informational findings,
  mainly style/deprecation notices. The reported async-context issue was fixed.
- Corrected two stale backend tests: assigned-order fixture now uses the driver
  profile ID; wallet first-access test expects the existing zero-balance
  auto-creation behavior.

## Release dependency

Deploy the backend's new merchant-menu endpoint before distributing the app
changes. The previous partner annual-fee commit is already pushed; these audit
fixes are a separate, unpushed change set. No database migration is needed for
these audit fixes.
