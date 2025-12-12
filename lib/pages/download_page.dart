import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toneup_app/services/config.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.mic, size: 64, color: Colors.white),
                ),

                const SizedBox(height: 32),

                Text(
                  'ToneUp Chinese learning',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'download the mobile app and start your 7-day free trial',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // 下载按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // iOS
                    Expanded(
                      child: _buildDownloadButton(
                        context,
                        icon: Icons.apple,
                        label: 'App Store',
                        url: UriConfig.appStoreUrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Android
                    Expanded(
                      child: _buildDownloadButton(
                        context,
                        icon: Icons.android,
                        label: 'Google Play',
                        url: UriConfig.playStoreUrl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // 二维码（可选）
                Text(
                  'Scan QR code to download',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // iOS 二维码
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: UriConfig.appStoreUrl,
                            size: 150,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('iOS'),
                      ],
                    ),

                    const SizedBox(width: 32),

                    // Android 二维码
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: UriConfig.playStoreUrl,
                            size: 150,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Android'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _launchUrl(context, url),
      icon: Icon(icon, size: 28),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开链接')));
      }
    }
  }
}
