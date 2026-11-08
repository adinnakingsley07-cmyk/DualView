# DualView 2.1

Flutter Android document viewer with:
- Mobile mode: one document pane.
- PC split mode: two independent document panes.
- Local file picker.
- Offline document rendering through `offline_document_viewer`.
- Search in the open document.

## Formats
PDF, DOCX/DOCM, PPTX/PPTM, XLSX/XLSM, XLS, CSV/TSV, RTF, and text-only support for legacy DOC/PPT. Some complex Office features are not supported by the renderer. See the package documentation: https://pub.dev/packages/offline_document_viewer

## Build using GitHub Actions from a phone
1. Replace the matching files in your GitHub repository with these project files, keeping the folder structure.
2. Ensure `.github/workflows/android-apk.yml` is in that exact path.
3. Open Actions and run `DualView APK Builder`, or commit to `main` to trigger it.
4. Download the `DualView-Android-APK` artifact from the completed run.

The GitHub cloud runner compiles the APK. This ZIP is source code, not a prebuilt or device-tested APK.
