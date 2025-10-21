import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show IFrameElement, window;
import 'dart:ui_web' as ui_web show platformViewRegistry;

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
    
    if (kIsWeb) {
      // Register the iframe view factory
      ui_web.platformViewRegistry.registerViewFactory('warehouse-editor', (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '/warehouse_editor/index.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'accelerometer; camera; display-capture; encrypted-media; fullscreen; geolocation; gyroscope; microphone; midi; payment; usb; xr-spatial-tracking'
          ..setAttribute('sandbox', 'allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups allow-popups-to-escape-sandbox allow-presentation allow-same-origin allow-scripts allow-top-navigation allow-top-navigation-by-user-activation');

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
      body: kIsWeb 
        ? const HtmlElementView(
            viewType: 'warehouse-editor',
          )
        : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.web, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '3D Warehouse Editor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This feature is only available on web platforms.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
    );
  }
} 