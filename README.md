<p align="center">
  <img src="assets/images/logo_icon_transparent.png" width="128" height="128" alt="LetNote Logo">
</p>

<h1 align="center">LetNote</h1>

<p align="center">
  <strong>Universal Offline-First Notes & Knowledge Workspace</strong><br>
  Built with Flutter, Riverpod, and SQLite. Local-first privacy, AES-256 encryption, and instant full-text search.
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#platform-packages">Downloads</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#ci-cd-github-actions">CI/CD</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#github-secrets">Secrets Setup</a>
</p>

---

## Key Features

- **True Offline-First**: All data, full-text search indexes, version snapshots, and attachments live strictly on your device.
- **10 Structured Note Types**: Standard, Checklist, To-Do, Meeting, Quick Note, Idea, Journal, Study, Project, and Code.
- **Hierarchical Knowledge Base**: Nested Book Groups & Books (Folders up to 10 levels deep) with color-coded tags.
- **Interactive Markdown & Checklists**: Rich formatting toolbar, live preview mode, and real-time word/character/reading-time statistics.
- **High-Speed Search (FTS5)**: Sub-150ms full-text search across 10,000+ notes using SQLite `FTS5` virtual table with `unicode61` tokenizer.
- **Version History & Rollback**: Automated snapshots every 10 minutes with point-in-time restoration.
- **Security & Privacy**: AES-256-CBC/GCM encryption, PBKDF2/Argon2 salt key derivation, App PIN with biometrics, and per-note encryption.
- **Encrypted Portability**: Full database export to encrypted `.letnote` bundles, plus Markdown, Text, and JSON exports.
- **Data Management**: Dedicated Danger Zone with double-confirmation ("DELETE" keyword + PIN challenge) atomic data wiping.

---

## Platform Installation Packages

LetNote provides native packages for all major operating systems built automatically via GitHub Actions:

| Platform | Package Format | Installation Experience |
| :--- | :--- | :--- |
| **Windows** | `.exe` Installer | Full wizard (*Next → Next → Install*) with Start Menu & Desktop shortcuts, plus uninstaller. |
| **Windows** | `.zip` Portable | Standalone zero-install archive. |
| **macOS** | `.dmg` Image | Standard disk image with drag-and-drop to `/Applications`. |
| **iOS** | `.ipa` Bundle | Distribution / Sideloading package (unsigned). |
| **Android** | `.apk` Package | Direct sideload package for Android devices. |
| **Android** | `.aab` Bundle | Optimized Google Play Store distribution bundle. |
| **Linux** | `.deb` Package | Native Debian/Ubuntu installer (`sudo dpkg -i LetNote-Linux-amd64.deb`). |
| **Linux** | `.tar.gz` Archive | Portable standalone binary bundle. |

---

## CI/CD: Automated GitHub Actions

The repository includes an enterprise-grade GitHub Actions workflow (`.github/workflows/build_and_release.yml`):
- **Trigger**: Runs automatically **only when code is pushed to the `main` branch** (or via manual `workflow_dispatch`).
- **Parallel Matrix Execution**: Compiles natively across `windows-latest`, `macos-latest`, and `ubuntu-latest`.
- **Automated Packaging**:
  - Compiles Inno Setup `.iss` on Windows into a single-file installer wizard.
  - Generates `.dmg` on macOS with Applications symlink.
  - Builds `.ipa` payload on macOS.
  - Generates `.apk` and `.aab` on Ubuntu.
  - Builds `.deb` and `.tar.gz` on Ubuntu with desktop integration.
- **GitHub Releases**: Automatically publishes all 7 platform artifacts to GitHub Releases under version tags.

---

## GitHub Secrets Configuration (Optional Signing)

If you wish to sign Android release packages with your production keystore, configure the following repository secrets under **Settings → Secrets and variables → Actions**:

| Secret Name | Description | Example |
| :--- | :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore file | `base64 -w 0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | `your-keystore-password` |
| `ANDROID_KEY_ALIAS` | Key alias in the keystore | `upload` |
| `ANDROID_KEY_PASSWORD` | Key password | `your-key-password` |

> If secrets are omitted, the workflow builds a standard release package and completes successfully.

---

## Local Development & Build

### Prerequisites
- Flutter SDK (≥ 3.22.0)
- Dart SDK (≥ 3.12.0)

### Run Locally
```bash
# Clone the repository
git clone https://github.com/Saurabh-Bhatia-Official/let_note.git
cd let_note

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run app
flutter run
```

### Build Installers Locally

#### Windows (.exe Installer)
```powershell
flutter build windows --release
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" packaging\windows\inno_setup.iss
```

#### Android (.apk & .aab)
```bash
flutter build apk --release
flutter build appbundle --release
```

#### macOS (.dmg)
```bash
flutter build macos --release
./packaging/macos/build_dmg.sh
```

#### Linux (.deb)
```bash
flutter build linux --release
./packaging/linux/build_deb.sh
```

---

## Documentation

For full technical specifications and PRD mapping, see [`features.md`](features.md).
