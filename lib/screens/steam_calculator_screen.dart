import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/steam_service.dart';
import '../widgets/steam_top_nav_bar.dart';
import 'steam_result_screen.dart';

class SteamCalculatorScreen extends StatefulWidget {
  const SteamCalculatorScreen({super.key});

  @override
  State<SteamCalculatorScreen> createState() => _SteamCalculatorScreenState();
}

class _SteamCalculatorScreenState extends State<SteamCalculatorScreen> {
  final TextEditingController _steamIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCurrency = 'Vietnamese Dong';
  bool _isLoading = false;

  final List<Map<String, String>> _currencies = [
    {'name': 'Vietnamese Dong', 'code': 'VND', 'symbol': '₫'},
    {'name': 'U.S. Dollar', 'code': 'USD', 'symbol': '\$'}
  ];

  final List<Map<String, String>> _lookupExamples = [
    {
      'type': 'Steam vanity url',
      'url': 'https://steamcommunity.com/id/gabelogannewell',
    },
    {
      'type': 'Steam profile url',
      'url': 'https://steamcommunity.com/profiles/76561198006889896',
    },
    {
      'type': 'Steam profile url',
      'url': 'https://steamcommunity.com/profiles/[U:1:1208333168]',
    },
    {
      'type': 'Steam /user/ url',
      'url': 'https://steamcommunity.com/user/qfkb',
    }
  ];

  @override
  void dispose() {
    _steamIdController.dispose();
    super.dispose();
  }

  void _calculateAccountValue() async {
    if (_steamIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text(
            'Please enter a Steam Profile URL or Steam ID!',
            style: TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final input = _steamIdController.text.trim();

    try {
      final result = await SteamService.calculateAccount(
        input: input,
        currencyName: _selectedCurrency,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _steamIdController.clear();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SteamResultScreen(
            result: result,
            currencyName: _selectedCurrency,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _steamIdController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _fillSampleUrl(String url) {
    setState(() {
      _steamIdController.text = url;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1B2838),
        content: Text(
          'Example copied: $url',
          style: const TextStyle(color: Color(0xFF66C0F4)),
        ),
        behavior: SnackBarBehavior.floating,
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
              showMenuButton: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 40.0,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeroHeader(),
                        const SizedBox(height: 32),
                        _buildCalculatorCard(),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF3880FF),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading Steam profile and library data...',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildHelpfulNotes(),
                        const SizedBox(height: 24),
                        _buildFilterBadges(),
                        const SizedBox(height: 36),
                        _buildLookupExamplesTable(),
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

  /// Steam Calculator Hero Header
  Widget _buildHeroHeader() {
    return Column(
      children: [
        const Text(
          'Steam Calculator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Calculate your Steam account value and convert any SteamID',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Main Input Fields & Calculation Action Form
  Widget _buildCalculatorCard() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input: URL / Steam ID
          _buildSteamIdInput(),
          const SizedBox(height: 18),

          // Currency Dropdown + Get Disappointed Action Button
          _buildActionBar(),
        ],
      ),
    );
  }

  /// Input: URL or Steam ID field (SteamDB pill-styled search bar)
  Widget _buildSteamIdInput() {
    return Container(
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
          const Icon(
            Icons.search,
            color: Color(0xFF6B7E96),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _steamIdController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: const Color(0xFF3B82F6),
              decoration: InputDecoration(
                hintText: 'Your profile url or steamid',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => _calculateAccountValue(),
            ),
          ),
          if (_steamIdController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF6B7E96), size: 18),
              onPressed: () {
                setState(() {
                  _steamIdController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  /// Action Row: Currency Dropdown + Blue Button
  Widget _buildActionBar() {
    final currencyDropdown = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141C28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2B3A50)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          dropdownColor: const Color(0xFF16202E),
          icon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.unfold_more, color: Color(0xFF8C9BAE), size: 18),
          ),
          style: const TextStyle(
            color: Color(0xFFD1D5DB),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCurrency = newValue;
              });
            }
          },
          items: _currencies.map<DropdownMenuItem<String>>((currency) {
            return DropdownMenuItem<String>(
              value: currency['name'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currency['name']!),
                  const SizedBox(width: 6),
                  Text(
                    '(${currency['symbol']})',
                    style: const TextStyle(color: Color(0xFF6B7E96)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );

    final submitButton = ElevatedButton(
      onPressed: _isLoading ? null : _calculateAccountValue,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B62C0),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF1B62C0).withValues(alpha: 0.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get disappointed in your life',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 16),
        ],
      ),
    );

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          currencyDropdown,
          submitButton,
        ],
      ),
    );
  }

  /// Helpful notes with icons matching SteamDB screenshot
  Widget _buildHelpfulNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNoteRow(
          icon: Icons.info_outline,
          iconColor: const Color(0xFF60A5FA),
          text:
              'Any SteamID format is accepted, enter anything you want and we will convert it on the fly for you.',
        ),
        const SizedBox(height: 8),
        _buildNoteRow(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          text: 'You cannot enter your login username or nickname.',
        ),
        const SizedBox(height: 8),
        _buildNoteRow(
          icon: Icons.public,
          iconColor: const Color(0xFF34D399),
          text:
              'Profile and "Game details" must be set to Public on Steam so your games can be calculated.',
          linkText: 'Steam Privacy Settings',
          onLinkTap: () {
            Clipboard.setData(
              const ClipboardData(
                text: 'https://steamcommunity.com/my/edit/settings',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Copied privacy settings link: https://steamcommunity.com/my/edit/settings',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoteRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    String? linkText,
    VoidCallback? onLinkTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF8F9DAE),
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                if (text.isNotEmpty) TextSpan(text: text),
                if (text.isNotEmpty && linkText != null) const TextSpan(text: ' '),
                if (linkText != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: InkWell(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3 Pill action buttons from screenshot: Profile badges, Top game owners, Top profile levels
  Widget _buildFilterBadges() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildPillButton(
          title: 'Profile badges',
          icon: Icons.military_tech_outlined,
        ),
        _buildPillButton(
          title: 'Top game owners',
          icon: Icons.emoji_events_outlined,
        ),
        _buildPillButton(
          title: 'Top profile levels',
          icon: Icons.star_border_outlined,
        ),
      ],
    );
  }

  Widget _buildPillButton({required String title, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF26374D)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8F9DAE)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Lookup examples table matching screenshot
  Widget _buildLookupExamplesTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'SteamID Lookup: Examples of what can be entered to find a SteamID',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121925),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF243348)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(_lookupExamples.length, (index) {
              final item = _lookupExamples[index];
              final isEven = index.isEven;
              final isLast = index == _lookupExamples.length - 1;

              return Container(
                decoration: BoxDecoration(
                  color: isEven ? const Color(0xFF121925) : const Color(0xFF0F1520),
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: Color(0xFF1E2B3E),
                            width: 1,
                          ),
                        ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        item['type']!,
                        style: const TextStyle(
                          color: Color(0xFF8F9DAE),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _fillSampleUrl(item['url']!),
                        child: Text(
                          item['url']!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.content_paste_go,
                        size: 16,
                        color: Color(0xFF6B7E96),
                      ),
                      tooltip: 'Fill in URL/SteamID',
                      onPressed: () => _fillSampleUrl(item['url']!),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
