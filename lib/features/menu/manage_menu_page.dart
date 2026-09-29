import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/database_helper.dart';
import 'widgets/adaptive_menu_image.dart';
import 'menu_model.dart';

class ManageMenuPage extends StatefulWidget {
  const ManageMenuPage({super.key});

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);
  static const _successGreen = Color(0xFF16A34A);
  static const _dangerRed = Color(0xFFDC2626);
  static const _menuThumbnailSize = 96.0;

  final ImagePicker _picker = ImagePicker();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  List<MenuModel> menus = [];
  File? imageFile;

  @override
  void initState() {
    super.initState();
    loadMenus();
  }

  Future<void> loadMenus() async {
    final data = await DatabaseHelper.instance.getMenus();
    setState(() {
      menus = data.map((e) => MenuModel.fromMap(e)).toList();
    });
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final menuDir = Directory('${dir.path}/menu');
    if (!await menuDir.exists()) {
      await menuDir.create(recursive: true);
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final savedImage = await File(
      picked.path,
    ).copy('${menuDir.path}/$fileName.jpg');

    setState(() {
      imageFile = savedImage;
    });
  }

  void showForm({MenuModel? menu}) {
    final parentContext = context;
    final nameCtrl = TextEditingController(text: menu?.name ?? '');
    final priceCtrl = TextEditingController(text: menu?.price.toString() ?? '');

    imageFile = menu != null && menu.image.isNotEmpty ? File(menu.image) : null;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: _primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          menu == null ? 'Tambah Menu Baru' : 'Edit Menu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lengkapi nama, harga, dan foto menu jika perlu.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await pickImage();
                        setDialogState(() {});
                      },
                      child: Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          gradient:
                              imageFile == null
                                  ? null
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFFF8FAFC),
                                      Color(0xFFE2E8F0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                          color: imageFile == null ? _surfaceTint : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _primaryBlue.withValues(alpha: 0.16),
                            width: 1.4,
                          ),
                        ),
                        child:
                            imageFile == null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: AdaptiveMenuImage(
                                        imageProvider: null,
                                        fallbackLabel: nameCtrl.text,
                                        borderRadius: BorderRadius.circular(14),
                                        placeholderSize: 32,
                                      ),
                                    ),
                                  ],
                                )
                                : Align(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: AdaptiveMenuImage(
                                          imageProvider: FileImage(imageFile!),
                                          fallbackLabel: nameCtrl.text,
                                          borderRadius: BorderRadius.circular(14),
                                          placeholderSize: 32,
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          margin: const EdgeInsets.all(10),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: _inputDecoration(
                        labelText: 'Nama Menu',
                        hintText: 'Contoh: Nasi Goreng Spesial',
                        icon: Icons.restaurant_menu_rounded,
                        iconColor: _primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await pickImage();
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(
                              imageFile == null ? 'Pilih Foto' : 'Ganti Foto',
                            ),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                imageFile = null;
                              });
                            },
                            icon: const Icon(Icons.text_fields_rounded),
                            label: const Text('Teks Saja'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Foto opsional. Jika kosong, kotak menu akan menampilkan teks singkat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        labelText: 'Harga',
                        hintText: '15000',
                        icon: Icons.payments_rounded,
                        iconColor: _successGreen,
                        prefixText: 'Rp ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price = int.tryParse(priceCtrl.text) ?? 0;
                    final messenger = ScaffoldMessenger.of(parentContext);
                    final navigator = Navigator.of(parentContext);

                    if (name.isEmpty || price <= 0) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Nama dan harga wajib diisi'),
                          backgroundColor: _dangerRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      return;
                    }

                    if (menu == null) {
                      await DatabaseHelper.instance.addMenu(
                        name,
                        price,
                        imageFile?.path ?? '',
                      );
                    } else {
                      await DatabaseHelper.instance.updateMenu(
                        menu.id!,
                        name,
                        price,
                        imageFile?.path ?? '',
                      );
                    }

                    if (mounted) {
                      navigator.pop();
                    }
                    await loadMenus();

                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          menu == null
                              ? 'Menu berhasil ditambahkan'
                              : 'Menu berhasil diperbarui',
                        ),
                        backgroundColor: _successGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteMenu(MenuModel menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _dangerRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: _dangerRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hapus Menu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Yakin ingin menghapus "${menu.name}"? Tindakan ini tidak dapat dibatalkan.',
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dangerRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (menu.image.isNotEmpty) {
      final file = File(menu.image);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await DatabaseHelper.instance.deleteMenu(menu.id!);
    await loadMenus();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Menu berhasil dihapus'),
        backgroundColor: _dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int get totalMenu => menus.length;

  int get totalHargaMenu {
    return menus.fold(0, (sum, menu) => sum + menu.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Kelola Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => showForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Tambah',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          Expanded(
            child:
                menus.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: menus.length,
                      itemBuilder: (_, index) {
                        final menu = menus[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.03),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => showForm(menu: menu),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _buildMenuImage(menu),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menu.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Siap ditampilkan di kasir',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Rp ${_currencyFormat.format(menu.price)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _successGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              color: _primaryBlue,
                                              size: 22,
                                            ),
                                            onPressed:
                                                () => showForm(menu: menu),
                                            tooltip: 'Edit',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_rounded,
                                              color: _dangerRed,
                                              size: 22,
                                            ),
                                            onPressed: () => deleteMenu(menu),
                                            tooltip: 'Hapus',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Kelola katalog menu',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'Tambah, ubah, dan rapikan menu yang tampil di kasir.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          _summaryCard(
            label: 'Total Menu',
            value: '$totalMenu',
            icon: Icons.restaurant_menu_rounded,
            color: _primaryBlue,
            bgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 10),
          _summaryCard(
            label: 'Total Harga',
            value: 'Rp ${_currencyFormat.format(totalHargaMenu)}',
            icon: Icons.payments_rounded,
            color: _successGreen,
            bgColor: const Color(0xFFF0FDF4),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 44,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai tambahkan menu agar katalog di kasir siap dipakai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Menu Pertama',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImage(MenuModel menu) {
    return SizedBox(
      width: _menuThumbnailSize,
      height: _menuThumbnailSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: AdaptiveMenuImage(
          imageProvider:
              menu.image.isNotEmpty && File(menu.image).existsSync()
                  ? FileImage(File(menu.image))
                  : null,
          fallbackLabel: menu.name,
          borderRadius: BorderRadius.circular(11),
          placeholderSize: 34,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    required Color iconColor,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: iconColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: iconColor, width: 1.6),
      ),
      filled: true,
      fillColor: _surfaceTint,
    );
  }
}
