import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptStyle {
  final String id;
  final int lineWidth;
  final int headerSpacing;
  final int sectionSpacing;
  final int itemSpacing;
  final double previewLineHeight;
  final int storeNamePrintSize;
  final List<String> headerLines;
  final List<String> footerLines;
  final String storeName;
  final List<String> storeAddressLines;
  final String? logoPath;

  const ReceiptStyle({
    this.id = 'custom',
    this.lineWidth = 32,
    this.headerSpacing = 1,
    this.sectionSpacing = 0,
    this.itemSpacing = 0,
    this.previewLineHeight = 1.35,
    this.storeNamePrintSize = 3,
    this.headerLines = const [],
    this.footerLines = const [
      'Terima kasih atas kunjungan Anda',
      'Kepuasan Anda adalah',
      'prioritas kami',
    ],
    this.storeName = 'WARUNG NDESO',
    this.storeAddressLines = const [
      'Ngasem, Monggot, Kec. Geyer',
      'Kabupaten Grobogan, Jawa Tengah',
      'Telp: 0878-2697-9247',
    ],
    this.logoPath,
  });

  static const compact = ReceiptStyle(
    id: 'compact',
    headerSpacing: 0,
    sectionSpacing: 0,
    itemSpacing: 0,
    previewLineHeight: 1.22,
    storeNamePrintSize: 3,
  );

  static const comfortable = ReceiptStyle(
    id: 'comfortable',
    headerSpacing: 1,
    sectionSpacing: 1,
    itemSpacing: 0,
    previewLineHeight: 1.34,
    storeNamePrintSize: 3,
  );

  ReceiptStyle copyWith({
    String? id,
    int? lineWidth,
    int? headerSpacing,
    int? sectionSpacing,
    int? itemSpacing,
    double? previewLineHeight,
    int? storeNamePrintSize,
    List<String>? headerLines,
    List<String>? footerLines,
    String? storeName,
    List<String>? storeAddressLines,
    String? logoPath,
  }) {
    return ReceiptStyle(
      id: id ?? this.id,
      lineWidth: lineWidth ?? this.lineWidth,
      headerSpacing: headerSpacing ?? this.headerSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      previewLineHeight: previewLineHeight ?? this.previewLineHeight,
      storeNamePrintSize: storeNamePrintSize ?? this.storeNamePrintSize,
      headerLines: headerLines ?? this.headerLines,
      footerLines: footerLines ?? this.footerLines,
      storeName: storeName ?? this.storeName,
      storeAddressLines: storeAddressLines ?? this.storeAddressLines,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}

class ReceiptHelper {
  static ReceiptStyle currentStyle = ReceiptStyle.compact;
  static const _stylePresetKey = 'receipt_style_preset';
  static const _styleHeaderSpacingKey = 'receipt_style_header_spacing';
  static const _styleSectionSpacingKey = 'receipt_style_section_spacing';
  static const _styleItemSpacingKey = 'receipt_style_item_spacing';
  static const _stylePreviewHeightKey = 'receipt_style_preview_height';
  static const _styleStoreNamePrintSizeKey = 'receipt_style_store_name_print_size';
  static const _styleStoreNameKey = 'receipt_style_store_name';
  static const _styleHeaderKey = 'receipt_style_header';
  static const _styleStoreAddressKey = 'receipt_style_store_address';
  static const _styleFooterKey = 'receipt_style_footer';
  static const _styleLogoPathKey = 'receipt_style_logo_path';

  static Future<void> loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final preset = prefs.getString(_stylePresetKey) ?? ReceiptStyle.compact.id;
    final storeName =
        prefs.getString(_styleStoreNameKey) ?? ReceiptStyle.compact.storeName;
    final logoPath = prefs.getString(_styleLogoPathKey);
    final headerLines = prefs.getStringList(_styleHeaderKey) ?? const <String>[];
    final storeAddressLines =
        prefs.getStringList(_styleStoreAddressKey) ??
        ReceiptStyle.compact.storeAddressLines;
    final footerLines =
        prefs.getStringList(_styleFooterKey) ?? ReceiptStyle.compact.footerLines;

    if (preset == ReceiptStyle.comfortable.id) {
      currentStyle = ReceiptStyle.comfortable.copyWith(
        storeName: storeName,
        headerLines: headerLines,
        storeAddressLines: storeAddressLines,
        footerLines: footerLines,
        logoPath: logoPath,
        storeNamePrintSize:
            prefs.getInt(_styleStoreNamePrintSizeKey) ??
            ReceiptStyle.comfortable.storeNamePrintSize,
      );
      return;
    }

    if (preset == ReceiptStyle.compact.id) {
      currentStyle = ReceiptStyle.compact.copyWith(
        storeName: storeName,
        headerLines: headerLines,
        storeAddressLines: storeAddressLines,
        footerLines: footerLines,
        logoPath: logoPath,
        storeNamePrintSize:
            prefs.getInt(_styleStoreNamePrintSizeKey) ??
            ReceiptStyle.compact.storeNamePrintSize,
      );
      return;
    }

    currentStyle = ReceiptStyle(
      id: 'custom',
      headerSpacing: prefs.getInt(_styleHeaderSpacingKey) ?? 1,
      sectionSpacing: prefs.getInt(_styleSectionSpacingKey) ?? 0,
      itemSpacing: prefs.getInt(_styleItemSpacingKey) ?? 0,
      previewLineHeight: prefs.getDouble(_stylePreviewHeightKey) ?? 1.28,
      storeNamePrintSize: prefs.getInt(_styleStoreNamePrintSizeKey) ?? 2,
      storeName: storeName,
      headerLines: headerLines,
      storeAddressLines: storeAddressLines,
      footerLines: footerLines,
      logoPath: logoPath,
    );
  }

  static Future<void> saveStyle(ReceiptStyle style) async {
    currentStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stylePresetKey, style.id);
    await prefs.setInt(_styleHeaderSpacingKey, style.headerSpacing);
    await prefs.setInt(_styleSectionSpacingKey, style.sectionSpacing);
    await prefs.setInt(_styleItemSpacingKey, style.itemSpacing);
    await prefs.setDouble(_stylePreviewHeightKey, style.previewLineHeight);
    await prefs.setInt(_styleStoreNamePrintSizeKey, style.storeNamePrintSize);
    await prefs.setString(_styleStoreNameKey, style.storeName);
    await prefs.setStringList(_styleHeaderKey, style.headerLines);
    await prefs.setStringList(_styleStoreAddressKey, style.storeAddressLines);
    await prefs.setStringList(_styleFooterKey, style.footerLines);
    if (style.logoPath == null || style.logoPath!.isEmpty) {
      await prefs.remove(_styleLogoPathKey);
    } else {
      await prefs.setString(_styleLogoPathKey, style.logoPath!);
    }
  }

  static String formatRupiah(int amount) {
    final format = NumberFormat('#,###', 'id_ID');
    return 'Rp ${format.format(amount)}';
  }

  static String line({ReceiptStyle? style}) =>
      '=' * (style ?? currentStyle).lineWidth;

  static String formatLine(String left, String right, {ReceiptStyle? style}) {
    final effectiveStyle = style ?? currentStyle;
    if (left.length + right.length >= effectiveStyle.lineWidth) {
      return '$left $right';
    }

    final space = effectiveStyle.lineWidth - (left.length + right.length);
    return left + (' ' * space) + right;
  }

  static String center(String text, {ReceiptStyle? style}) {
    final effectiveStyle = style ?? currentStyle;
    if (text.length >= effectiveStyle.lineWidth) return text;

    final space = (effectiveStyle.lineWidth - text.length) ~/ 2;
    return (' ' * space) + text;
  }

  static double previewStoreNameFontSize({ReceiptStyle? style}) {
    switch ((style ?? currentStyle).storeNamePrintSize) {
      case 1:
        return 20;
      case 2:
        return 24;
      case 3:
        return 30;
      default:
        return 24;
    }
  }

  static String formatItem(
    String name,
    int qty,
    int price, {
    ReceiptStyle? style,
  }) {
    final effectiveStyle = style ?? currentStyle;
    final subtotal = qty * price;
    final priceStr = formatRupiah(price).replaceAll('Rp ', '');
    final subtotalStr = formatRupiah(subtotal).replaceAll('Rp ', '');

    return '$name\n${formatLine('$qty x $priceStr', subtotalStr, style: effectiveStyle)}';
  }

  static String buildReceiptText({
    required int transaksiId,
    required DateTime dateTime,
    required String method,
    required int total,
    required int paid,
    required List<Map<String, dynamic>> items,
    ReceiptStyle? style,
    bool includeStoreName = true,
  }) {
    final effectiveStyle = style ?? currentStyle;
    final change = paid - total;
    final formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
    final time = DateFormat('HH:mm').format(dateTime);
    final buffer = StringBuffer();

    void writeBlankLines(int count) {
      for (var i = 0; i < count; i++) {
        buffer.writeln();
      }
    }

    if (includeStoreName) {
      buffer.writeln(
        center(effectiveStyle.storeName.toUpperCase(), style: effectiveStyle),
      );
      writeBlankLines(effectiveStyle.headerSpacing);
    }
    for (final lineText in effectiveStyle.headerLines) {
      buffer.writeln(center(lineText, style: effectiveStyle));
    }
    if (effectiveStyle.headerLines.isNotEmpty &&
        effectiveStyle.storeAddressLines.isNotEmpty) {
      buffer.writeln();
    }
    for (final lineText in effectiveStyle.storeAddressLines) {
      buffer.writeln(center(lineText, style: effectiveStyle));
    }

    writeBlankLines(effectiveStyle.sectionSpacing);
    buffer.writeln(line(style: effectiveStyle));
    writeBlankLines(effectiveStyle.sectionSpacing);
    buffer.writeln(
      formatLine('Tanggal', formattedDate, style: effectiveStyle),
    );
    buffer.writeln(formatLine('Jam', time, style: effectiveStyle));
    buffer.writeln(formatLine('Metode', method, style: effectiveStyle));

    writeBlankLines(effectiveStyle.sectionSpacing);
    buffer.writeln(line(style: effectiveStyle));
    writeBlankLines(effectiveStyle.sectionSpacing);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final qty = (item['qty'] ?? 0) as int;
      final price = (item['price'] ?? 0) as int;
      buffer.writeln(
        formatItem(
          item['name'].toString(),
          qty,
          price,
          style: effectiveStyle,
        ),
      );

      if (i < items.length - 1) {
        writeBlankLines(effectiveStyle.itemSpacing);
      }
    }

    writeBlankLines(effectiveStyle.sectionSpacing);
    buffer.writeln(line(style: effectiveStyle));
    writeBlankLines(effectiveStyle.sectionSpacing);
    buffer.writeln(
      formatLine(
        'TOTAL',
        formatRupiah(total).replaceAll('Rp ', ''),
        style: effectiveStyle,
      ),
    );
    buffer.writeln(
      formatLine(
        'BAYAR',
        formatRupiah(paid).replaceAll('Rp ', ''),
        style: effectiveStyle,
      ),
    );
    buffer.writeln(
      formatLine(
        'KEMBALI',
        formatRupiah(change < 0 ? 0 : change).replaceAll('Rp ', ''),
        style: effectiveStyle,
      ),
    );

    writeBlankLines(effectiveStyle.sectionSpacing);
    buffer.writeln(line(style: effectiveStyle));
    writeBlankLines(effectiveStyle.sectionSpacing);

    for (final footerLine in effectiveStyle.footerLines) {
      buffer.writeln(center(footerLine, style: effectiveStyle));
    }

    return buffer.toString().trimRight();
  }
}
