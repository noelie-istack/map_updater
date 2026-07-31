import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double? _svgWidth;
  double? _svgHeight;
  Map<String, Map<String, String>> _exhibitorBooths = {};
  Map<String, Map<String, String>> _sponsoredAreaBooths = {};

  Uint8List? _uploadedSvgBytes;

  final _sponsoredIdsController = TextEditingController();

  static const _knownSponsoredIds = [
    'MainStage',
    'ExhibitionBar',
    'RelaxationBeach',
    'NetworkingZone',
    'BusinessHub',
    'MeetingTables',
    'Cafe',
    'MediaCentre',
    'Info',
    'BreakOutStage',
    'ExhibitorLounge',
    'BeerGarden',
    'MassageArea',
    'SpeakerLounge',
    'ConnectZone',
  ];

  Set<String> get _selectedIds => _sponsoredIdsController.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();

  void _toggleId(String id) async {
    final current = _selectedIds;
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    setState(() {
      _sponsoredIdsController.text = current.join(', ');
    });
    final svgString = _uploadedSvgBytes != null
        ? String.fromCharCodes(_uploadedSvgBytes!)
        : await rootBundle.loadString('assets/floorplan.svg');
    _parseSponsoredAreaBooths(svgString);
  }

  @override
  void dispose() {
    _sponsoredIdsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    getDimensions();
    getExhibitorBooths();
    getSponsoredAreaBooths();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left panel ──────────────────────────────────────
            SizedBox(
              width: 340,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Floorplan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _uploadedSvgBytes != null
                            ? SvgPicture.memory(
                                _uploadedSvgBytes!,
                                width: 308,
                                height: 308,
                                fit: BoxFit.contain,
                              )
                            : SvgPicture.asset(
                                'assets/floorplan.svg',
                                width: 308,
                                height: 308,
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickSvgFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload SVG'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.height,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Height: ${_svgHeight?.toStringAsFixed(0) ?? '—'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copy height',
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: _svgHeight == null
                                ? null
                                : () => _copyToClipboard(
                                    context,
                                    _svgHeight!.toStringAsFixed(0),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const RotatedBox(
                            quarterTurns: 1,
                            child: Icon(
                              Icons.height,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Width:  ${_svgWidth?.toStringAsFixed(0) ?? '—'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copy width',
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: _svgWidth == null
                                ? null
                                : () => _copyToClipboard(
                                    context,
                                    _svgWidth!.toStringAsFixed(0),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // ── Right panel ─────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // ExhibitorBooths card
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Exhibitor Booths',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Copy JSON',
                                  icon: const Icon(Icons.copy),
                                  onPressed: _exhibitorBooths.isEmpty
                                      ? null
                                      : () => _copyToClipboard(
                                          context,
                                          const JsonEncoder.withIndent(
                                            '  ',
                                          ).convert(_exhibitorBooths),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _exhibitorBooths.isNotEmpty
                                        ? const JsonEncoder.withIndent(
                                            '  ',
                                          ).convert(_exhibitorBooths)
                                        : '...',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // SponsoredAreaBooths card
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sponsored Area Booths',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Copy JSON',
                                  icon: const Icon(Icons.copy),
                                  onPressed: _sponsoredAreaBooths.isEmpty
                                      ? null
                                      : () => _copyToClipboard(
                                          context,
                                          const JsonEncoder.withIndent(
                                            '  ',
                                          ).convert(_sponsoredAreaBooths),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _knownSponsoredIds.map((id) {
                                final selected = _selectedIds.contains(id);
                                return FilterChip(
                                  label: Text(id),
                                  selected: selected,
                                  onSelected: (_) => _toggleId(id),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _sponsoredIdsController,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Sponsored IDs (comma-separated)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final svgString = _uploadedSvgBytes != null
                                        ? String.fromCharCodes(
                                            _uploadedSvgBytes!,
                                          )
                                        : await rootBundle.loadString(
                                            'assets/floorplan.svg',
                                          );
                                    _parseSponsoredAreaBooths(svgString);
                                  },
                                  child: const Text('Apply'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sponsored IDs must match the ID found inside the SVG.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _sponsoredAreaBooths.isNotEmpty
                                        ? const JsonEncoder.withIndent(
                                            '  ',
                                          ).convert(_sponsoredAreaBooths)
                                        : '...',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickSvgFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final bytes = result.files.single.bytes!;
    final svgString = String.fromCharCodes(bytes);
    _parseDimensions(svgString);
    _parseExhibitorBooths(svgString);
    _parseSponsoredAreaBooths(svgString);
    setState(() {
      _uploadedSvgBytes = bytes;
    });
  }

  void getDimensions() async {
    final svgString = await rootBundle.loadString('assets/floorplan.svg');
    _parseDimensions(svgString);
  }

  void _parseDimensions(String svgString) {
    final widthMatch = RegExp(
      r'<svg[^>]*\swidth="([^"]+)"',
    ).firstMatch(svgString);
    final heightMatch = RegExp(
      r'<svg[^>]*\sheight="([^"]+)"',
    ).firstMatch(svgString);
    setState(() {
      _svgWidth = widthMatch != null
          ? double.tryParse(widthMatch.group(1)!)
          : null;
      _svgHeight = heightMatch != null
          ? double.tryParse(heightMatch.group(1)!)
          : null;
    });
  }

  void getExhibitorBooths() async {
    final svgString = await rootBundle.loadString('assets/floorplan.svg');
    _parseExhibitorBooths(svgString);
  }

  void _parseExhibitorBooths(String svgString) {
    final document = XmlDocument.parse(svgString);
    final boothPattern = RegExp(r'^[ABC]\d{2}$');
    final Map<String, Map<String, String>> booths = {};

    for (final group in document.findAllElements('g')) {
      final id = group.getAttribute('id') ?? '';
      if (boothPattern.hasMatch(id)) {
        final firstChild = group.childElements.firstWhere(
          (e) => e.name.local == 'rect' || e.name.local == 'path',
          orElse: () => group.childElements.first,
        );
        final attrs = <String, String>{};
        if (firstChild.name.local == 'rect') {
          attrs['d'] = _rectToPath(firstChild);
        } else {
          for (final attr in firstChild.attributes) {
            if (attr.name.local == 'fill' &&
                attr.value.toLowerCase() == 'white')
              continue;
            attrs[attr.name.local] = attr.value;
          }
        }
        booths[id] = attrs;
      }
    }

    setState(() {
      _exhibitorBooths = booths;
    });
  }

  String _rectToPath(XmlElement rect) {
    final x = double.tryParse(rect.getAttribute('x') ?? '0') ?? 0;
    final y = double.tryParse(rect.getAttribute('y') ?? '0') ?? 0;
    final w = double.tryParse(rect.getAttribute('width') ?? '0') ?? 0;
    final h = double.tryParse(rect.getAttribute('height') ?? '0') ?? 0;
    final rx = double.tryParse(rect.getAttribute('rx') ?? '0') ?? 0;
    final ry =
        double.tryParse(
          rect.getAttribute('ry') ?? rect.getAttribute('rx') ?? '0',
        ) ??
        0;

    if (rx == 0 && ry == 0) {
      return 'M$x,${y}h${w}v${h}h${-w}Z';
    }
    // Rounded rect
    return 'M${x + rx},$y'
        'h${w - 2 * rx}'
        'a$rx,$ry 0 0 1 $rx,$ry'
        'v${h - 2 * ry}'
        'a$rx,$ry 0 0 1 ${-rx},$ry'
        'h${-(w - 2 * rx)}'
        'a$rx,$ry 0 0 1 ${-rx},${-ry}'
        'v${-(h - 2 * ry)}'
        'a$rx,$ry 0 0 1 $rx,${-ry}'
        'Z';
  }

  void getSponsoredAreaBooths() async {
    final svgString = await rootBundle.loadString('assets/floorplan.svg');
    _parseSponsoredAreaBooths(svgString);
  }

  void _parseSponsoredAreaBooths(String svgString) {
    final document = XmlDocument.parse(svgString);
    final sponsoredIds = _sponsoredIdsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final Map<String, Map<String, String>> booths = {};

    for (final group in document.findAllElements('g')) {
      final id = group.getAttribute('id') ?? '';
      if (sponsoredIds.contains(id)) {
        final firstChild = group.childElements.firstWhere(
          (e) => e.name.local == 'rect' || e.name.local == 'path',
          orElse: () => group.childElements.first,
        );
        final attrs = <String, String>{};
        if (firstChild.name.local == 'rect') {
          attrs['d'] = _rectToPath(firstChild);
        } else {
          for (final attr in firstChild.attributes) {
            if (attr.name.local == 'fill' &&
                attr.value.toLowerCase() == 'white')
              continue;
            attrs[attr.name.local] = attr.value;
          }
        }
        booths[id] = attrs;
      }
    }

    setState(() {
      _sponsoredAreaBooths = booths;
    });
  }
}
