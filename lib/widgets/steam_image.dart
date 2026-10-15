import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/steam_service.dart';

/// Widget hiển thị ảnh Steam (Avatar, Game capsule, Icon)
/// Tự động vượt chặn DNS của nhà mạng Việt Nam thông qua DoH + Socket TLS SNI
class SteamImage extends StatefulWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const SteamImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  State<SteamImage> createState() => _SteamImageState();
}

class _SteamImageState extends State<SteamImage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant SteamImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadImage();
    }
  }

  void _loadImage() async {
    if (widget.url == null || widget.url!.trim().isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final bytes = await SteamService.fetchImageBytes(widget.url!);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null && _bytes!.isNotEmpty) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    if (!_loading && widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFF1F2937),
          child: const Icon(
            Icons.sports_esports,
            size: 16,
            color: Colors.white54,
          ),
        );
  }
}
