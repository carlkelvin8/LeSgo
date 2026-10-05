# Partner annual registration

Partners pay a fixed PHP 1,000 annual registration fee. Payment or an admin
waiver covers one year from its recorded timestamp (February 29 renews on
February 28 in a non-leap year). Application approval is still required.

On the partner details page, **Waive & Activate** records the administrator,
timestamp, and optional reason, approves the application, and activates the
partner. Repeating this action during the covered year does not extend coverage
or replace the original waiver audit.

At expiry, the completed payment/waiver is archived in the existing fee row's
`metadata.annual_history`. The current row becomes unpaid for PHP 1,000,
retains the application decision, and receives fresh gateway references.
The partner is restricted until renewal payment or a new admin waiver.
The fee details page displays the annual history.

## Release

Deploy the matching admin and API changes together. API implementation is in
the `codex/partner-annual-fee` branch based on current `origin/feature/auth`,
in the local `BACKEND/lesgo-api-partner-fee` worktree.
The old API working checkout is unchanged.

No new database migration is needed: the existing fee table and JSON metadata
store the current period and prior-year audit. Both applications must already
have their registration fee and waiver migrations applied.

Keep Laravel's scheduler running. The hourly
`registration-fees:renew-partners` command opens expired annual renewals.
The API also checks expiry during fee status/access/checkout requests; opening
partner or fee details in the admin checks it too.

Existing explicit grandfathered exemptions are preserved. Completed historical
payments are not repriced, and existing pending gateway checkouts retain their
original amount; newly created partner fees and annual renewals cost PHP 1,000.
Rider fees retain their existing one-time package behavior.

Checks use isolated SQLite test databases and mocked PayMongo responses.
Live payment and production deployment have not been performed.
