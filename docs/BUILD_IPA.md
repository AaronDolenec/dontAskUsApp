# Building an iOS .ipa (CI + Manual)

This project includes a GitHub Actions workflow and a Fastlane lane to build an iOS `.ipa` and commit it to the repository under `ios/ci-artifacts/`.

Important: macOS (Xcode) is required to build iOS apps. The workflow is configured to run on `macos-latest` and must be triggered manually via the GitHub UI (it's `workflow_dispatch`).

## Files added

## Required secrets / setup

To produce a signed `.ipa`, you must make signing credentials available on the macOS runner. Options:

  - Create a Match repository and set `MATCH_GIT_URL` and `MATCH_PASSWORD` as repository secrets.
  - The Fastlane lane will run `match` if `MATCH_GIT_URL` is present.


Alternatively, configure Xcode project signing to use an account present on the runner (less reproducible).

## How to run (manual)

1. Push these changes to GitHub.
2. Go to the repository Actions tab → `Build and commit iOS IPA` → `Run workflow`.
3. If signing is configured, the job will build the `.ipa` and commit it into `ios/ci-artifacts/`.

## Notes / Caveats

If you'd like, I can add automatic release creation or change the export method; tell me which you prefer.
