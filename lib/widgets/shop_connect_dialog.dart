import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import 'dart:html' as html show window;

class ShopConnectDialog extends StatelessWidget {
  final VoidCallback? onConnected;
  final String? clientId;
  const ShopConnectDialog({super.key, this.onConnected, this.clientId});

  static const String backendBaseUrl = 'https://remix-wgxs2bbz5q-uc.a.run.app'; // Cloud Run deployed backend URL

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Connect Your Shop',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 28),
                        splashRadius: 22,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect your store to start syncing orders and analytics.',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 28),
                  _shopifyButton(context),
                  const SizedBox(height: 16),
                  _oauthButton(context, 'Etsy', Icons.shopping_bag, kPastelOrange, '/api/auth/etsy'),
                  const SizedBox(height: 16),
                  _oauthButton(context, 'Amazon', Icons.store, Colors.amber, '/api/auth/amazon'),
                  const SizedBox(height: 16),
                  _oauthButton(context, 'TikTok Shop', Icons.video_collection, Colors.pinkAccent, '/api/auth/tiktok'),
                  const SizedBox(height: 16),
                  _oauthButton(context, 'WooCommerce', Icons.shopping_cart, Colors.deepPurpleAccent, '/api/auth/woocommerce'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shopifyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.shopping_bag, color: Colors.white),
        label: const Text('Shopify'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          elevation: 0,
        ),
        onPressed: () {
          if (kIsWeb) {
            final clientIdParam = clientId != null ? '&clientId=$clientId' : '';
            final url = '$backendBaseUrl/api/auth/shopify?shop=your-shop.myshopify.com$clientIdParam';
            html.window.open(url, '_blank');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shopify connection is only available on web platforms')),
            );
          }
        },
      ),
    );
  }

  Widget _oauthButton(BuildContext context, String label, IconData icon, Color color, String path) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          elevation: 0,
        ),
        onPressed: () {
          if (kIsWeb) {
            final url = backendBaseUrl + path;
            html.window.open(url, '_blank');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OAuth connection is only available on web platforms')),
            );
          }
        },
      ),
    );
  }
} 