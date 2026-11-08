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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'docx', 'docm', 'xlsx', 'xlsm', 'xls',
          'pptx', 'pptm', 'ppt', 'doc', 'csv', 'tsv', 'rtf', 'txt'
        ],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.single.path == null) return;
      final picked = result.files.single;
      setState(() {
        panes[index].path = picked.path!;
        panes[index].name = picked.name;
        panes[index].controller.dispose();
        panes[index].controller = DocumentViewController();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
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
        subtitle: const Text('Offline document workspace'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Mobile'), icon: Icon(Icons.smartphone)),
                ButtonSegment(value: true, label: Text('PC split'), icon: Icon(Icons.splitscreen)),
              ],
              selected: {splitMode},
              onSelectionChanged: (value) => setState(() => splitMode = value.first),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: splitMode
            ? Row(
                children: [
                  Expanded(child: DocumentPane(state: panes[0], index: 0, onOpen: () => pickDocument(0))),
                  const VerticalDivider(width: 2),
                  Expanded(child: DocumentPane(state: panes[1], index: 1, onOpen: () => pickDocument(1))),
                ],
              )
            : DocumentPane(state: panes[0], index: 0, onOpen: () => pickDocument(0)),
      ),
    );
  }
}

class PaneState {
  String? path;
  String? name;
  DocumentViewController controller = DocumentViewController();
}

class DocumentPane extends StatefulWidget {
  const DocumentPane({
    super.key,
    required this.state,
    required this.index,
    required this.onOpen,
  });

  final PaneState state;
  final int index;
  final VoidCallback onOpen;

  @override
  State<DocumentPane> createState() => _DocumentPaneState();
}

class _DocumentPaneState extends State<DocumentPane> {
  final searchController = TextEditingController();
  int currentUnit = 1;
  int totalUnits = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> search() async {
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.name ?? 'Document ${widget.index + 1}',
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
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (_) => search(),
                    decoration: const InputDecoration(
                      hintText: 'Find in document',
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(onPressed: search, icon: const Icon(Icons.search)),
              ],
            ),
          ),
        Expanded(
          child: state.path == null
              ? _EmptyPane(onOpen: widget.onOpen)
              : DocumentView(
                  key: ValueKey(state.path),
                  source: DocumentSource.file(state.path!),
                  controller: state.controller,
                  placeholderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, failure) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to display this document.\n${failure.runtimeType}\n${failure.recovery}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  onReady: (info) {
                    if (mounted) setState(() => totalUnits = info.unitCount);
                  },
                ),
        ),
        if (state.path != null)
          ListenableBuilder(
            listenable: state.controller,
            builder: (context, _) {
              final position = state.controller.position;
              final unit = position == null ? 1 : position.index + 1;
              return Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(totalUnits > 0 ? '$unit / $totalUnits' : 'Document open'),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Previous page / slide',
                          onPressed: unit > 1 ? () => state.controller.goTo(unit - 2) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Next page / slide',
                          onPressed: totalUnits == 0 || unit < totalUnits
                              ? () => state.controller.goTo(unit)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Nothing open yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Choose a document stored on your phone. Files are rendered on-device.'),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.folder_open), label: const Text('Open file')),
            ],
          ),
        ),
      );
}
