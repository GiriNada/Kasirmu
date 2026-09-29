import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/export_service.dart';
import '../report/transaction_detail_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime selectedDate = DateTime.now();
  int totalPenjualan = 0;
  int totalTransaksi = 0;
  List<Map<String, dynamic>> transaksi = [];
  List<Map<String, dynamic>> menuTerjual = [];
  List<Map<String, dynamic>> menuTidakLaku = [];
  bool _isLoading = false;
  bool _isExporting = false;
  int _reportRequestId = 0;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    final requestId = ++_reportRequestId;
    final date = DateFormat('yyyy-MM-dd').format(selectedDate);
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final results = await Future.wait<dynamic>([
      DatabaseHelper.instance.getTotalPenjualanByDate(date),
      DatabaseHelper.instance.getTotalTransaksiByDate(date),
      DatabaseHelper.instance.getTransaksiByDate(date),
      DatabaseHelper.instance.getMenuTerjual(date),
      DatabaseHelper.instance.getMenuTidakLaku(date),
    ]);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harian'),
        actions: [
          TextButton.icon(
            onPressed: _isExporting ? null : _exportReport,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            label: const Text('Export', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== PILIH TANGGAL =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Pilih Tanggal'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      loadReport();
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(),
          Row(
            children: [
              // ================= MENU TERJUAL =================
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(left: 12, right: 6, top: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.bar_chart, color: Colors.green),
                        title: Text(
                          "Menu Terjual",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      SizedBox(
                        height: 150,
                        child:
                            menuTerjual.isEmpty
                                ? const Center(
                                  child: Text(
                                    "Belum ada\npenjualan",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: menuTerjual.length,
                                  itemBuilder: (context, index) {
                                    final menu = menuTerjual[index];

                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        menu['name'],
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "${menu['total_qty']}x",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= MENU TIDAK LAKU =================
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(left: 6, right: 12, top: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.trending_down, color: Colors.red),
                        title: Text(
                          "Tidak Laku",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      SizedBox(
                        height: 150,
                        child:
                            menuTidakLaku.isEmpty
                                ? const Center(
                                  child: Text(
                                    "Semua menu\nterjual 🎉",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: menuTidakLaku.length,
                                  itemBuilder: (context, index) {
                                    final menu = menuTidakLaku[index];

                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        menu['name'],
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          "0x",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ===== SUMMARY =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _summaryBox(
                  title: 'Transaksi',
                  value: totalTransaksi.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _summaryBox(
                  title: 'Penjualan',
                  value: 'Rp $totalPenjualan',
                  icon: Icons.payments,
                  color: Colors.green,
                ),
              ],
            ),
          ),

          const Divider(),

          // ===== LIST TRANSAKSI =====
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transaksi.isEmpty
                    ? const Center(child: Text('Tidak ada transaksi'))
                    : ListView.builder(
                      itemCount: transaksi.length,
                      itemBuilder: (_, i) {
                        final t = transaksi[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.receipt),
                            title: Text(
                              '#${t['id']} • Rp ${t['total']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(t['payment_method']),
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
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(title),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
        periodLabel: DateFormat('dd MMM yyyy').format(selectedDate),
        periodType: 'harian',
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
}
