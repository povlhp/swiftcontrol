# Fork Merge Strategy

## Overview

This document explains how to merge updates from the upstream BikeControl project into this fork while maintaining the NO_COMMERCIAL build configuration. It covers branch strategy, the merge process, conflict resolution, and keeping the fork functional as a standalone build without commercial dependencies.

This fork strips out all commercial services (Supabase, RevenueCat, IAP, sign-in providers, Shorebird) and provides stubs where needed so the app compiles and runs with the `--dart-define=NO_COMMERCIAL=true` flag.

## Branch Strategy

### Main Branch (`main`)

- Tracks the upstream BikeControl repository at `https://github.com/OpenBikeControl/bikecontrol`
- Contains all commercial code (Supabase, RevenueCat, IAP, etc.)
- Use this branch to pull latest upstream changes

### Stripped Branch (`stripped`)

- Contains the NO_COMMERCIAL modifications
- All CI workflows trigger on this branch
- This is the branch you build and distribute from

### Workflow

```
upstream/main --> your-fork/main (merge upstream)
your-fork/main --> your-fork/stripped (merge and resolve conflicts)
```

The `main` branch stays close to upstream. The `stripped` branch carries the permanent fork modifications. Each time you pull from upstream, you merge into `main` first, then merge `main` into `stripped` and resolve any conflicts.

## Getting Updates from Upstream

### Step 1: Add upstream remote (one-time setup)

```bash
git remote add upstream https://github.com/OpenBikeControl/bikecontrol.git
git fetch upstream
```

If you already have the remote, just fetch:

```bash
git fetch upstream
```

### Step 2: Merge upstream into your main branch

```bash
git checkout main
git merge upstream/main
git push origin main
```

### Step 3: Merge main into stripped

```bash
git checkout stripped
git merge main
```

### Step 4: Resolve conflicts

See the "Conflict Resolution" section below for the expected conflict areas and how to handle each one.

### Step 5: Push stripped

```bash
git push origin stripped
```

This triggers all CI workflows automatically.

## Conflict Resolution

### Expected Conflicts

When merging upstream changes, you should expect conflicts in these specific areas. Each has a predictable resolution pattern.

#### 1. `pubspec.yaml`

**What changes upstream**: New dependencies, version bumps

**How to resolve**:
- Keep your NO_COMMERCIAL modifications (removed packages). Your version has these packages removed; upstream has them listed. Accept your deletion.
- Accept version bumps for non-commercial packages. If upstream bumps `flutter` SDK constraint or a package like `path_provider`, take the upstream version.
- If upstream adds a NEW commercial package, add it to the "removed" list in this document, delete it from `pubspec.yaml`, and follow the "Adding New Commercial Packages to Blocklist" section.

#### 2. `lib/utils/iap/iap_manager.dart`

**What changes upstream**: New IAP features, bug fixes

**How to resolve**:
- Your version has `NoopIAPManager` and a conditional `instance` getter that returns the no-op implementation when `NO_COMMERCIAL` is true.
- Upstream changes to the base `IAPManager` class: accept them only if they don't break non-commercial mode (pure refactoring, new abstract methods). If upstream adds new abstract methods, add matching no-op implementations to `NoopIAPManager`.
- If upstream significantly restructures the file, you may need to rewrite the `NoopIAPManager` stub against the new structure.

#### 3. `lib/utils/core.dart`

**What changes upstream**: New features, refactoring

**How to resolve**:
- Your version has `isCommercial`/`isNonCommercial` boolean getters and a nullable `supabase` client.
- Upstream has `isCommercial` as `true` always and a non-nullable `supabase`.
- Keep your modifications. Accept upstream changes to other parts of the file (new utility functions, constants, etc.).
- If upstream adds a new function that calls a commercial service, you may need to add a null guard or a no-op stub.

#### 4. `lib/utils/settings/settings.dart`

**What changes upstream**: New settings options, initialization changes

**How to resolve**:
- Your version skips `Supabase.init()` in non-commercial mode with a `if (isCommercial)` guard.
- Keep your guard. Accept upstream changes to other initialization code and settings fields.
- If upstream adds new settings that depend on Supabase or other commercial services, wrap them in the same `if (isCommercial)` guard.

#### 5. `lib/pages/subscriptions/login.dart`

**What changes upstream**: New sign-in providers, UI changes

**How to resolve**:
- Your version has a static "All features unlocked" stub page that replaces the full login flow.
- Keep your stub. If upstream redesigns the page structure (new widget classes, different routing), recreate the stub with the same visual output using the new structure.

#### 6. `lib/pages/subscription.dart`

**What changes upstream**: New subscription features, pricing changes

