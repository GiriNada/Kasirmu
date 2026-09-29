import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/utils/receipt_helper.dart';
import '../printer/printer_page.dart';
import '../receipt/receipt_settings_page.dart';
import 'about_app_page.dart';
import 'store_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    ReceiptHelper.loadStyle().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = ReceiptHelper.currentStyle;

    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage:
                      style.logoPath != null &&
                              style.logoPath!.isNotEmpty &&
                              File(style.logoPath!).existsSync()
                          ? FileImage(
                              File(style.logoPath!),
                            )
                          : null,
                  child:
                      style.logoPath == null ||
                              style.logoPath!.isEmpty ||
                              !File(style.logoPath!).existsSync()
                          ? const Icon(
                              Icons.storefront_rounded,
                              color: _primaryBlue,
                              size: 28,
                            )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style.storeAddressLines.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _menuTile(
            icon: Icons.store_rounded,
            title: 'Profil Toko',
            subtitle: 'Nama toko, header, alamat, footer, dan logo',
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const StoreProfilePage()),
              );
              if (changed == true) {
                await ReceiptHelper.loadStyle();
                if (mounted) setState(() {});
              }
            },
          ),
          const SizedBox(height: 10),
          _menuTile(
            icon: Icons.receipt_long_rounded,
            title: 'Pengaturan Struk',
            subtitle: 'Atur kerapatan dan gaya tampilan struk',
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptSettingsPage()),
              );
              if (changed == true) {
                await ReceiptHelper.loadStyle();
                if (mounted) setState(() {});
              }
            },
          ),
          const SizedBox(height: 10),
          _menuTile(
            icon: Icons.print_rounded,
            title: 'Printer',
            subtitle: 'Hubungkan printer bluetooth dan test print',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _menuTile(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi singkat tentang Kasirmu',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutAppPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
