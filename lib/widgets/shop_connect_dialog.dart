import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import 'dart:html' as html;

class ShopConnectDialog extends StatelessWidget {
  final VoidCallback? onConnected;
  const ShopConnectDialog({super.key, this.onConnected});

  static const String shopifyInstallUrl = 'https://apps.shopify.com/'; // Replace with your actual app store listing URL if available
  static const String backendBaseUrl = 'https://us-central1-breadcrumb-bd857.cloudfunctions.net/remix'; // Cloud Run deployed backend URL

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
        onPressed: () async {
          final url = Uri.parse(shopifyInstallUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch Shopify install URL')),
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
          final url = backendBaseUrl + path;
          html.window.open(url, '_blank');
        },
      ),
    );
  }
} 