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

  // Filter state
  bool _showFilterPanel = false;
  String _selectedStatus = 'All'; // 'All', 'Affectionless', 'InProgress', 'Done'
  String _priceFilter = 'All'; // 'All', 'High to Low', 'Low to High', 'Free', 'Paid'
  DateTime? _fromDate;
  DateTime? _toDate;

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != 'All') count++;
    if (_priceFilter != 'All') count++;
    if (_fromDate != null || _toDate != null) count++;
    return count;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SteamGameItem> get _filteredGames {
    var list = widget.games;

    // 1. Tìm kiếm theo tên game
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((g) => g.name.toLowerCase().contains(q)).toList();
    }

    // 2. Lọc theo trạng thái game
    if (_selectedStatus != 'All') {
      list = list.where((g) => g.status == _selectedStatus).toList();
    }

    // 3. Lọc theo phân loại giá (Free / Paid)
    if (_priceFilter == 'Free') {
      list = list
          .where((g) => g.isFree || (g.finalPrice ?? g.initialPrice ?? 0) == 0)
          .toList();
    } else if (_priceFilter == 'Paid') {
      list = list
          .where((g) => !g.isFree && (g.finalPrice ?? g.initialPrice ?? 0) > 0)
          .toList();
    }

    // 4. Lọc theo khoảng ngày (Từ ngày - đến ngày)
    if (_fromDate != null || _toDate != null) {
      list = list.where((g) {
        final d = g.lastPlayed ?? g.addedDate;
        if (d == null) return false;
        if (_fromDate != null) {
          final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
          if (d.isBefore(start)) return false;
        }
        if (_toDate != null) {
          final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
          if (d.isAfter(end)) return false;
        }
        return true;
      }).toList();
    }

    // 5. Sắp xếp theo giá game cao/thấp
    if (_priceFilter == 'High to Low') {
      list = List.of(list)..sort((a, b) {
        final pA = a.finalPrice ?? a.initialPrice ?? 0;
        final pB = b.finalPrice ?? b.initialPrice ?? 0;
        return pB.compareTo(pA);
      });
    } else if (_priceFilter == 'Low to High') {
      list = List.of(list)..sort((a, b) {
        final pA = a.finalPrice ?? a.initialPrice ?? 0;
        final pB = b.finalPrice ?? b.initialPrice ?? 0;
        return pA.compareTo(pB);
      });
    }

    return list;
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
    final isMobile = MediaQuery.of(context).size.width < 820;
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

                        // Header Bar: Title, Search, Total Count, Filter Button
                        _buildHeader(totalGames, isMobile),
                        const SizedBox(height: 12),

                        // Filter Panel (Hiện ra khi bấm nút Filter)
                        if (_showFilterPanel) ...[
                          _buildFilterPanel(isMobile),
                          const SizedBox(height: 16),
                        ],

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
                Row(
                  children: [
                    Expanded(child: _buildSearchInput()),
                    const SizedBox(width: 8),
                    _buildFilterToggleButton(),
                  ],
                ),
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
                const SizedBox(width: 10),
                _buildCountPill(totalGames),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: _buildSearchInput(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterToggleButton(),
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

  Widget _buildFilterToggleButton() {
    final hasActive = _activeFilterCount > 0;
    return InkWell(
      onTap: () {
        setState(() {
          _showFilterPanel = !_showFilterPanel;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _showFilterPanel
              ? const Color(0xFF1E293B)
              : const Color(0xFF0F141D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasActive || _showFilterPanel
                ? const Color(0xFF38BDF8)
                : const Color(0xFF26374D),
            width: hasActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 17,
              color: hasActive || _showFilterPanel
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: TextStyle(
                color: hasActive || _showFilterPanel
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_activeFilterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121926),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF223044)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Filter & Sort Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_activeFilterCount > 0)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'All';
                      _priceFilter = 'All';
                      _fromDate = null;
                      _toDate = null;
                      _currentPage = 1;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFF87171)),
                  label: const Text(
                    'Reset',
                    style: TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _showFilterPanel = false;
                  });
                },
                child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1E2838), height: 1),
          const SizedBox(height: 14),

          // 1. Trạng thái (Status)
          const Text(
            'STATUS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                isSelected: _selectedStatus == 'All',
                onTap: () => setState(() {
                  _selectedStatus = 'All';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'Affectionless',
                isSelected: _selectedStatus == 'Affectionless',
                onTap: () => setState(() {
                  _selectedStatus = 'Affectionless';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'InProgress',
                isSelected: _selectedStatus == 'InProgress',
                onTap: () => setState(() {
                  _selectedStatus = 'InProgress';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'Done',
                isSelected: _selectedStatus == 'Done',
                onTap: () => setState(() {
                  _selectedStatus = 'Done';
                  _currentPage = 1;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Giá game (Price & Sorting)
          const Text(
            'PRICE & SORTING',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Default',
                isSelected: _priceFilter == 'All',
                onTap: () => setState(() {
                  _priceFilter = 'All';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'Price: High → Low',
                isSelected: _priceFilter == 'High to Low',
                onTap: () => setState(() {
                  _priceFilter = 'High to Low';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'Price: Low → High',
                isSelected: _priceFilter == 'Low to High',
                onTap: () => setState(() {
                  _priceFilter = 'Low to High';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'Free Only',
                isSelected: _priceFilter == 'Free',
                onTap: () => setState(() {
                  _priceFilter = 'Free';
                  _currentPage = 1;
                }),
              ),
              _buildFilterChip(
                label: 'Paid Only',
                isSelected: _priceFilter == 'Paid',
                onTap: () => setState(() {
                  _priceFilter = 'Paid';
                  _currentPage = 1;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Từ ngày - Đến ngày (Date range)
          const Text(
            'DATE RANGE (LAST PLAYED / ACTIVITY)',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDateSelectorButton(
                label: _fromDate != null ? 'From: ${_formatDate(_fromDate)}' : 'From Date',
                isSelected: _fromDate != null,
                onTap: () async {
                  final picked = await _pickDate(_fromDate ?? DateTime.now());
                  if (picked != null) {
                    setState(() {
                      _fromDate = picked;
                      _currentPage = 1;
                    });
                  }
                },
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF64748B)),
              _buildDateSelectorButton(
                label: _toDate != null ? 'To: ${_formatDate(_toDate)}' : 'To Date',
                isSelected: _toDate != null,
                onTap: () async {
                  final picked = await _pickDate(_toDate ?? DateTime.now());
                  if (picked != null) {
                    setState(() {
                      _toDate = picked;
                      _currentPage = 1;
                    });
                  }
                },
              ),
              if (_fromDate != null || _toDate != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                      _currentPage = 1;
                    });
                  },
                  child: const Text('Clear dates', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7).withValues(alpha: 0.25)
              : const Color(0xFF0F141D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : const Color(0xFF26374D),
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelectorButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7).withValues(alpha: 0.25)
              : const Color(0xFF0F141D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : const Color(0xFF26374D),
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFFCBD5E1),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              surface: Color(0xFF141C28),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF141C28),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
