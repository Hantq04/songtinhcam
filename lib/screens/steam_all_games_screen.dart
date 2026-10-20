import 'package:flutter/material.dart';
import '../models/steam_models.dart';
import '../widgets/steam_image.dart';
import '../widgets/steam_top_nav_bar.dart';
import 'steam_game_detail_screen.dart';

class SteamAllGamesScreen extends StatefulWidget {
  final List<SteamGameItem> games;
  final String currencyName;
  final String? profileName;

  const SteamAllGamesScreen({
    super.key,
    required this.games,
    required this.currencyName,
    this.profileName,
  });

  @override
  State<SteamAllGamesScreen> createState() => _SteamAllGamesScreenState();
}

class _SteamAllGamesScreenState extends State<SteamAllGamesScreen> {
  final int _pageSize = 50;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SteamGameItem> get _filteredGames {
    if (_searchQuery.trim().isEmpty) {
      return widget.games;
    }
    final q = _searchQuery.toLowerCase();
    return widget.games.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  int get _totalPages {
    final total = _filteredGames.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _pageSize) + 1;
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    // Scroll to top of table
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _openGameDetail(SteamGameItem game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SteamGameDetailScreen(
          game: game,
          currencyName: widget.currencyName,
          profileName: widget.profileName,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F141D);
    final isMobile = MediaQuery.of(context).size.width < 768;
    final filtered = _filteredGames;
    final totalGames = filtered.length;
    final totalPages = _totalPages;

    // Adjust page if search reduced total pages
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (totalGames == 0) ? 0 : (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize > totalGames)
        ? totalGames
        : startIndex + _pageSize;
    final pageGames = (totalGames == 0)
        ? <SteamGameItem>[]
        : filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Bar
            SteamTopNavBar(
              isMobile: isMobile,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
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
                        // Breadcrumbs
                        _buildBreadcrumbs(),
                        const SizedBox(height: 16),

                        // Header Bar: Title, Search, Total Count
                        _buildHeader(totalGames, isMobile),
                        const SizedBox(height: 16),

                        // Games Table
                        _buildGamesTable(pageGames, startIndex),
                        const SizedBox(height: 20),

                        // Pagination Bar with < > and Page Numbers
                        if (totalPages > 1) ...[
                          _buildPaginationBar(totalPages, startIndex, endIndex, totalGames),
                          const SizedBox(height: 36),
                        ],
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

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: Color(0xFF38BDF8), size: 20),
              Text(
                'Result',
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
        const Text('/', style: TextStyle(color: Color(0xFF4B5563))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.profileName != null
                ? '${widget.profileName} / All Games'
                : 'All Games',
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

  Widget _buildHeader(int totalGames, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Games in Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildCountPill(totalGames),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchInput(),
              ],
            )
          : Row(
              children: [
                const Text(
                  'All Games in Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                _buildCountPill(totalGames),
                const Spacer(),
                SizedBox(
                  width: 260,
                  child: _buildSearchInput(),
                ),
              ],
            ),
    );
  }

  Widget _buildCountPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2838),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E3E55)),
      ),
      child: Text(
        '$count games',
        style: const TextStyle(
          color: Color(0xFF93C5FD),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF0F141D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF26374D)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Color(0xFF6B7E96)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Filter games by name...',
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _currentPage = 1;
                });
              },
              child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildGamesTable(List<SteamGameItem> games, int startIndex) {
    if (games.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF121926),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF223044)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(
              'No games found matching "$_searchQuery"',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: games.length,
        separatorBuilder: (_, _) => const Divider(
          color: Color(0xFF1B2533),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final game = games[index];
          final globalIndex = startIndex + index + 1;
          final isFree = game.isFree;
          final isDiscounted = game.discountPercent > 0;

          return InkWell(
            onTap: () => _openGameDetail(game),
            child: Container(
              color: index.isEven ? const Color(0xFF121926) : const Color(0xFF0F1520),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 38,
                    child: Text(
                      '#$globalIndex',
                      style: const TextStyle(
                        color: Color(0xFF6B7E96),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Capsule Banner
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
                    width: 75,
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
                  const SizedBox(width: 12),

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
                    width: 95,
                    child: Text(
                      game.finalPriceFormatted ?? (isFree ? 'Free' : '—'),
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
            ),
          );
        },
      ),
    );
  }

  /// Pagination Bar: < 1 2 3 4 > and info text
  Widget _buildPaginationBar(int totalPages, int startIndex, int endIndex, int totalGames) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          final paginationControls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Prev Button <
              _buildNavArrowButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () => _goToPage(_currentPage - 1),
                tooltip: 'Previous page',
              ),
              const SizedBox(width: 6),

              // Page numbers
              ..._buildPageNumbers(totalPages),

              const SizedBox(width: 6),
              // Next Button >
              _buildNavArrowButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < totalPages,
                onTap: () => _goToPage(_currentPage + 1),
                tooltip: 'Next page',
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                Text(
                  'Showing ${startIndex + 1} - $endIndex of $totalGames games (Page $_currentPage/$totalPages)',
                  style: const TextStyle(color: Color(0xFF8F9DAE), fontSize: 12),
                ),
                const SizedBox(height: 10),
                paginationControls,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1} - $endIndex of $totalGames games',
                style: const TextStyle(color: Color(0xFF8F9DAE), fontSize: 13),
              ),
              paginationControls,
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF1E2838) : const Color(0xFF141C28),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? const Color(0xFF2E3E55) : const Color(0xFF1E2838),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF38BDF8) : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    final List<Widget> widgets = [];

    // Show up to 7 page numbers with intelligent ellipsis
    List<int> pagesToShow = [];
    if (totalPages <= 7) {
      pagesToShow = List.generate(totalPages, (i) => i + 1);
    } else {
      if (_currentPage <= 4) {
        pagesToShow = [1, 2, 3, 4, 5, -1, totalPages];
      } else if (_currentPage >= totalPages - 3) {
        pagesToShow = [1, -1, totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
      } else {
        pagesToShow = [1, -1, _currentPage - 1, _currentPage, _currentPage + 1, -2, totalPages];
      }
    }

    for (final p in pagesToShow) {
      if (p < 0) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        final isActive = p == _currentPage;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => _goToPage(p),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0284C7) : const Color(0xFF1E2838),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF2E3E55),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$p',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
