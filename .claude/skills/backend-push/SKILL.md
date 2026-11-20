---
name: backend-push
description: Ship BACKEND/lesgo-api changes to the deployed repo carlkelvin8/Lesgo-API (branch feature/auth, auto-deploys on Laravel Cloud) without overwriting its diverged history. Use after backend changes are done and tested in the monorepo.
---

# Push backend changes to Lesgo-API

Production deploy. Only push when the user has said so in this turn.

1. In the monorepo: `cd BACKEND/lesgo-api && php artisan test` is green. Commit there.
2. Build a patch of only your changes: `git diff <base>..HEAD -- BACKEND/lesgo-api > $SCRATCH/x.patch`
   (use `git add -N` first for new files if uncommitted).
3. Fresh clone in the scratchpad: `gh repo clone carlkelvin8/Lesgo-API api -- --branch feature/auth`.
   Apply with `git apply -p3 $SCRATCH/x.patch`. If a file already contains part of your change (pushed earlier), exclude it
   with `--exclude` and copy the file by hand instead of forcing the patch.
4. Test in the clone: COPY the monorepo `vendor` (`cp -R`, ~180 MB), then `composer dump-autoload`, copy `.env`, run
   `php artisan test`. Do NOT symlink `vendor`: Composer's autoloader resolves `App\` and `Database\` from the vendor's
   real path, so a symlink silently runs the monorepo's code instead of the clone's (that produced a fake "~15 failing").
   The suite is fully green at baseline (533 passed on 2026-11-15); any failure after your change is yours.
   Delete the `vendor` copy and `.env` afterwards.
5. Commit with the Co-Authored-By line, then `git push origin feature/auth`. No new branch.
6. After the push: Laravel Cloud auto-deploys and runs `migrate --force`. Mention any new env vars or manual admin steps.
