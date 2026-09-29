import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database_helper.dart';
import '../../core/utils/receipt_helper.dart';
import '../menu/manage_menu_page.dart';
import '../menu/widgets/adaptive_menu_image.dart';
import '../payment/payment_page.dart';
import '../report/report_page1.dart';
import '../settings/settings_page.dart';
import '../transaction/cart_model.dart';
import 'menu_model.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);
  static const _successGreen = Color(0xFF16A34A);
  static const _dangerRed = Color(0xFFDC2626);
  static const _cartInitialSize = 0.16;
  static const _menuCardBorderRadius = 18.0;
  static const _menuImageDecodeSize = 420;
  static const _menuCardShadow = BoxShadow(
    color: Color(0x120F172A),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  final ValueNotifier<bool> _isCartCollapsedNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<List<CartModel>> _cartNotifier =
      ValueNotifier<List<CartModel>>([]);

  List<MenuModel> menus = [];
  String _storeName = ReceiptStyle.compact.storeName;
  ImageProvider? _storeLogoProvider;
  final Map<String, ImageProvider> _menuImageProviders = {};

  @override
  void initState() {
    super.initState();
    _loadStoreProfile();
    loadMenus();
  }

  @override
  void dispose() {
    _isCartCollapsedNotifier.dispose();
    _cartNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadStoreProfile() async {
    await ReceiptHelper.loadStyle();
    final logoPath = ReceiptHelper.currentStyle.logoPath;
    final hasValidLogo =
        logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync();
    if (!mounted) return;
    setState(() {
      _storeName = ReceiptHelper.currentStyle.storeName;
      _storeLogoProvider = hasValidLogo
          ? ResizeImage(
              FileImage(File(logoPath)),
              width: 160,
              height: 160,
            )
          : null;
    });
  }

  Future<void> loadMenus() async {
    final data = await DatabaseHelper.instance.getMenus();
    final loadedMenus = data.map((e) => MenuModel.fromMap(e)).toList();
    final nextProviders = <String, ImageProvider>{};
    for (final menu in loadedMenus) {
      if (menu.image.isNotEmpty && File(menu.image).existsSync()) {
        nextProviders[menu.image] = ResizeImage(
          FileImage(File(menu.image)),
          width: _menuImageDecodeSize,
          height: _menuImageDecodeSize,
        );
      }
    }

    setState(() {
      menus = loadedMenus;
      _menuImageProviders
        ..clear()
        ..addAll(nextProviders);
    });
  }

  void add(MenuModel menu) {
    final nextCart = List<CartModel>.from(_cartNotifier.value);
    final index = nextCart.indexWhere((item) => item.name == menu.name);
    if (index >= 0) {
      nextCart[index].qty++;
    } else {
      nextCart.add(CartModel(name: menu.name, price: menu.price));
    }
    _cartNotifier.value = nextCart;
  }

  void minus(CartModel item) {
    final nextCart = List<CartModel>.from(_cartNotifier.value);
    final index = nextCart.indexWhere((entry) => entry.name == item.name);
    if (index < 0) return;
    if (nextCart[index].qty > 1) {
      nextCart[index].qty--;
    } else {
      nextCart.removeAt(index);
    }
    _cartNotifier.value = nextCart;
  }

  void _increaseCartItem(CartModel item) {
    final nextCart = List<CartModel>.from(_cartNotifier.value);
    final index = nextCart.indexWhere((entry) => entry.name == item.name);
    if (index < 0) return;
    nextCart[index].qty++;
    _cartNotifier.value = nextCart;
  }

  void _clearCart() {
    if (_cartNotifier.value.isEmpty) return;
    _cartNotifier.value = [];
  }

  int _totalFor(List<CartModel> cart) {
    return cart.fold(0, (sum, item) => sum + item.total);
  }

  int _cartPortionsFor(List<CartModel> cart) {
    return cart.fold(0, (sum, item) => sum + item.qty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kasirmu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Kasir digital fleksibel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Kelola Menu',
          icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageMenuPage()),
            ).then((_) => loadMenus());
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
              await _loadStoreProfile();
            },
          ),
          IconButton(
            tooltip: 'Laporan',
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: menus.isEmpty ? _buildEmptyState() : _buildMenuGrid(),
              ),
            ],
          ),
          _buildCartPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kasirmu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<List<CartModel>>(
                  valueListenable: _cartNotifier,
                  builder: (context, cart, _) {
                    return Text(
                      '${menus.length} menu tersedia | ${cart.length} item di keranjang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_storeLogoProvider != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: _storeLogoProvider!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 12.0;
        const spacing = 12.0;
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 720 ? 3 : 2;
        final availableWidth =
            width - (horizontalPadding * 2) - (spacing * (crossAxisCount - 1));
        final cardWidth = availableWidth / crossAxisCount;
        final imageHeight = cardWidth;
        final estimatedHeight = imageHeight + 112;
        final childAspectRatio = (cardWidth / estimatedHeight).clamp(0.62, 0.78);

        return ValueListenableBuilder<List<CartModel>>(
          valueListenable: _cartNotifier,
          builder: (context, cart, _) {
            final cartQtyByName = <String, int>{
              for (final item in cart) item.name: item.qty,
            };

            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                MediaQuery.of(context).size.height * _cartInitialSize + 24,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: menus.length,
              itemBuilder: (_, index) {
                final menu = menus[index];
                final cartQty = cartQtyByName[menu.name] ?? 0;
                return _buildMenuCard(menu, cartQty);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMenuCard(MenuModel menu, int cartQty) {
    final hasCartQty = cartQty > 0;
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => add(menu),
          borderRadius: BorderRadius.circular(_menuCardBorderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_menuCardBorderRadius),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [_menuCardShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildMenuPhoto(menu)),
                        if (hasCartQty)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$cartQty di keranjang',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: Center(
                      child: Text(
                        menu.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFBBF7D0).withValues(alpha: 0.8),
                        ),
                      ),
                      child: Text(
                        'Rp ${_currencyFormat.format(menu.price)}',
                        style: const TextStyle(
                          color: _successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color:
                          hasCartQty
                              ? const Color(0xFFDCEBFF)
                              : const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            hasCartQty
                                ? const Color(0xFFBFDBFE)
                                : const Color(0xFFDCE7F7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasCartQty
                              ? Icons.add_shopping_cart_rounded
                              : Icons.add_rounded,
                          color: _primaryBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasCartQty ? 'Tambah lagi' : 'Tambahkan',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _primaryBlue,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuPhoto(MenuModel menu) {
    return AdaptiveMenuImage(
      imageProvider: _menuImageProviders[menu.image],
      cacheKey: menu.image.isEmpty ? null : menu.image,
      fallbackLabel: menu.name,
      borderRadius: BorderRadius.circular(_menuCardBorderRadius - 4),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).size.height * _cartInitialSize + 24,
        ),
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
                Icons.restaurant_menu_rounded,
                size: 42,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada menu tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan menu dulu supaya kasir bisa mulai transaksi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageMenuPage()),
                ).then((_) => loadMenus());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Menu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final shouldCollapse = notification.extent <= (_cartInitialSize + 0.02);
        if (_isCartCollapsedNotifier.value != shouldCollapse) {
          _isCartCollapsedNotifier.value = shouldCollapse;
        }
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: _cartInitialSize,
        minChildSize: _cartInitialSize,
        maxChildSize: 0.62,
        snap: false,
        builder: (context, scrollController) {
          return ValueListenableBuilder<List<CartModel>>(
            valueListenable: _cartNotifier,
            builder: (context, cart, _) {
              final total = _totalFor(cart);
              final cartPortions = _cartPortionsFor(cart);

              return RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ValueListenableBuilder<bool>(
                              valueListenable: _isCartCollapsedNotifier,
                              builder: (context, isCollapsed, child) {
                                return AnimatedSwitcher(
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
                                  child: isCollapsed
                                      ? _buildCollapsedCartSummary(
                                          cart,
                                          total,
                                          cartPortions,
                                        )
                                      : _buildExpandedCartHeader(cart),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              if (cart.isEmpty)
                SliverToBoxAdapter(child: _buildAnimatedEmptyCart())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = cart[index];
                      return _buildAnimatedCartItem(item, index);
                    }, childCount: cart.length),
                  ),
                  ),
                  SliverToBoxAdapter(
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Bayar',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        AnimatedSwitcher(
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
                                          child: Text(
                                            'Rp ${_currencyFormat.format(total)}',
                                            key: ValueKey(total),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (cart.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${cart.length} jenis',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: cart.isEmpty ? null : _goToPayment,
                                    child: const Text(
                                      'Lanjut ke Pembayaran',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: _dangerRed,
                                    ),
                                    onPressed: cart.isEmpty ? null : _clearCart,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAnimatedEmptyCart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.94, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 18),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: _surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: Colors.grey.shade400,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada item di keranjang',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap menu di atas untuk mulai transaksi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCartItem(CartModel item, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${item.name}-${item.qty}'),
      duration: Duration(milliseconds: 180 + (index * 35).clamp(0, 140)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.92, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    '${item.qty}x',
                    key: ValueKey('badge-${item.name}-${item.qty}'),
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_currencyFormat.format(item.price)} per item',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.remove_rounded,
                              color: _dangerRed,
                            ),
                            onPressed: () => minus(item),
                          ),
                        ),
                        Container(
                          width: 38,
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.18),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              '${item.qty}',
                              key: ValueKey('qty-${item.name}-${item.qty}'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.add_rounded,
                              color: _primaryBlue,
                            ),
                            onPressed: () => _increaseCartItem(item),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 86,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'Rp ${_currencyFormat.format(item.total)}',
                    key: ValueKey('total-${item.name}-${item.total}'),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedCartSummary(
    List<CartModel> cart,
    int total,
    int cartPortions,
  ) {
    return Container(
      key: const ValueKey('collapsed-cart-summary'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cart.isEmpty
                      ? 'Keranjang masih kosong'
                      : '${cart.length} item | $cartPortions porsi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_currencyFormat.format(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: cart.isEmpty ? null : _goToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primaryBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'Bayar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCartHeader(List<CartModel> cart) {
    return Container(
      key: const ValueKey('expanded-cart-header'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Keranjang',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${cart.length} item',
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tarik ke atas',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _goToPayment() async {
    final cart = _cartNotifier.value;
    if (cart.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          total: _totalFor(cart),
          items: cart.map((e) => e.toMap()).toList(),
        ),
      ),
    );
    if (!mounted) return;
    _clearCart();
  }
}
