import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/database/database_helper.dart';
import '../../core/printer/printer_service.dart';
import '../../core/utils/receipt_helper.dart';
import '../printer/printer_page.dart';
import '../receipt/receipt_page.dart';

class PaymentPage extends StatefulWidget {
  final int total;
  final List<Map<String, dynamic>> items;

  const PaymentPage({super.key, required this.total, required this.items});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);
  static const _successGreen = Color(0xFF16A34A);
  static const _dangerRed = Color(0xFFDC2626);

  final PrinterService printerService = PrinterService.instance;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  final TextEditingController _paidController = TextEditingController();

  String paymentMethod = 'Cash';
  int paidAmount = 0;
  bool _isSubmitting = false;

  bool get isTransfer => paymentMethod == 'Transfer';
  int get change => paidAmount - widget.total;
  bool get isPaidEnough => paidAmount >= widget.total;

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  void addQuickCash(int value) {
    setState(() {
      paidAmount = value;
      _syncPaidController();
    });
  }

  void adjustPaidAmount(int delta) {
    setState(() {
      final nextValue = paidAmount + delta;
      paidAmount = nextValue < 0 ? 0 : nextValue;
      _syncPaidController();
    });
  }

  void _syncPaidController() {
    _paidController.text =
        paidAmount == 0 ? '' : _currencyFormat.format(paidAmount);
    _paidController.selection = TextSelection.fromPosition(
      TextPosition(offset: _paidController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Printer',
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterPage()),
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionReveal(
                      delay: 0,
                      child: _buildTotalCard(),
                    ),
                    const SizedBox(height: 12),
                    _SectionReveal(
                      delay: 40,
                      child: _buildOrderSummary(),
                    ),
                    const SizedBox(height: 12),
                    _SectionReveal(
                      delay: 80,
                      child: _buildMethodSection(),
                    ),
                    const SizedBox(height: 12),
                    if (!isTransfer) ...[
                      _SectionReveal(
                        delay: 120,
                        child: _buildPaidInput(),
                      ),
                      const SizedBox(height: 12),
                      _SectionReveal(
                        delay: 160,
                        child: _buildQuickCashSection(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _SectionReveal(
                      delay: 200,
                      child: _buildChangeCard(),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaksi Aktif',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.items.length} item siap diproses',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rp ${_currencyFormat.format(widget.total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Total Bayar',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ReceiptHelper.formatRupiah(widget.total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...widget.items.map((item) {
            final qty = (item['qty'] ?? 0) as int;
            final price = (item['price'] ?? 0) as int;
            final subtotal = qty * price;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['name']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$qty x ${ReceiptHelper.formatRupiah(price)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ReceiptHelper.formatRupiah(subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMethodSection() {
    final methods = [
      (
        value: 'Cash',
        title: 'Cash',
        subtitle: 'Pembayaran tunai langsung',
        icon: Icons.payments_rounded,
        color: _successGreen,
      ),
      (
        value: 'Transfer',
        title: 'Transfer',
        subtitle: 'Transfer rekening / non-tunai',
        icon: Icons.account_balance_rounded,
        color: _primaryBlue,
      ),
    ];

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
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...methods.map(
            (method) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _paymentMethodTile(
                value: method.value,
                title: method.title,
                subtitle: method.subtitle,
                icon: method.icon,
                color: method.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidInput() {
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
          const Text(
            'Nominal Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _paidController,
            keyboardType: TextInputType.number,
            inputFormatters: [_CurrencyTextInputFormatter(_currencyFormat)],
            decoration: _inputDecoration(
              labelText: 'Uang dibayar',
              icon: Icons.payments_rounded,
              iconColor: _successGreen,
              prefixText: 'Rp ',
            ),
            onChanged: (value) {
              setState(() {
                final rawValue = value.replaceAll('.', '');
                paidAmount = int.tryParse(rawValue) ?? 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCashSection() {
    final quickValues = {
      5000,
      10000,
      15000,
      20000,
      25000,
      50000,
      75000,
      100000,
      widget.total,
      ((widget.total / 10000).ceil() * 10000),
      ((widget.total / 20000).ceil() * 20000),
      ((widget.total / 50000).ceil() * 50000),
    }.toList()
      ..sort();

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
          const Text(
            'Nominal Cepat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickValues.map(_quickButton).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Penyesuaian Cepat',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _adjustButton('-5rb', -5000),
              _adjustButton('+5rb', 5000),
              _adjustButton('+10rb', 10000),
              _adjustButton('+20rb', 20000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = paymentMethod == value;

    return _PressableScale(
      onTap: () {
        setState(() {
          paymentMethod = value;
          if (isTransfer) {
            paidAmount = widget.total;
            _syncPaidController();
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : _surfaceTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
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
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(
                    color: selected ? color : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeCard() {
    final enough = isPaidEnough;
    final title =
        isTransfer ? 'Transfer sesuai total' : (enough ? 'Kembalian' : 'Nominal Kurang');
    final amount = isTransfer
        ? widget.total
        : (enough ? change : widget.total - paidAmount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enough ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              enough
                  ? _successGreen.withValues(alpha: 0.18)
                  : _dangerRed.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enough
                  ? _successGreen.withValues(alpha: 0.12)
                  : _dangerRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              enough ? Icons.check_circle_outline : Icons.error_outline,
              color: enough ? _successGreen : _dangerRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey('$paymentMethod-$enough-$paidAmount'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enough ? _successGreen : _dangerRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ReceiptHelper.formatRupiah(amount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      isPaidEnough ? 'Siap dibayar' : 'Menunggu nominal cukup',
                      key: ValueKey(isPaidEnough),
                      style: TextStyle(
                        color: isPaidEnough ? _successGreen : _dangerRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPaidEnough ? _primaryBlue : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: isPaidEnough && !_isSubmitting ? _submitPayment : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Memproses...' : 'Bayar Sekarang',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    required Color iconColor,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
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

  Widget _quickButton(int value) {
    final selected = paidAmount == value;
    return AnimatedScale(
      scale: selected ? 1.02 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
          foregroundColor: selected ? _primaryBlue : const Color(0xFF334155),
          side: BorderSide(
            color: selected ? _primaryBlue : const Color(0xFFCBD5E1),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onPressed: () => addQuickCash(value),
        child: Text(
          ReceiptHelper.formatRupiah(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _adjustButton(String label, int delta) {
    final isNegative = delta < 0;
    final color = isNegative ? _dangerRed : _successGreen;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        backgroundColor: color.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () => adjustPaidAmount(delta),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final transactionDate = DateTime.now();
    final trxId = await DatabaseHelper.instance.insertTransaction(
      widget.total,
      widget.items,
      paymentMethod,
      paidAmount,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          transactionId: trxId,
          total: widget.total,
          paidAmount: paidAmount,
          paymentMethod: paymentMethod,
          date: transactionDate.toIso8601String(),
        ),
      ),
    );
  }
}

class _SectionReveal extends StatefulWidget {
  const _SectionReveal({
    required this.child,
    required this.delay,
  });

  final Widget child;
  final int delay;

  @override
  State<_SectionReveal> createState() => _SectionRevealState();
}

class _SectionRevealState extends State<_SectionReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.03),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
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
      scale: _pressed ? 0.985 : 1,
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

class _CurrencyTextInputFormatter extends TextInputFormatter {
  _CurrencyTextInputFormatter(this.formatter);

  final NumberFormat formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    final formatted = formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
