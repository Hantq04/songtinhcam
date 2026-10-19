import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/steam_models.dart';
import '../utils/steam_formatters.dart';
import '../widgets/steam_image.dart';
import '../widgets/steam_top_nav_bar.dart';

class SteamGameDetailScreen extends StatefulWidget {
  final SteamGameItem game;
  final String currencyName;
  final String? profileName;
  final String? avatarUrl;

  const SteamGameDetailScreen({
    super.key,
    required this.game,
    required this.currencyName,
    this.profileName,
    this.avatarUrl,
  });

  @override
  State<SteamGameDetailScreen> createState() => _SteamGameDetailScreenState();
}

class _SteamGameDetailScreenState extends State<SteamGameDetailScreen> {
  late String _status;
  final GlobalKey _statusButtonKey = GlobalKey();
  final TextEditingController _commentController = TextEditingController();
  String _activeActivityTab = 'Comments';

  @override
  void initState() {
    super.initState();
    _status = widget.game.status.isNotEmpty ? widget.game.status : 'Affectionless';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _setStatus(String newStatus) {
    setState(() {
      _status = newStatus;
      widget.game.status = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2838),
        content: Text(
          'Game status updated to: $newStatus',
          style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Droplist menu: Only 3 statuses (Affectionless, InProgress, Done) styled matching the project
  void _showStatusMenu() {
    final RenderBox? button =
        _statusButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: const Color(0xFF141C28),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF223044), width: 1.2),
      ),
      items: [
        // 1. Affectionless
        _buildStatusMenuItem(
          value: 'Affectionless',
          badgeText: 'Affectionless',
          badgeBg: const Color(0xFF1E2838),
          badgeBorder: const Color(0xFF334155),
          badgeTextColor: const Color(0xFF94A3B8),
          isSelected: _status == 'Affectionless',
        ),

        // 2. InProgress
        _buildStatusMenuItem(
          value: 'InProgress',
          badgeText: 'InProgress',
          badgeBg: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
          badgeBorder: const Color(0xFF2563EB),
          badgeTextColor: const Color(0xFF93C5FD),
          isSelected: _status == 'InProgress',
        ),

        // 3. Done
        _buildStatusMenuItem(
          value: 'Done',
          badgeText: 'Done',
          badgeBg: const Color(0xFF14532D).withValues(alpha: 0.35),
          badgeBorder: const Color(0xFF16A34A),
          badgeTextColor: const Color(0xFF86EFAC),
          isSelected: _status == 'Done',
        ),
      ],
    ).then((selected) {
      if (selected != null) {
        _setStatus(selected);
      }
    });
  }