**How to resolve**:
- Your version has a "Pro is permanently unlocked" stub that replaces the full subscription/pricing UI.
- Keep your stub. Same approach as `login.dart`: if the page is restructured, rewrite the stub.

#### 7. Deleted files

**What changes upstream**: Files you deleted may be modified upstream

**How to resolve**:
- If upstream modifies a file you already deleted (e.g., `revenuecat_service.dart`, `supabase_auth.dart`), the conflict auto-resolves -- the file doesn't exist in your branch, so git keeps it deleted. No action needed.
- If upstream adds a NEW file that imports a commercial package you deleted, you need to either:
  - Delete the new file (run `git rm <file>`)
  - Or add null-handling guards if the file has non-commercial value
- After resolving, run the commercial import grep check (see "Testing After Merge").

#### 8. `ios/Runner.xcodeproj/project.pbxproj`

**What changes upstream**: New build targets, build settings changes

**How to resolve**:
- Your version removed the TrainerActivity extension (requires paid developer account).
- Accept upstream changes to other build targets and settings.
- If upstream adds a new extension target, decide whether it needs a paid developer account. If yes, remove it.
- This file is painful to merge manually. Use a merge tool if needed: `git mergetool`.

#### 9. `android/app/build.gradle.kts`

**What changes upstream**: SDK versions, dependency versions

**How to resolve**:
- Your version has a conditional signing block wrapped in `if (System.getenv("NO_COMMERCIAL") != "true")`.
- Keep your conditional. Accept upstream SDK version bumps and non-commercial dependency updates.
- If upstream adds a new commercial dependency to this file, add it to the blocklist and remove it.

### Conflict Resolution Commands

```bash
# See all conflicted files
git status

# For each conflicted file, edit to resolve, then:
git add <resolved-file>
git commit -m "Merge upstream/main into stripped, resolve conflicts"
```

For complex binary files like `project.pbxproj`, a dedicated merge tool is recommended:

```bash
git mergetool
```

## Keeping Fork Functional

### After Every Merge

Run these checks in order after a successful merge:

```bash
# 1. Clean and get dependencies
flutter clean && flutter pub get

# 2. Run static analysis (warnings are acceptable, errors are not)
flutter analyze --no-fatal-infos --no-fatal-warnings

# 3. Build debug APK (quickest compilation target)
flutter build apk --debug --dart-define=NO_COMMERCIAL=true

# 4. Test on other platforms if available
flutter build windows --debug --dart-define=NO_COMMERCIAL=true   # Windows
flutter build ios --debug --no-codesign --dart-define=NO_COMMERCIAL=true   # iOS (macOS only)
```

### Adding New Commercial Packages to Blocklist

If upstream adds a new commercial package, follow these steps:

1. Add to the "Removed Packages Reference" table in this document.
2. Remove the package from `pubspec.yaml`.
3. Find all import sites: `grep -r "package:new_package" lib/ --include="*.dart"`
4. For each file that imports the removed package:
   - **Pure commercial file** (all code depends on the commercial service): delete the file with `git rm <file>`.
   - **Mixed file** (combines commercial and non-commercial code): remove the import and surrounding commercial code, add null-handling guards.
   - **UI that needs a placeholder**: replace the widget with a stub (simple Text or placeholder widget).
5. Clean and build: `flutter clean && flutter pub get && flutter build apk --debug --dart-define=NO_COMMERCIAL=true`

### Testing After Merge

```bash
# Verify no commercial imports remain in lib/
grep -r "supabase\|purchases_flutter\|google_sign_in\|sign_in_with_apple\|shorebird\|in_app_purchase\|in_app_review\|in_app_update\|restart_app" lib/ --include="*.dart"

# The command should return zero matches across all files.
# If any match appears, investigate and address it.
```

## CI/CD

### Workflows

The following GitHub Actions workflows are configured (all in `.github/workflows/`):

| Workflow | Trigger | Runner | Artifact |
|----------|---------|--------|----------|
| `build-android.yml` | Push to `main`/`stripped`, workflow_dispatch | ubuntu-latest | `android-debug-apk` → `app-debug.apk` |
| `build-windows.yml` | Push to `main`/`stripped`, workflow_dispatch | windows-latest | `windows-debug` → `build/windows/x64/runner/Debug/` |
| `build-ios-sideload.yml` | Push to `main`/`stripped`, workflow_dispatch | macos-14 | `ios-sideload-ipa` → `ios-sideload.ipa` |
| `analyze.yml` | Push, PR | ubuntu-latest | (none -- just reports) |

### Triggering Builds

