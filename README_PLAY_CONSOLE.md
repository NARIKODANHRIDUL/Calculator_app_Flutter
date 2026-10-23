# Google Play Console CLI Deployment Guide

This setup enables building and publishing your Android App Bundle (`.aab`) to the Google Play Console directly from the command line without manual uploads through the web interface.

---

## 1. Quick Start

### Windows (PowerShell)
```powershell
# Build and upload to Internal Testing
.\publish_play_console.ps1 -Track internal

# Upload to Production
.\publish_play_console.ps1 -Track production

# Upload with staged rollout (e.g. 20%)
.\publish_play_console.ps1 -Track production -Status inProgress -UserFraction 0.2

# Skip build and upload existing .aab
.\publish_play_console.ps1 -SkipBuild -Track internal
```

### macOS / Linux / Git Bash
```bash
chmod +x ./publish_play_console.sh

# Build and upload to Internal Testing
./publish_play_console.sh --track internal

# Upload to Alpha or Beta
./publish_play_console.sh --track beta
```

### Direct Dart Command
```bash
# Build the bundle first
flutter build appbundle --release

# Run the publisher tool
dart run tool/publish_to_play_console.dart --track=internal

# View all options
dart run tool/publish_to_play_console.dart --help
```

---

## 2. One-Time Setup: Google Play Developer API Key

To authenticate with Google Play Console from the command line, you need a Service Account JSON key:

1. **Open Google Play Console**:
   - Go to [Google Play Console](https://play.google.com/console).
   - In the left menu, navigate to **Setup** > **API access**.

2. **Link or Create Google Cloud Project**:
   - If not already linked, click **Choose a project to link** or **Create new Google Cloud project**.

3. **Create Service Account**:
   - Under **Service accounts**, click **Learn how to create service accounts** or go directly to the [Google Cloud Console - Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts).
   - Click **Create Service Account**:
     - Name: `play-console-publisher`
     - Role: **Service Account User**
   - Click **Done**.

4. **Create and Download JSON Key**:
   - In the Service Accounts list, click on your newly created service account.
   - Go to the **Keys** tab > **Add Key** > **Create new key**.
   - Choose **JSON** and click **Create**.
   - Save the downloaded file into your project as:
     ```
     android/play-service-account.json
     ```
     *(This file is automatically ignored by `.gitignore` to keep credentials secure).*

5. **Grant App Permissions in Play Console**:
   - Return to **Google Play Console** > **API access** (refresh if needed).
   - Find your service account under **Service accounts** and click **Grant access** (or **Manage permissions**).
   - In **App permissions**, select your app (`neriquest.calculator`).
   - In **Account permissions**, ensure the following are checked:
     - *Releases*: Edit and delete draft releases, Release to production, Release to testing tracks.
   - Click **Invite user** / **Save changes**.

---

## 3. Configuration Details

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `--track` | `internal`, `alpha`, `beta`, `production` | `internal` | Destination release track |
| `--status` | `completed`, `draft`, `inProgress`, `halted` | `completed` | Release rollout status |
| `--user-fraction` | `0.0` to `1.0` | `null` | Rollout percentage for staged releases (e.g. `0.2` = 20%) |
| `--release-notes` | Text | `null` | Release notes in English (en-US) |
| `--key-file` | File path | `android/play-service-account.json` | Path to service account JSON |
| `--bundle-path` | File path | `build/app/outputs/bundle/release/app-release.aab` | Path to `.aab` |

---

## 4. Keystore & Signing Configuration

Your release signing is already configured in [`android/app/build.gradle`](file:///d:/Flutter/Calculator_app_Flutter/android/app/build.gradle) using [`android/key.properties`](file:///d:/Flutter/Calculator_app_Flutter/android/key.properties):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

Both `key.properties` and `upload-keystore.jks` are protected in `.gitignore`.

---

## 5. Automated CI/CD (GitHub Actions)

An automated deployment pipeline is included at [`.github/workflows/deploy_play_console.yml`](file:///d:/Flutter/Calculator_app_Flutter/.github/workflows/deploy_play_console.yml).

To enable it:
1. In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions**.
2. Add the following repository secrets:
   - `PLAY_SERVICE_ACCOUNT_JSON`: Contents of `android/play-service-account.json`
   - `PLAY_KEYSTORE_BASE64`: Base64 encoded `upload-keystore.jks` (`[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))`)
   - `KEY_PROPERTIES`: Contents of `android/key.properties`
3. Trigger a deployment by pushing a git tag (e.g. `git tag v1.0.8 && git push origin v1.0.8`) or via GitHub Actions web UI (**Run workflow**).
