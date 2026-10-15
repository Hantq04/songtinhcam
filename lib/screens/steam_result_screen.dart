import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/steam_service.dart';
import '../utils/steam_formatters.dart';
import '../widgets/steam_top_nav_bar.dart';

class SteamResultScreen extends StatefulWidget {
  final SteamCalculationResult result;
  final String currencyName;

  const SteamResultScreen({
    super.key,
    required this.result,
    required this.currencyName,
  });

  @override
  State<SteamResultScreen> createState() => _SteamResultScreenState();
}

class _SteamResultScreenState extends State<SteamResultScreen> {
  late SteamCalculationResult _result;
  late String _currencyName;
  final TextEditingController _bottomInputController = TextEditingController();
  bool _isRecalculating = false;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
    _currencyName = widget.currencyName;
  }

  @override
  void dispose() {
    _bottomInputController.dispose();
    super.dispose();
  }

  void _recalculateAccount(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isRecalculating = true;
    });

    try {
      final newResult = await SteamService.calculateAccount(
        input: trimmed,
        currencyName: _currencyName,
      );

      if (!mounted) return;
      setState(() {
        _result = newResult;
        _isRecalculating = false;
        _bottomInputController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E2838),
          content: Text('Updated data for: ${_result.profileName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyShareLink() {
    final link = 'https://steamcommunity.com/profiles/${_result.steamId}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF182030),
        content: Text(
          'Profile link copied to clipboard!',
          style: TextStyle(color: Color(0xFF60A5FA)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
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
            SteamTopNavBar(
              isMobile: isMobile,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 40.0,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back navigation row
                        _buildBackHeader(),
                        const SizedBox(height: 16),

                        // 1. Hero Profile Banner (Avatar, Username, Level, Account Value)
                        _buildHeroProfileBanner(isMobile),
                        const SizedBox(height: 18),

                        // 2. Notice banner (Red warning if private, or blue info)
                        _buildNoticeBanner(),
                        const SizedBox(height: 20),

                        // 3. Dual Progress / Status Bars
                        _buildDualProgressBars(isMobile),
                        const SizedBox(height: 24),

                        // 4. SteamDB 5-Column Stats Grid
                        _buildSteamDbStatsGrid(isMobile),
                        const SizedBox(height: 32),

                        // 5. Games Library List (if games available)
                        if (_result.games.isNotEmpty) ...[
                          _buildGamesLibraryTable(),
                          const SizedBox(height: 36),
                        ],

                        // 6. Bottom Search Bar ("Want to calculate value of your own Steam account?")
                        _buildBottomSearchBox(),
                        const SizedBox(height: 48),
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

  Widget _buildBackHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: Color(0xFF38BDF8), size: 20),
              Text(
                'Steam Calculator',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '/',
          style: TextStyle(color: Color(0xFF4B5563)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_result.profileName} (${_result.steamId})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// 1. Hero Profile Banner (matches SteamDB screenshot)
  Widget _buildHeroProfileBanner(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileLeft(),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E2B3E), height: 1),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildProfileRight(),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProfileLeft()),
                const SizedBox(width: 24),
                _buildProfileRight(),
              ],
            ),
    );
  }

  Widget _buildProfileLeft() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with white/crisp border as in SteamDB screenshot
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SteamImage(
              url: _result.avatarUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 68,
                height: 68,
                color: const Color(0xFF1F2937),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // User info column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display name
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _result.profileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_result.realName != null &&
                      _result.realName!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '(${_result.realName})',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Badges row: Level, Years, Medal, Flag, Share
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Level circle badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2433),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3880FF), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Level ',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '${_result.steamLevel}',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badges count badge
                  if (_result.badgesCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162335),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2E466E)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.military_tech_outlined, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            '${_result.badgesCount} badges',
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Country flag / badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2433),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A3950)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 13, color: Color(0xFFFBBF24)),
                        SizedBox(width: 4),
                        Text(
                          'VN',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Share button
                  InkWell(
                    onTap: _copyShareLink,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2433),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A3950)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.ios_share, size: 13, color: Color(0xFF94A3B8)),
                          SizedBox(width: 4),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRight() {
    final hasValue = (_result.stats?.totalInitialPrice ?? 0) > 0 ||
        (_result.totalValue.isNotEmpty && _result.totalValue != '0 ₫' && _result.totalValue != '\$0.00' && _result.totalValue != 'Cần API Key');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Account Value',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasValue ? _result.totalValue : 'N/A',
          style: TextStyle(
            color: hasValue ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasValue ? "Today's prices: ${_result.lowestPrice}" : 'games are hidden',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// 2. Notice banner (Red warning if private, or blue confirmation)
  Widget _buildNoticeBanner() {
    final isHidden = _result.visibilityState != 3 && _result.games.isEmpty;

    if (isHidden) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B1D1D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDC2626)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Games are hidden by default on Steam, you can change your Steam profile privacy settings:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. From your Steam Profile, click the Edit Profile link under your displayed badge\n'
              '2. Click the My Privacy Settings tab\n'
              '3. Set Game details to Public\n'
              '4. Uncheck Always keep my total playtime private option',
              style: TextStyle(
                color: Color(0xFFFEE2E2),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'After changing your privacy settings, it may take some time for SteamDB to clear the cache and see new data.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF132032),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _result.statusNote ??
                  'Full data from Steam Web API & Steam Store API (scanned entire game library and current prices).',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Dual Progress / Status Bars (matches SteamDB screenshot)
  Widget _buildDualProgressBars(bool isMobile) {
    final gamesCount = _result.gamesOwned is int
        ? _result.gamesOwned as int
        : (_result.games.length);
    final calculatedCount = _result.stats?.gamesCountCalculated ?? _result.games.length;

    final gamesBar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '$gamesCount games owned',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                calculatedCount > 0 ? '$calculatedCount games calculated' : 'games are hidden',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: calculatedCount > 0 ? 1.0 : 0.0,
            backgroundColor: const Color(0xFF1E2838),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            minHeight: 8,
          ),
        ),
      ],
    );

    final xpBar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Level ${_result.steamLevel}  ·  XP to next level',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${_result.steamLevel * 100} XP',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0.78,
            backgroundColor: Color(0xFF1E2838),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
            minHeight: 8,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          gamesBar,
          const SizedBox(height: 16),
          xpBar,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: gamesBar),
        const SizedBox(width: 32),
        Expanded(child: xpBar),
      ],
    );
  }

  /// 4. SteamDB 5-Column Stats Grid (Average price, Price/hour, Hours, Playtime, Today's price)
  Widget _buildSteamDbStatsGrid(bool isMobile) {
    final gamesCount = _result.games.length;
    final totalHours = _result.stats?.totalPlaytimeHours ?? 0.0;
    final totalInitialPrice = _result.stats?.totalInitialPrice ?? 0;
    final avgPlaytimeStr = gamesCount > 0
        ? '${(totalHours / gamesCount).toStringAsFixed(1)}h'
        : 'Private';

    final avgPriceStr = gamesCount > 0 && totalInitialPrice > 0
        ? _formatAvgPrice(totalInitialPrice / gamesCount)
        : 'Private';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final colWidth = isNarrow
              ? (constraints.maxWidth - 20) / 2
              : 155.0;

          return Wrap(
            spacing: isNarrow ? 20 : 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildStatColumn('Average price ⓘ', avgPriceStr, Colors.white, width: colWidth),
              _buildStatColumn('Average price per hour ⓘ', _result.pricePerHour, const Color(0xFFFBBF24), width: colWidth),
              _buildStatColumn('Hours on record', _result.hoursPlayed, Colors.white, width: colWidth),
              _buildStatColumn('Average playtime', avgPlaytimeStr, Colors.white, width: colWidth),
              _buildStatColumn("⭐ Today's prices ⓘ", _result.lowestPrice, const Color(0xFF60A5FA), width: colWidth),
            ],
          );
        },
      ),
    );
  }

  String _formatAvgPrice(num amount) =>
      SteamFormatters.formatAmount(amount, _currencyName);

  Widget _buildStatColumn(String label, String value, Color valueColor, {double? width}) {
    return SizedBox(
      width: width ?? 155,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8F9DAE),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Top Games Table matching SteamDB
  Widget _buildGamesLibraryTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Games in library',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2838),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E3E55)),
              ),
              child: Text(
                '${_result.games.length} games',
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121926),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF223044)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _result.games.length > 50 ? 50 : _result.games.length,
            separatorBuilder: (_, _) => const Divider(
              color: Color(0xFF1B2533),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final game = _result.games[index];
              final isFree = game.isFree;
              final isDiscounted = game.discountPercent > 0;

              return Container(
                color: index.isEven ? const Color(0xFF121926) : const Color(0xFF0F1520),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF6B7E96),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Game capsule banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SteamImage(
                        url: game.logoUrl,
                        width: 64,
                        height: 28,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 64,
                          height: 28,
                          color: const Color(0xFF1F2937),
                          child: const Icon(Icons.sports_esports, size: 14, color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Game name
                    Expanded(
                      child: Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Playtime
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${game.playtimeHours.toStringAsFixed(1)}h',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Discount pill
                    if (isDiscounted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C6B22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '-${game.discountPercent}%',
                          style: const TextStyle(
                            color: Color(0xFFBEEE11),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Price
                    SizedBox(
                      width: 100,
                      child: Text(
                        game.finalPriceFormatted ?? (isFree ? 'Miễn phí' : '—'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isFree
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF60A5FA),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
    );
  }

  /// 6. Bottom Search Bar ("Want to calculate value of your own Steam account?")
  Widget _buildBottomSearchBox() {
    return Column(
      children: [
        const Text(
          'Want to calculate value of your own Steam account?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: BoxDecoration(
            color: const Color(0xFF141C28),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF26374D), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF6B7E96), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _bottomInputController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your profile url or steamid',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: _recalculateAccount,
                ),
              ),
              if (_isRecalculating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3880FF)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF3880FF), size: 20),
                  onPressed: () => _recalculateAccount(_bottomInputController.text),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
