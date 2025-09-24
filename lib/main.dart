// Flutter web app - Paste to JSON (Firewall Rules)
// Copy this file to lib/main.dart in a Flutter project and run with `flutter run -d chrome`.

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FirewallRuleApp());
}

class FirewallRuleApp extends StatelessWidget {
  const FirewallRuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paste → Firewall JSON',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Roboto',
      ),
      home: const PasteToJsonHome(),
    );
  }
}

class PasteToJsonHome extends StatefulWidget {
  const PasteToJsonHome({super.key});

  @override
  State<PasteToJsonHome> createState() => _PasteToJsonHomeState();
}

class _PasteToJsonHomeState extends State<PasteToJsonHome> {
  final TextEditingController _pasteController = TextEditingController();
  final TextEditingController _fileNameController =
  TextEditingController(text: 'RuleFirewall.dat');
  String? _jsonPretty;
  int _indentSpaces = 2;
  String _status = '';

  @override
  void dispose() {
    _pasteController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  bool _isIPAddress(String input) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$'); // IPv4
    return ipRegex.hasMatch(input.trim());
  }

  bool _isDomainOrUrl(String input) {
    final urlRegex = RegExp(
        r'^(https?:\/\/)?([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})(\/.*)?$'); // URL/Domain
    return urlRegex.hasMatch(input.trim());
  }

  void _generateJson() {
    final raw = _pasteController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _status = 'Vui lòng dán dữ liệu trước khi tạo JSON.';
      });
      return;
    }

    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final blackListIP = <String>[];
    final blackListDNS = <String>[];

    for (final line in lines) {
      if (_isIPAddress(line)) {
        blackListIP.add(line);
      } else if (_isDomainOrUrl(line)) {
        blackListDNS.add(line);
      }
    }

    final result = {
      "blackListIP": blackListIP,
      "blackListDNS": blackListDNS,
    };

    final encoder = JsonEncoder.withIndent(' ' * _indentSpaces);
    final pretty = encoder.convert(result);

    setState(() {
      _jsonPretty = pretty;
      _status = 'Tạo JSON thành công.';
    });
  }

  void _downloadJson() {
    if (_jsonPretty == null) return;
    final filename = _fileNameController.text.trim().isEmpty
        ? 'RuleFirewall.dat'
        : _fileNameController.text.trim();

    final bytes = utf8.encode(_jsonPretty!);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = filename
      ..style.display = 'none';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    setState(() {
      _status = 'Đã tải xuống $filename';
    });
  }

  void _copyJsonToClipboard() {
    if (_jsonPretty == null) return;
    Clipboard.setData(ClipboardData(text: _jsonPretty!));
    setState(() {
      _status = 'Đã copy JSON vào clipboard.';
    });
  }

  void _clearAll() {
    _pasteController.clear();
    setState(() {
      _jsonPretty = null;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paste → Firewall Rules JSON'),
        centerTitle: false,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: _clearAll,
            icon: const Icon(Icons.clear_all),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Column(
            children: [
              // header card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Dán danh sách IP/DNS vào khung bên dưới',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text(
                                'Mỗi dòng 1 mục. IP sẽ vào blackListIP, URL sẽ vào blackListDNS',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _generateJson,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Tạo JSON'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // main content
              Expanded(
                child: isWide
                    ? Row(
                  children: [
                    Expanded(child: _buildInputCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPreviewCard()),
                  ],
                )
                    : Column(
                  children: [
                    Expanded(child: _buildInputCard()),
                    const SizedBox(height: 12),
                    Expanded(child: _buildPreviewCard()),
                  ],
                ),
              ),

              // footer controls
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fileNameController,
                      decoration: const InputDecoration(
                          labelText: 'Tên file khi tải (mặc định: RuleFirewall.dat)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _indentSpaces,
                    items: const [1, 2, 4, 8]
                        .map((e) => DropdownMenuItem<int>(
                        value: e, child: Text('Indent ${e}')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _indentSpaces = v;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _jsonPretty == null ? null : _downloadJson,
                    icon: const Icon(Icons.download),
                    label: const Text('Tải JSON'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _jsonPretty == null ? null : _copyJsonToClipboard,
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copy'),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child:
                Text(_status, style: const TextStyle(color: Colors.grey)),
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Input (paste ở đây)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _pasteController,
                expands: true,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                  'Dán dữ liệu thô, mỗi dòng 1 IP hoặc 1 DNS/URL (vd: 157.240.199.35 hoặc https://vnexpress.net)',
                ),
                style: const TextStyle(fontSize: 14, height: 1.4),
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pasteController.text =
                      '157.240.199.35\n157.240.199.36\nhttps://vnexpress.net/\nhttps://thanhnien.vn/';
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Sample'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pasteController.text = '';
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                Text(
                    '${_pasteController.text.split(RegExp(r"\r?\n")).where((l) => l.trim().isNotEmpty).length} dòng'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Preview JSON',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: _jsonPretty == null
                    ? const Center(
                    child: Text(
                        'Chưa có JSON — bấm "Tạo JSON" để xem preview'))
                    : SingleChildScrollView(
                  child: SelectableText(
                    _jsonPretty!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
