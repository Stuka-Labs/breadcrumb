import 'package:flutter/material.dart';
import '../constants/theme.dart';

class ShopConnectDialog extends StatelessWidget {
  final VoidCallback? onConnected;
  const ShopConnectDialog({super.key, this.onConnected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connect Your Shop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _shopButton(context, 'Etsy', Icons.shopping_bag, kPastelOrange),
            const SizedBox(height: 12),
            _shopButton(context, 'Amazon', Icons.store, Colors.amber),
            const SizedBox(height: 12),
            _shopButton(context, 'TikTok Shop', Icons.video_collection, Colors.pinkAccent),
            const SizedBox(height: 12),
            _shopButton(context, 'WooCommerce', Icons.shopping_cart, Colors.deepPurpleAccent),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopButton(BuildContext context, String label, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          // TODO: Implement OAuth/connection flow for each platform
          if (onConnected != null) onConnected!();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connect $label coming soon!')),
          );
        },
      ),
    );
  }
} 