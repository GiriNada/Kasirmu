import 'package:flutter/material.dart';

import '../../core/utils/receipt_helper.dart';

class ReceiptSettingsPage extends StatefulWidget {
  const ReceiptSettingsPage({super.key});

  @override
  State<ReceiptSettingsPage> createState() => _ReceiptSettingsPageState();
}

class _ReceiptSettingsPageState extends State<ReceiptSettingsPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);

  late ReceiptStyle _draftStyle;
  late String _selectedPreset;

  @override
  void initState() {
    super.initState();
    _draftStyle = ReceiptHelper.currentStyle;
    _selectedPreset = _draftStyle.id;
  }

  Future<void> _save() async {
    await ReceiptHelper.saveStyle(
      _draftStyle,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset == ReceiptStyle.compact.id) {
        _draftStyle = ReceiptStyle.compact.copyWith(
          storeName: _draftStyle.storeName,
          headerLines: _draftStyle.headerLines,
          storeAddressLines: _draftStyle.storeAddressLines,
          logoPath: _draftStyle.logoPath,
          footerLines: _draftStyle.footerLines,
        );
      } else if (preset == ReceiptStyle.comfortable.id) {
        _draftStyle = ReceiptStyle.comfortable.copyWith(
          storeName: _draftStyle.storeName,
          headerLines: _draftStyle.headerLines,
          storeAddressLines: _draftStyle.storeAddressLines,
          logoPath: _draftStyle.logoPath,
          footerLines: _draftStyle.footerLines,
        );
      } else {
        _draftStyle = _draftStyle.copyWith(id: 'custom');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sample = ReceiptHelper.buildReceiptText(
      transaksiId: 1,
      dateTime: DateTime(2026, 4, 16, 9, 30),
      method: 'Cash',
      total: 28000,
      paid: 50000,
      items: const [
        {'name': 'Nasi Goreng', 'qty': 1, 'price': 15000},
        {'name': 'Es Teh', 'qty': 2, 'price': 6500},
      ],
      style: _draftStyle,
      includeStoreName: false,
    );

    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Pengaturan Struk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionCard(
            title: 'Gaya Struk',
            child: Column(
              children: [
                _presetTile(
                  title: 'Compact',
                  subtitle: 'Nama toko besar, isi rapat, hemat kertas',
                  value: ReceiptStyle.compact.id,
                ),
                const SizedBox(height: 10),
                _presetTile(
                  title: 'Comfortable',
                  subtitle: 'Tetap ringkas, tapi antarbagian lebih lega',
                  value: ReceiptStyle.comfortable.id,
                ),
                const SizedBox(height: 10),
                _presetTile(
                  title: 'Custom',
                  subtitle: 'Atur sendiri jarak dan tinggi teks',
                  value: 'custom',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Atur Kerapatan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sliderLabel(
                  'Jarak header nama toko',
                  '${_draftStyle.headerSpacing}',
                ),
                Slider(
                  value: _draftStyle.headerSpacing.toDouble(),
                  min: 0,
                  max: 3,
                  divisions: 3,
                  label: '${_draftStyle.headerSpacing}',
                  onChanged: (value) {
                    setState(() {
                      _selectedPreset = 'custom';
                      _draftStyle = _draftStyle.copyWith(
                        id: 'custom',
                        headerSpacing: value.round(),
                      );
                    });
                  },
                ),
                _sliderLabel(
                  'Jarak antarbagian',
                  '${_draftStyle.sectionSpacing}',
                ),
                Slider(
                  value: _draftStyle.sectionSpacing.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: '${_draftStyle.sectionSpacing}',
                  onChanged: (value) {
                    setState(() {
                      _selectedPreset = 'custom';
                      _draftStyle = _draftStyle.copyWith(
                        id: 'custom',
                        sectionSpacing: value.round(),
                      );
                    });
                  },
                ),
                _sliderLabel('Jarak antaritem', '${_draftStyle.itemSpacing}'),
                Slider(
                  value: _draftStyle.itemSpacing.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: '${_draftStyle.itemSpacing}',
                  onChanged: (value) {
                    setState(() {
                      _selectedPreset = 'custom';
                      _draftStyle = _draftStyle.copyWith(
                        id: 'custom',
                        itemSpacing: value.round(),
                      );
                    });
                  },
                ),
                _sliderLabel(
                  'Ukuran nama toko struk',
                  _storeNameSizeLabel(_draftStyle.storeNamePrintSize),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _headerSizeChip(
                      label: 'Kecil',
                      printSize: 1,
                    ),
                    _headerSizeChip(
                      label: 'Sedang',
                      printSize: 2,
                    ),
                    _headerSizeChip(
                      label: 'Besar',
                      printSize: 3,
                    ),
                  ],
                ),
                _sliderLabel(
                  'Tinggi baris preview',
                  _draftStyle.previewLineHeight.toStringAsFixed(2),
                ),
                Slider(
                  value: _draftStyle.previewLineHeight,
                  min: 1.2,
                  max: 1.6,
                  divisions: 8,
                  label: _draftStyle.previewLineHeight.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _selectedPreset = 'custom';
                      _draftStyle = _draftStyle.copyWith(
                        id: 'custom',
                        previewLineHeight: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Preview',
            child: Center(
              child: _buildThermalPreview(
                storeName: _draftStyle.storeName,
                body: sample,
              ),
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
              'Simpan Pengaturan',
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

  Widget _presetTile({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = _selectedPreset == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _applyPreset(value),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : _surfaceTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _primaryBlue : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: _primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderLabel(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _headerSizeChip({
    required String label,
    required int printSize,
  }) {
    final selected = _draftStyle.storeNamePrintSize == printSize;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedPreset = 'custom';
          _draftStyle = _draftStyle.copyWith(
            id: 'custom',
            storeNamePrintSize: printSize,
          );
        });
      },
      selectedColor: const Color(0xFFEFF6FF),
      backgroundColor: _surfaceTint,
      labelStyle: TextStyle(
        color: selected ? _primaryBlue : const Color(0xFF334155),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? _primaryBlue : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildThermalPreview({
    required String storeName,
    required String body,
  }) {
    return Container(
      width: 286,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E0D1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            storeName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ReceiptHelper.previewStoreNameFontSize(
                style: _draftStyle,
              ),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1,
            ),
          ),
          SizedBox(height: 6 + (_draftStyle.headerSpacing * 4)),
          Text(
            body,
            textAlign: TextAlign.left,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: _draftStyle.previewLineHeight,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _storeNameSizeLabel(int size) {
    switch (size) {
      case 1:
        return 'Kecil';
      case 2:
        return 'Sedang';
      case 3:
        return 'Besar';
      default:
        return size.toString();
    }
  }

}
