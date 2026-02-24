How to remove sensitive files before making the repo public
=========================================================

Follow these steps to ensure secrets are not published to GitHub.

1) Identify sensitive files (examples in this repo):
- `.env` (contains API endpoints and possibly secrets)
- `build/` (contains generated artifacts that may include embedded config)
- Any `*.jks`, `*.keystore`, `google-services.json`, `GoogleService-Info.plist`, or `*.p12` files

2) Stop tracking sensitive files and remove them from the next commit:

   # Remove local .env from the index but keep the file locally
   git rm --cached .env
   # Remove build/ from the index
   git rm -r --cached build/
   git commit -m "Remove sensitive and build artifacts from repository"

3) Clean secrets from git history (optional but recommended if secrets were already committed):

   # Install BFG (https://rtyley.github.io/bfg-repo-cleaner/) or use git-filter-repo.
   # Example with BFG to remove all .env files from history:
   bfg --delete-files .env
   git reflog expire --expire=now --all && git gc --prune=now --aggressive

   # Alternatively use git filter-repo (preferred modern approach):
   git filter-repo --invert-paths --paths .env --paths build/

4) Force-push cleaned history to the remote (ONLY if you're prepared to rewrite history):

   git push --force

5) Verify no secrets remain:
   - Search for common patterns: private keys, service account JSONs, long base64 blobs.
   - Use open-source scanners (truffleHog, git-secrets, detect-secrets) in CI.

If you want, I can add a GitHub Action that scans for secrets on push and blocks the merge if something suspicious appears.