- **Automatic**: Push to `main` or `stripped` branch.
- **Manual**: Use `workflow_dispatch` from the GitHub Actions tab in your repository.

### Artifacts

- **Android**: `android-debug-apk` → `app-debug.apk` (signed with debug keystore, installable on any device in developer mode)
- **Windows**: `windows-debug` → `build/windows/x64/runner/Debug/` (standalone executable)
- **iOS**: `ios-sideload-ipa` → `ios-sideload.ipa` (unsigned, needs re-signing before install)

## iOS Sideload Instructions

### Prerequisites

- A free Apple ID (no paid developer account needed)
- AltStore or Sideloadly installed on your computer or iOS device

### Steps

1. Download `ios-sideload.ipa` from the GitHub Actions artifact page.
2. Open AltStore or Sideloadly on your computer.
3. Connect your iOS device via USB.
4. Drag the `.ipa` file into AltStore (or select it in Sideloadly).
5. Sign in with your free Apple ID when prompted.
6. The app installs on your device.
7. Trust the developer certificate:
   - Go to Settings, General, VPN & Device Management.
   - Tap your Apple ID, then tap "Trust".

### Limitations

- Free Apple ID certificates expire after 7 days.
- You need to re-sign the app weekly. AltStore can auto-refresh on the same network.
- Maximum of 3 apps per device with a free Apple ID.

## Removed Packages Reference

| Package | Reason | Removal Strategy |
|---------|--------|------------------|
| `supabase_flutter` | Backend auth and sync | Delete all imports; nullable getter in `core.dart` |
| `purchases_flutter` | iOS and Android in-app purchases via RevenueCat | Delete; `NoopIAPManager` stub |
| `purchases_ui_flutter` | RevenueCat UI paywall screens | Delete entire package |
| `google_sign_in` | Google sign-in provider | Delete; stub login page |
| `sign_in_with_apple` | Apple sign-in provider | Delete; stub login page |
| `sign_in_button` | UI button widgets for sign-in | Delete |
| `shorebird_code_push` | Over-the-air updates via Shorebird | Delete; static "no updates" response |
| `windows_iap` | Windows Store in-app purchases | Delete entire directory |
| `in_app_purchase` | Platform in-app purchases (Apple/Google) | Delete |
| `in_app_review` | App Store rating prompt | Delete |
| `in_app_update` | Play Store in-app update prompt | Delete |
| `restart_app` | App restart utility (used by Shorebird) | Delete |

## Troubleshooting

### Build fails after merge

1. **Check `pubspec.yaml` first.** Look for new packages added upstream that may be commercial. Compare with the "Removed Packages Reference" table.
2. Run `flutter clean && flutter pub get` to ensure a clean dependency resolution.
3. Search for new import sites of commercial packages: `grep -r "package:xxx" lib/`.
4. Run `flutter analyze` for specific error messages. Each error points to a file and line that needs attention.

### New commercial dependency added upstream

1. Follow the "Adding New Commercial Packages to Blocklist" section above.
2. Check if the package has a non-commercial alternative (e.g., a community replacement or a built-in Flutter equivalent).
3. If no alternative exists, add to the blocklist and create the necessary stubs.

### iOS build fails

1. Verify the TrainerActivity extension is still excluded from the Xcode project. Check `ios/Runner.xcodeproj/project.pbxproj` for any `TrainerActivity` references.
2. Check `ios/Runner/Runner.entitlements` for new entitlements that require a paid developer account (e.g., `com.apple.developer.icloud-services`, push notifications).
3. Verify `ios/Runner/Info.plist` has no leftover Google or Apple sign-in configuration (`CFBundleURLTypes` with Google/Apple reverse-ClientID).
4. Check that `ios/Podfile` has no leftover commercial pod references.

### Android build fails

1. Verify `android/app/build.gradle.kts` still has the conditional signing block: `if (System.getenv("NO_COMMERCIAL") != "true")`.
2. Check for new Android permissions in `android/app/src/main/AndroidManifest.xml` that may require a paid developer account.
3. Run `flutter clean && flutter pub get` and retry.

### Git merge produces too many conflicts

If a merge produces conflicts far beyond the expected files listed above, one of these may have happened:

- The upstream made a large refactor that touched many files. In this case, consider doing the merge incrementally: merge a middle commit first, then the rest.
- Your `stripped` branch has diverged significantly. You can do `git merge --squash main` to collapse all upstream changes into a single commit and manually re-apply your modifications.

## Contact

- Upstream repository: https://github.com/OpenBikeControl/bikecontrol
- Upstream issues: https://github.com/OpenBikeControl/bikecontrol/issues
- This fork's issues: (file issues in your own fork's issue tracker)
