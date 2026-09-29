import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/export_service.dart';
import '../../core/database/database_helper.dart';
import '../report/transaction_detail_page.dart';

enum PeriodeFilter { harian, mingguan, bulanan }

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  PeriodeFilter selectedPeriode = PeriodeFilter.harian;
  DateTime selectedDate = DateTime.now();

  int totalPenjualan = 0;
  int totalTransaksi = 0;
  List<Map<String, dynamic>> transaksi = [];
  List<Map<String, dynamic>> menuTerjual = [];
  List<Map<String, dynamic>> menuTidakLaku = [];
  bool _isLoading = false;
  int _reportRequestId = 0;

  late TabController _tabController;

  // Format currency
  final _currencyFormat = NumberFormat('#,###', 'id_ID');
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedPeriode = PeriodeFilter.values[_tabController.index];
        });
        loadReport();
      }
    });
    loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Hitung range tanggal berdasarkan periode
  // ─────────────────────────────────────────────
  (String, String) _getDateRange() {
    switch (selectedPeriode) {
      case PeriodeFilter.harian:
        final d = DateFormat('yyyy-MM-dd').format(selectedDate);
        return (d, d);
      case PeriodeFilter.mingguan:
        // Senin s.d. Minggu di minggu yang dipilih
        final weekday = selectedDate.weekday; // 1=Mon, 7=Sun
        final monday = selectedDate.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (
          DateFormat('yyyy-MM-dd').format(monday),
          DateFormat('yyyy-MM-dd').format(sunday),
        );
      case PeriodeFilter.bulanan:
        final first = DateTime(selectedDate.year, selectedDate.month, 1);
        final last = DateTime(selectedDate.year, selectedDate.month + 1, 0);
        return (
          DateFormat('yyyy-MM-dd').format(first),
          DateFormat('yyyy-MM-dd').format(last),
        );
    }
  }

  // Label periode yang tampil di header
  String _periodeLabel() {
    switch (selectedPeriode) {
      case PeriodeFilter.harian:
        return DateFormat('dd MMM yyyy').format(selectedDate);
      case PeriodeFilter.mingguan:
        final (start, end) = _getDateRange();
        final s = DateFormat('dd MMM').format(DateTime.parse(start));
        final e = DateFormat('dd MMM yyyy').format(DateTime.parse(end));
        return '$s – $e';
      case PeriodeFilter.bulanan:
        return DateFormat('MMMM yyyy').format(selectedDate);
    }
  }

  Future<void> loadReport() async {
    final requestId = ++_reportRequestId;
    final (startDate, endDate) = _getDateRange();
    if (mounted) {
      setState(() => _isLoading = true);
    }

    late final List<dynamic> results;
    if (selectedPeriode == PeriodeFilter.harian) {
      results = await Future.wait<dynamic>([
        DatabaseHelper.instance.getTotalPenjualanByDate(startDate),
        DatabaseHelper.instance.getTotalTransaksiByDate(startDate),
        DatabaseHelper.instance.getTransaksiByDate(startDate),
        DatabaseHelper.instance.getMenuTerjual(startDate),
        DatabaseHelper.instance.getMenuTidakLaku(startDate),
      ]);
    } else {
      results = await Future.wait<dynamic>([
        DatabaseHelper.instance.getTotalPenjualanByRange(startDate, endDate),
        DatabaseHelper.instance.getTotalTransaksiByRange(startDate, endDate),
        DatabaseHelper.instance.getTransaksiByRange(startDate, endDate),
        DatabaseHelper.instance.getMenuTerjualByRange(startDate, endDate),
        DatabaseHelper.instance.getMenuTidakLakuByRange(startDate, endDate),
      ]);
    }

    if (!mounted || requestId != _reportRequestId) return;

    setState(() {
      _isLoading = false;
      totalPenjualan = results[0] as int;
      totalTransaksi = results[1] as int;
      transaksi = List<Map<String, dynamic>>.from(results[2] as List);
      menuTerjual = List<Map<String, dynamic>>.from(results[3] as List);
      menuTidakLaku = List<Map<String, dynamic>>.from(results[4] as List);
    });
  }

  // ─────────────────────────────────────────────
  // Date Picker sesuai periode
  // ─────────────────────────────────────────────
  Future<void> _pickDate() async {
    if (selectedPeriode == PeriodeFilter.bulanan) {
      // Pilih bulan
      await _showMonthPicker();
    } else {
      // Pilih tanggal (harian & mingguan)
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2023),
        lastDate: DateTime.now(),
        helpText:
            selectedPeriode == PeriodeFilter.mingguan
                ? 'Pilih tanggal dalam minggu'
                : 'Pilih tanggal',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF2563EB),
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => selectedDate = picked);
        loadReport();
      }
    }
  }

  Future<void> _showMonthPicker() async {
    int tempYear = selectedDate.year;
    int tempMonth = selectedDate.month;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setInner) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setInner(() => tempYear--),
                      ),
                      Text(
                        '$tempYear',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          if (tempYear < DateTime.now().year) {
                            setInner(() => tempYear++);
                          }
                        },
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 280,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (_, i) {
                        final month = i + 1;
                        final isSelected = month == tempMonth;
                        final isFuture = DateTime(
                          tempYear,
                          month,
                        ).isAfter(DateTime.now());
                        return GestureDetector(
                          onTap:
                              isFuture
                                  ? null
                                  : () {
                                    setInner(() => tempMonth = month);
                                  },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF2563EB)
                                      : isFuture
                                      ? Colors.grey.shade100
                                      : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormat(
                                'MMM',
                              ).format(DateTime(tempYear, month)),
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : isFuture
                                        ? Colors.grey.shade400
                                        : const Color(0xFF2563EB),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(
                          () => selectedDate = DateTime(tempYear, tempMonth, 1),
                        );
                        Navigator.pop(context);
                        loadReport();
                      },
                      child: const Text('Pilih'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB),
        title: const Text(
          'Laporan Penjualan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: _isExporting ? null : _exportReport,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download_outlined, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── HEADER PERIODE ───
          _buildPeriodeHeader(),

          // ─── SUMMARY CARDS ───
          _buildSummaryCards(),

          // ─── MENU TERJUAL & TIDAK LAKU ───
          _buildMenuSection(),

          const Divider(height: 1),

          // ─── LIST TRANSAKSI ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Daftar Transaksi ($totalTransaksi)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildTransaksiList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildPeriodeHeader() {
    return Container(
      color: const Color(0xFF2563EB),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Periode',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _periodeLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.calendar_month, size: 16),
            label: Text(
              selectedPeriode == PeriodeFilter.bulanan
                  ? 'Pilih Bulan'
                  : 'Pilih Tanggal',
              style: const TextStyle(fontSize: 13),
            ),
            onPressed: _pickDate,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          _summaryCard(
            key: ValueKey('trx-$totalTransaksi'),
            label: 'Total Transaksi',
            value: '$totalTransaksi',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 10),
          _summaryCard(
            key: ValueKey('sales-$totalPenjualan'),
            label: 'Total Penjualan',
            value: 'Rp ${_currencyFormat.format(totalPenjualan)}',
            icon: Icons.payments_rounded,
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFF0FDF4),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    Key? key,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        key: key,
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

  // ─────────────────────────────────────────────
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _menuCard(
            title: 'Menu Terjual',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF16A34A),
            items: menuTerjual,
            emptyText: 'Belum ada\npenjualan',
            badgeColor: const Color(0xFF16A34A),
            badgeBg: const Color(0xFFDCFCE7),
            trailingBuilder: (menu) => '${menu['total_qty']}x',
          ),
          const SizedBox(width: 10),
          _menuCard(
            title: 'Tidak Laku',
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFFDC2626),
            items: menuTidakLaku,
            emptyText: 'Semua menu\nterjual 🎉',
            badgeColor: const Color(0xFFDC2626),
            badgeBg: const Color(0xFFFEE2E2),
            trailingBuilder: (_) => '0x',
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> items,
    required String emptyText,
    required Color badgeColor,
    required Color badgeBg,
    required String Function(Map<String, dynamic>) trailingBuilder,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            SizedBox(
              height: 140,
              child:
                  items.isEmpty
                      ? Center(
                        child: Text(
                          emptyText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final menu = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    menu['name'],
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    trailingBuilder(menu),
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildTransaksiList() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (transaksi.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('list-${transaksi.length}-${_periodeLabel()}'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: transaksi.length,
      itemBuilder: (_, i) {
        final t = transaksi[i];

        // Parsing tanggal dari field 'created_at' atau 'date'
        // Sesuaikan nama field dengan kolom di database kamu
        String tanggalLabel = '';
        try {
          final rawDate = t['created_at'] ?? t['date'] ?? t['tanggal'] ?? '';
          if (rawDate.toString().isNotEmpty) {
            final dt = DateTime.parse(rawDate.toString());
            tanggalLabel = DateFormat('dd MMM yyyy, HH:mm').format(dt);
          }
        } catch (_) {}

        // Badge warna berdasarkan payment method
        final pm = (t['payment_method'] ?? '').toString().toLowerCase();
        final pmColor =
            pm.contains('cash')
                ? const Color(0xFF16A34A)
                : pm.contains('qris') || pm.contains('transfer')
                ? const Color(0xFF2563EB)
                : const Color(0xFF7C3AED);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 180 + (i * 25)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _PressableScale(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => TransactionDetailPage(
                        transaksiId: t['id'],
                        total: t['total'],
                      ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            title: Text(
              '#${t['id']} • Rp ${_currencyFormat.format(t['total'])}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Tanggal
                if (tanggalLabel.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tanggalLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                // Payment method badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pmColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t['payment_method'] ?? '-',
                    style: TextStyle(
                      color: pmColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportReport() async {
    if (_isExporting || transaksi.isEmpty) {
      if (transaksi.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diexport')),
        );
      }
      return;
    }

    setState(() => _isExporting = true);

    try {
      final file = await ExportService.exportReportXlsx(
        periodLabel: _periodeLabel(),
        periodType: _periodeTypeLabel(),
        totalPenjualan: totalPenjualan,
        totalTransaksi: totalTransaksi,
        transaksi: transaksi,
        menuTerjual: menuTerjual,
        menuTidakLaku: menuTidakLaku,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            file == null
                ? 'Export XLSX gagal dibuat'
                : 'Export XLSX berhasil',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat export XLSX')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _periodeTypeLabel() {
    switch (selectedPeriode) {
      case PeriodeFilter.harian:
        return 'harian';
      case PeriodeFilter.mingguan:
        return 'mingguan';
      case PeriodeFilter.bulanan:
        return 'bulanan';
    }
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    required this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.988 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            if (_pressed != value) {
              setState(() => _pressed = value);
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}
