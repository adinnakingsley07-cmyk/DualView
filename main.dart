import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:offline_document_viewer/offline_document_viewer.dart';

void main() => runApp(const DualViewApp());

class DualViewApp extends StatelessWidget {
  const DualViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DualView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457A6)),
        useMaterial3: true,
      ),
      home: const DualViewHome(),
    );
  }
}

class DualViewHome extends StatefulWidget {
  const DualViewHome({super.key});

  @override
  State<DualViewHome> createState() => _DualViewHomeState();
}

class _DualViewHomeState extends State<DualViewHome> {
  bool splitMode = false;
  final List<PaneState> panes = [PaneState(), PaneState()];

  Future<void> pickDocument(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf', 'docx', 'docm', 'xlsx', 'xlsm', 'xls',
        'pptx', 'pptm', 'ppt', 'doc', 'csv', 'tsv', 'rtf', 'txt',
      ],
      allowMultiple: false,
      withData: false,
    );

    if (!mounted || result == null || result.files.single.path == null) {
      return;
    }

    final picked = result.files.single;
    setState(() {
      panes[index].path = picked.path!;
      panes[index].name = picked.name;
      panes[index].controller.dispose();
      panes[index].controller = DocumentViewController();
      panes[index].unitCount = 0;
    });
  }

  @override
  void dispose() {
    for (final pane in panes) {
      pane.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DualView'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
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
              selected: <bool>{splitMode},
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
                      state: panes[0],
                      onOpen: () => pickDocument(0),
                    ),
                  ),
                  const VerticalDivider(width: 2),
                  Expanded(
                    child: DocumentPane(
                      state: panes[1],
                      onOpen: () => pickDocument(1),
                    ),
                  ),
                ],
              )
            : DocumentPane(
                state: panes[0],
                onOpen: () => pickDocument(0),
              ),
      ),
    );
  }
}

class PaneState {
  String? path;
  String? name;
  int unitCount = 0;
  DocumentViewController controller = DocumentViewController();
}

class DocumentPane extends StatefulWidget {
  const DocumentPane({
    super.key,
    required this.state,
    required this.onOpen,
  });

  final PaneState state;
  final VoidCallback onOpen;

  @override
  State<DocumentPane> createState() => _DocumentPaneState();
}

class _DocumentPaneState extends State<DocumentPane> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> runSearch() async {
    await widget.state.controller.search(searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.name ?? 'Document pane',
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
        if (state.path != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (_) => runSearch(),
                    decoration: const InputDecoration(
                      hintText: 'Find in document',
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: runSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.path == null
              ? _EmptyPane(onOpen: widget.onOpen)
              : DocumentView(
                  key: ValueKey<String>(state.path!),
                  source: DocumentSource.file(state.path!),
                  controller: state.controller,
                  placeholderBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, failure) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to display this document.\n'
                        '${failure.runtimeType}\n${failure.recovery}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  onReady: (info) {
                    if (!mounted) return;
                    setState(() => state.unitCount = info.unitCount);
                  },
                ),
        ),
        if (state.path != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Text(
              state.unitCount > 0
                  ? '${state.unitCount} pages / slides / sheets'
                  : 'Opening document…',
              textAlign: TextAlign.center,
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
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing open yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a document stored on your phone. '
              'Files are rendered on-device.',
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
