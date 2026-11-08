# DualView 2.2

Flutter Android source project for an offline document viewer with:
- Mobile mode: one document pane.
- PC split mode: two independent document panes.
- Local file picker.
- On-device PDF, DOCX, PPTX, XLSX and additional format rendering through `offline_document_viewer`.
- In-document search.

## Upload this project to GitHub

Upload the **contents** of this ZIP into the root of your repository. Keep the `lib/` and `.github/workflows/` folders intact. In particular, the Dart app file must be `lib/main.dart` (not `main.dart` at repository root).

## Build an APK using GitHub Actions

1. Commit the files to the repository's `main` branch.
2. Open the repository's Actions tab.
3. Select `Build DualView Android APK`.
4. Choose Run workflow if it has not started automatically.
5. When the run succeeds, open it and download the `DualView-Android-APK` artifact.
6. Extract the artifact ZIP and install `app-release.apk` on your Android phone.

The GitHub runner creates the Android wrapper, downloads Flutter dependencies, and builds the APK. The first build requires network access on GitHub's runner.

## Important

This is source code, not a prebuilt APK. It has not been compiled or tested on a physical phone in this environment. Office document rendering is supplied by the third-party package and has format-specific limitations; see its documentation and third-party notices before publishing commercially.
