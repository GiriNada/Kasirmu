import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/receipt_helper.dart';

class StoreProfilePage extends StatefulWidget {
  const StoreProfilePage({super.key});

  @override
  State<StoreProfilePage> createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends State<StoreProfilePage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);

  final ImagePicker _picker = ImagePicker();

  late TextEditingController _storeNameController;
  late TextEditingController _headerController;
  late TextEditingController _storeAddressController;
  late TextEditingController _footerController;

  String? _logoPath;

  @override
  void initState() {
    super.initState();
    final style = ReceiptHelper.currentStyle;
    _storeNameController = TextEditingController(text: style.storeName);
    _headerController = TextEditingController(
      text: style.headerLines.join('\n'),
    );
    _storeAddressController = TextEditingController(
      text: style.storeAddressLines.join('\n'),
    );
    _footerController = TextEditingController(
      text: style.footerLines.join('\n'),
    );
    _logoPath = style.logoPath;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _headerController.dispose();
    _storeAddressController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final logoDir = Directory('${dir.path}/store_profile');
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }

    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
    final savedImage = await File(picked.path).copy('${logoDir.path}/$fileName');

    setState(() {
      _logoPath = savedImage.path;
    });
  }

  Future<void> _removeLogo() async {
    final path = _logoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _logoPath = null;
    });
  }

  Future<void> _save() async {
    final storeName = _storeNameController.text.trim().isEmpty
        ? ReceiptStyle.compact.storeName
        : _storeNameController.text.trim();
    final addressLines = _storeAddressController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final headerLines = _headerController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final footerLines = _footerController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    await ReceiptHelper.saveStyle(
      ReceiptHelper.currentStyle.copyWith(
        storeName: storeName,
        headerLines: headerLines,
        storeAddressLines: addressLines.isEmpty
            ? ReceiptStyle.compact.storeAddressLines
            : addressLines,
        footerLines: footerLines.isEmpty
            ? ReceiptStyle.compact.footerLines
            : footerLines,
        logoPath: _logoPath,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Profil Toko',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionCard(
            title: 'Logo Toko',
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipOval(
                    child: _logoPath != null && File(_logoPath!).existsSync()
                        ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                        : const Icon(
                            Icons.storefront_rounded,
                            size: 42,
                            color: _primaryBlue,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Pilih Logo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryBlue,
                          side: const BorderSide(color: _primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _logoPath == null ? null : _removeLogo,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus Logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Identitas Toko',
            child: Column(
              children: [
                TextField(
                  controller: _storeNameController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Nama toko',
                    hint: 'Contoh: WARUNG NDESO',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _headerController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: 'Header struk',
                    hint: 'Satu baris per kalimat header',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeAddressController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    label: 'Alamat toko',
                    hint: 'Satu baris per bagian alamat',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _footerController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    label: 'Footer struk',
                    hint: 'Satu baris per kalimat footer',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Simpan Profil Toko',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _surfaceTint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryBlue, width: 1.5),
      ),
    );
  }
}
