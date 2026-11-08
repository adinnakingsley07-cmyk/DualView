# DualView 2.0 — Offline Android document viewer

This is a Flutter-based replacement for the first native Android prototype. It provides:
- Mobile mode: one document pane.
- PC split mode: two independent panes side by side on the same Android phone.
- Local file selection through Android's document picker.
- On-device document rendering using `offline_document_viewer`.
- In-document search and previous/next page or slide controls.
- No cloud conversion service and no app-level Internet permission is declared.

## Supported formats and fidelity
The bundled renderer package documents:
- PDF: full PDF rendering.
- DOCX/DOCM: high-fidelity rendering.
- PPTX/PPTM: high-fidelity rendering.
- XLSX/XLSM: high-fidelity rendering.
- XLS: values without styling.
- CSV/TSV: full tabular rendering.
- RTF: text and formatting.
- Legacy DOC/PPT: text-only extraction.

Known renderer limitations include unsupported chart/conditional-formatting/pivot-table rendering in spreadsheets, some PowerPoint autofit/layout differences, and password-protected documents not opening. See package documentation and third-party notices before distribution.

## Build on a computer
1. Install Flutter stable and Android Studio with Android SDK.
2. Extract this project.
3. Open a terminal in this folder.
4. Run `flutter pub get`.
5. Run `flutter create --platforms=android .` to generate/refresh the Android platform wrapper for your installed Flutter version.
6. Connect your Android phone with USB debugging enabled.
7. Run `flutter run` or build an APK with `flutter build apk --release`.

The first dependency download/build requires internet on the development computer. After dependencies and engine assets are bundled into the app, document viewing itself works offline.

## Important
I cannot compile or test an APK in this environment because the Flutter/Android build toolchain and a connected Android device are not available here. This ZIP contains the application source and dependency configuration, not a prebuilt APK.

## Build using only your Android phone (cloud build)

You do **not** need to install Flutter on your phone. Use a cloud builder:
1. Create a GitHub account and a new repository named `DualView`.
2. Upload the contents of this project ZIP into the repository (not the ZIP itself), keeping the `.github/workflows/android-apk.yml` folder path.
3. In the repository, open **Actions** and allow GitHub Actions if prompted.
4. Run **Build DualView APK** using **Run workflow**, or push to `main`.
5. When the workflow finishes, open its run, scroll to **Artifacts**, and download `dualview-release-apk`.
6. Extract the downloaded artifact ZIP on your phone; install `app-release.apk`.

The build runs on GitHub's cloud machines. The phone is only used to upload source, start the build, and download the APK. GitHub account/repository and Actions usage limits apply. The APK is a test build; production distribution should use a private signing key and a deliberate package ID.

This workflow generates the missing Android platform wrapper, resolves packages, builds a release APK, and uploads it as an artifact. It does not prove the app has been tested on your particular phone.
