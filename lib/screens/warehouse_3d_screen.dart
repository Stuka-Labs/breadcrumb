import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Warehouse3DScreen extends StatefulWidget {
  const Warehouse3DScreen({Key? key}) : super(key: key);

  @override
  State<Warehouse3DScreen> createState() => _Warehouse3DScreenState();
}

class _Warehouse3DScreenState extends State<Warehouse3DScreen> {
  late html.IFrameElement _iframe;
  bool _loading = true;
  String? _layoutJson;

  @override
  void initState() {
    super.initState();
    _iframe = html.IFrameElement()
      ..src = 'warehouse_editor/index.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..onLoad.listen((event) {
        setState(() {
          _loading = false;
        });
      });
    // Fallback: hide spinner after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _loading) setState(() => _loading = false);
    });
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'warehouse-3d-iframe',
      (int viewId) => _iframe,
    );
    html.window.onMessage.listen((event) {
      if (event.data is Map && event.data['type'] == 'export') {
        setState(() {
          _layoutJson = event.data['data'] != null ? jsonEncode(event.data['data']) : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layout exported!')));
      }
      if (event.data is Map && event.data['type'] == 'import-request') {
        if (_layoutJson != null) {
          _iframe.contentWindow?.postMessage({'type': 'import', 'data': jsonDecode(_layoutJson!)}, '*');
        }
      }
    });
  }

  void _exportLayout() {
    _iframe.contentWindow?.postMessage({'type': 'export-request'}, '*');
  }

  void _importLayout() {
    if (_layoutJson != null) {
      _iframe.contentWindow?.postMessage({'type': 'import', 'data': jsonDecode(_layoutJson!)}, '*');
    }
  }

  Future<void> _saveToFirestore() async {
    _exportLayout();
    await Future.delayed(const Duration(milliseconds: 500));
    if (_layoutJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No layout to save!')));
      return;
    }
    final List<dynamic> layout = jsonDecode(_layoutJson!);
    final batch = FirebaseFirestore.instance.batch();
    for (final obj in layout) {
      batch.set(
        FirebaseFirestore.instance.collection('locations').doc(),
        {
          'zone': obj['layer'] ?? 1,
          'aisle': obj['aisle'] ?? 1,
          'shelf': obj['shelf'] ?? 1,
          'bin': obj['bin'] ?? 1,
          'capacity': obj['capacity'] ?? 0,
          'currentStock': obj['currentStock'] ?? 0,
          'status': obj['status'] ?? 'active',
          'type': obj['type'],
          'name': obj['name'],
          'width': obj['width'],
          'height': obj['height'],
          'depth': obj['depth'],
          'color': obj['color'],
          'rotation': obj['rotation'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3D Layout saved to Firestore!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Warehouse Blueprint')),
      body: Stack(
        children: [
          HtmlElementView(viewType: 'warehouse-3d-iframe'),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export Layout'),
                  onPressed: _exportLayout,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Layout'),
                  onPressed: _importLayout,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save to Firestore'),
                  onPressed: _saveToFirestore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 