  PopupMenuItem<String> _buildStatusMenuItem({
    required String value,
    required String badgeText,
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeTextColor,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      padding: EdgeInsets.zero,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2838) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: badgeBorder, width: 1),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 16,
                color: Color(0xFF38BDF8),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F141D);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Bar synchronized with other screens
            SteamTopNavBar(
              isMobile: isMobile,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 40.0,
                  vertical: 20.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Breadcrumbs row
                        _buildBreadcrumbRow(),
                        const SizedBox(height: 16),

                        // 1. Hero Card: Game Banner + Title + Status Button
                        _buildHeroGameCard(isMobile),
                        const SizedBox(height: 18),

                        // 2. Price & Information Card (Giá gốc, Giá đang giảm + %, Start date để trống)
                        _buildPriceAndInfoCard(isMobile),
                        const SizedBox(height: 18),

                        // 3. Activity Card (All, Comments, History, Work log - activity để trống)
                        _buildActivityCard(),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Breadcrumb Header: Steam Calculator / `ProfileName` / `GameName`
  Widget _buildBreadcrumbRow() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 2),
              Text(
                'Library',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text('/', style: TextStyle(color: Color(0xFF4B5563))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.game.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// 1. Hero Game Card: Banner, Name, App ID, Status Button
  Widget _buildHeroGameCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game capsule banner if available
          if (widget.game.logoUrl != null && widget.game.logoUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SteamImage(
                url: widget.game.logoUrl,
                height: isMobile ? 120 : 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: Container(
                  height: 100,
                  color: const Color(0xFF1E2838),
                  child: const Center(
                    child: Icon(Icons.sports_esports, color: Color(0xFF64748B), size: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Title & Status Row (Responsive)
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusDropdownButton(),
                        const Spacer(),
                        _buildSteamStoreLink(),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.game.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'App ID: ${widget.game.appId}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildStatusDropdownButton(),
                    const SizedBox(width: 12),
                    _buildSteamStoreLink(),
                  ],
                ),
        ],
      ),
    );
  }

  /// Status Dropdown Pill Button (Affectionless / InProgress / Done)
  Widget _buildStatusDropdownButton() {
    Color bg;
    Color border;
    Color textColor;

    switch (_status) {
      case 'Done':
        bg = const Color(0xFF14532D);
        border = const Color(0xFF16A34A);
        textColor = const Color(0xFF86EFAC);
        break;
      case 'InProgress':
        bg = const Color(0xFF1E3A8A);
        border = const Color(0xFF2563EB);
        textColor = const Color(0xFF93C5FD);
        break;
      case 'Affectionless':
      default:
        bg = const Color(0xFF1E2838);
        border = const Color(0xFF334155);
        textColor = const Color(0xFF94A3B8);
        break;
    }

    return InkWell(
      key: _statusButtonKey,
      onTap: _showStatusMenu,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _status,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSteamStoreLink() {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.game.storeUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF182030),
            content: Text(
              'Store link copied to clipboard!',
              style: TextStyle(color: Color(0xFF60A5FA)),
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2838),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2E3E55)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new, size: 14, color: Color(0xFF93C5FD)),
            SizedBox(width: 6),
            Text(
              'Steam Store',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Price and Info Card:
  /// - Giá gốc
  /// - Giá đang giảm nếu có kèm % giảm
  /// - Start date để trống
  /// - Playtime
  Widget _buildPriceAndInfoCard(bool isMobile) {
    final isDiscounted = widget.game.discountPercent > 0;
    final isFree = widget.game.isFree;

    // Giá gốc
    final originalPriceStr = _getOriginalPriceText();

    // Giá đang giảm (hoặc giá hiện tại)
    final currentPriceStr = widget.game.finalPriceFormatted ??
        (widget.game.finalPrice != null
            ? SteamFormatters.formatAmount(widget.game.finalPrice!, widget.currencyName)
            : (isFree ? 'Miễn phí (Free)' : '—'));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin game',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid / List of details
          _buildDetailRow(
            label: 'Giá gốc',
            valueWidget: Text(
              originalPriceStr,
              style: TextStyle(
                color: isDiscounted ? const Color(0xFF64748B) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: isDiscounted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1E2838), height: 16),

          _buildDetailRow(
            label: 'Giá đang giảm',
            valueWidget: isFree
                ? const Text(
                    'Miễn phí (Free)',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentPriceStr,
                        style: TextStyle(
                          color: isDiscounted ? const Color(0xFF60A5FA) : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isDiscounted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4C6B22),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '-${widget.game.discountPercent}%',
                            style: const TextStyle(
                              color: Color(0xFFBEEE11),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const Divider(color: Color(0xFF1E2838), height: 16),

          if (isDiscounted) ...[
            _buildDetailRow(
              label: '% Giảm giá',
              valueWidget: Text(
                '-${widget.game.discountPercent}%',
                style: const TextStyle(
                  color: Color(0xFFBEEE11),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Color(0xFF1E2838), height: 16),
          ],

          // Start date (để trống)
          _buildDetailRow(
            label: 'Start date',
            valueWidget: const Text(
              'Add date',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1E2838), height: 16),

          // Playtime
          _buildDetailRow(
            label: 'Hours on record',
            valueWidget: Text(
              '${widget.game.playtimeHours.toStringAsFixed(1)}h',
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getOriginalPriceText() {
    if (widget.game.isFree) return 'Miễn phí (Free)';
    if (widget.game.initialPriceFormatted != null &&
        widget.game.initialPriceFormatted!.isNotEmpty) {
      return widget.game.initialPriceFormatted!;
    }
    if (widget.game.initialPrice != null && widget.game.initialPrice! > 0) {
      return SteamFormatters.formatAmount(
          widget.game.initialPrice!, widget.currencyName);
    }
    if (widget.game.finalPriceFormatted != null &&
        widget.game.finalPriceFormatted!.isNotEmpty) {
      return widget.game.finalPriceFormatted!;
    }
    return '0 ₫';
  }

  Widget _buildDetailRow({required String label, required Widget valueWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8F9DAE),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        valueWidget,
      ],
    );
  }

  /// 3. Activity Card: Tabs (All, Comments, History, Work log), Comment Box, Activity để trống
  Widget _buildActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Filter tabs: All, Comments, History, Work log
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActivityTab('All'),
                const SizedBox(width: 8),
                _buildActivityTab('Comments'),
                const SizedBox(width: 8),
                _buildActivityTab('History'),
                const SizedBox(width: 8),
                _buildActivityTab('Work log'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Comment box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A3BF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'NH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF182232),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A3A50)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _commentController,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildQuickPromptChip('Can I get more info...?'),
                          _buildQuickPromptChip('Status update...'),
                          _buildQuickPromptChip('Thanks...'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pro tip
          const Padding(
            padding: EdgeInsets.only(left: 44),
            child: Text(
              'Pro tip: press M to comment',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),

          // Activity content is left empty as requested ("activity để trống")
        ],
      ),
    );
  }

  Widget _buildActivityTab(String title) {
    final isActive = _activeActivityTab == title;
    return InkWell(
      onTap: () {
        setState(() {
          _activeActivityTab = title;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFF182232),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF26374D),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPromptChip(String text) {
    return InkWell(
      onTap: () {
        _commentController.text = text;
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF141C28),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF28384E)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
