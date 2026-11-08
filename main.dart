import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:offline_document_viewer/offline_document_viewer.dart';

void main() {
  runApp(const DualViewApp());
}

class DualViewApp extends StatelessWidget {
  const DualViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2457A6),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'DualView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const DualViewHome(),
    );
  }
}

class DocumentPaneState {
  String? fileName;
  Uint8List? bytes;
  DocumentViewController controller = DocumentViewController();

  void replaceDocument({required String name, required Uint8List data}) {
    controller.dispose();
    controller = DocumentViewController();
    fileName = name;
    bytes = data;
  }

  void dispose() => controller.dispose();
}

class DualViewHome extends StatefulWidget {
  const DualViewHome({super.key});

  @override
  State<DualViewHome> createState() => _DualViewHomeState();
}

class _DualViewHomeState extends State<DualViewHome> {
  bool splitMode = false;
  final panes = [DocumentPaneState(), DocumentPaneState()];

  Future<void> openDocument(int paneIndex) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'docx', 'docm', 'doc', 'pptx', 'pptm', 'ppt',
          'xlsx', 'xlsm', 'xls', 'csv', 'tsv', 'rtf', 'txt'
        ],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final selected = result.files.single;
      final data = selected.bytes;
      if (data == null) {
        throw Exception('The selected file could not be read. Please choose it again.');
      }

      setState(() {
        panes[paneIndex].replaceDocument(name: selected.name, data: data);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open file: $error')),
      );
    }
  }

  @override
  void dispose() {
    for (final pane in panes) {
      pane.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DUALVIEW',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF182337),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(
                  const BorderSide(color: Colors.white54),
                ),
              ),
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Mobile'),
                  icon: Icon(Icons.smartphone),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('PC split'),
                  icon: Icon(Icons.splitscreen),
                ),
              ],
              selected: {splitMode},
              onSelectionChanged: (selection) {
                setState(() => splitMode = selection.first);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: splitMode
            ? Row(
                children: [
                  Expanded(
                    child: DocumentPane(
                      key: const ValueKey('pane-left'),
                      pane: panes[0],
                      paneNumber: 1,
                      onOpen: () => openDocument(0),
                    ),
                  ),
                  const VerticalDivider(width: 2, thickness: 1),
                  Expanded(
                    child: DocumentPane(
                      key: const ValueKey('pane-right'),
                      pane: panes[1],
                      paneNumber: 2,
                      onOpen: () => openDocument(1),
                    ),
                  ),
                ],
              )
            : DocumentPane(
                key: const ValueKey('pane-mobile'),
                pane: panes[0],
                paneNumber: 1,
                onOpen: () => openDocument(0),
              ),
      ),
    );
  }
}

class DocumentPane extends StatefulWidget {
  const DocumentPane({
    super.key,
    required this.pane,
    required this.paneNumber,
    required this.onOpen,
  });

  final DocumentPaneState pane;
  final int paneNumber;
  final VoidCallback onOpen;

  @override
  State<DocumentPane> createState() => _DocumentPaneState();
}

class _DocumentPaneState extends State<DocumentPane> {
  final searchController = TextEditingController();
  int unitCount = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchDocument() async {
    await widget.pane.controller.search(searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final pane = widget.pane;
    final hasDocument = pane.bytes != null && pane.fileName != null;

    return Column(
      children: [
        Material(
          color: const Color(0xFFE8EDF5),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pane.fileName ?? 'Document ${widget.paneNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Open document',
                  onPressed: widget.onOpen,
                  icon: const Icon(Icons.folder_open),
                ),
              ],
            ),
          ),
        ),
        if (hasDocument)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (_) => searchDocument(),
                    decoration: const InputDecoration(
                      hintText: 'Find in document',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: searchDocument,
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    searchController.clear();
                    pane.controller.search('');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
        Expanded(
          child: !hasDocument
              ? _EmptyPane(onOpen: widget.onOpen)
              : DocumentView(
                  key: ValueKey('${pane.fileName}-${pane.bytes!.length}'),
                  source: DocumentSource.bytes(
                    pane.bytes!,
                    name: pane.fileName!,
                  ),
                  controller: pane.controller,
                  placeholderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (context, failure) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'This document could not be displayed.\n\n'
                        '${failure.runtimeType}\n'
                        '${failure.recovery}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  onReady: (info) {
                    if (mounted) {
                      setState(() => unitCount = info.unitCount);
                    }
                  },
                ),
        ),
        if (hasDocument)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: const Color(0xFFE8EDF5),
            child: Text(
              unitCount > 0
                  ? '$unitCount pages / slides / sheets'
                  : 'Document opened',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: Color(0xFF2457A6),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nothing open yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a document stored on your phone. In PC split mode, '
              'each side can show a different file.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open file'),
            ),
          ],
        ),
      ),
    );
  }
}
