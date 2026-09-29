import 'package:flutter/material.dart';

class AdaptiveMenuImage extends StatefulWidget {
  const AdaptiveMenuImage({
    super.key,
    required this.borderRadius,
    this.imageProvider,
    this.cacheKey,
    this.fallbackLabel,
    this.placeholderIcon = Icons.fastfood_rounded,
    this.placeholderSize = 42,
  });

  final BorderRadius borderRadius;
  final ImageProvider? imageProvider;
  final String? cacheKey;
  final String? fallbackLabel;
  final IconData placeholderIcon;
  final double placeholderSize;

  @override
  State<AdaptiveMenuImage> createState() => _AdaptiveMenuImageState();
}

class _AdaptiveMenuImageState extends State<AdaptiveMenuImage> {
  static final Map<String, double> _aspectRatioCache = {};
  static const _fallbackThemes = [
    (
      [Color(0xFFE0F2FE), Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
      Color(0xFF1E3A8A),
    ),
    (
      [Color(0xFFDCFCE7), Color(0xFFECFCCB), Color(0xFFFEF3C7)],
      Color(0xFF166534),
    ),
    (
      [Color(0xFFFCE7F3), Color(0xFFF3E8FF), Color(0xFFE0E7FF)],
      Color(0xFF9D174D),
    ),
    (
      [Color(0xFFFFEDD5), Color(0xFFFEF3C7), Color(0xFFFFF7ED)],
      Color(0xFF9A3412),
    ),
    (
      [Color(0xFFE0F7FA), Color(0xFFDCFCE7), Color(0xFFE6FFFA)],
      Color(0xFF0F766E),
    ),
    (
      [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFE0E7FF)],
      Color(0xFF334155),
    ),
  ];

  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  double? _aspectRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AdaptiveMenuImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveImage() {
    _removeImageListener();

    final provider = widget.imageProvider;
    if (provider == null) {
      if (_aspectRatio != null) {
        setState(() => _aspectRatio = null);
      }
      return;
    }

    final cacheKey = widget.cacheKey;
    if (cacheKey != null && _aspectRatioCache.containsKey(cacheKey)) {
      final cachedRatio = _aspectRatioCache[cacheKey]!;
      if (_aspectRatio != cachedRatio) {
        setState(() => _aspectRatio = cachedRatio);
      }
      return;
    }

    final stream = provider.resolve(createLocalImageConfiguration(context));
    _imageStream = stream;
    _imageListener = ImageStreamListener((info, _) {
      final ratio = info.image.width / info.image.height;
      final cacheKey = widget.cacheKey;
      if (cacheKey != null) {
        _aspectRatioCache[cacheKey] = ratio;
      }
      if (!mounted || _aspectRatio == ratio) return;
      setState(() => _aspectRatio = ratio);
    });
    stream.addListener(_imageListener!);
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  Alignment _imageAlignment() {
    final ratio = _aspectRatio;
    if (ratio == null) return const Alignment(0, -0.08);
    if (ratio < 0.85) return const Alignment(0, -0.22);
    if (ratio < 1.05) return const Alignment(0, -0.1);
    if (ratio > 1.7) return const Alignment(0, -0.02);
    return const Alignment(0, -0.06);
  }

  String _displayLabel() {
    final raw = widget.fallbackLabel?.trim() ?? '';
    return raw.replaceAll(RegExp(r'\s+'), ' ');
  }

  int _themeIndex(String label) {
    var hash = 0;
    for (final codeUnit in label.codeUnits) {
      hash = (hash + codeUnit) % _fallbackThemes.length;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = _displayLabel();
    final fallbackTheme = _fallbackThemes[_themeIndex(displayLabel)];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.hardEdge,
        child: widget.imageProvider == null
            ? displayLabel.isNotEmpty
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          fallbackTheme.$1[0],
                          fallbackTheme.$1[1],
                          fallbackTheme.$1[2].withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          displayLabel,
                          maxLines: 3,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.placeholderSize * 0.4,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: fallbackTheme.$2,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      widget.placeholderIcon,
                      size: widget.placeholderSize,
                      color: const Color(0xFF94A3B8),
                    ),
                  )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: widget.imageProvider!,
                    fit: BoxFit.cover,
                    alignment: _imageAlignment(),
                    filterQuality: FilterQuality.low,
                  ),
                ],
              ),
      ),
    );
  }
}
