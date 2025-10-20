import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WarehouseEditorScreen extends StatefulWidget {
  const WarehouseEditorScreen({super.key});

  @override
  State<WarehouseEditorScreen> createState() => _WarehouseEditorScreenState();
}

class _WarehouseEditorScreenState extends State<WarehouseEditorScreen> {
  bool _isDisposed = false;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    // Register the iframe view factory
    ui_web.platformViewRegistry.registerViewFactory('warehouse-editor', (int viewId) {
      final iframe = html.IFrameElement()
        ..src = '/warehouse_editor/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; camera; display-capture; encrypted-media; fullscreen; geolocation; gyroscope; microphone; midi; payment; usb; xr-spatial-tracking'
        ..sandbox.addAll([
          'allow-forms',
          'allow-modals',
          'allow-orientation-lock',
          'allow-pointer-lock',
          'allow-popups',
          'allow-popups-to-escape-sandbox',
          'allow-presentation',
          'allow-same-origin',
          'allow-scripts',
          'allow-top-navigation',
          'allow-top-navigation-by-user-activation',
        ] as List<String>);

      // Listen for messages from the iframe
      _messageSubscription = html.window.onMessage.listen((event) {
        if (_isDisposed) return;
        if (event.data is Map) {
          final data = event.data as Map;
          if (data['type'] == 'export') {
            // Handle export data
            print('Received export data: ${data['data']}');
          }
        }
      });

      return iframe;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Warehouse Editor'),
      ),
      body: const HtmlElementView(
        viewType: 'warehouse-editor',
      ),
    );
  }
} 