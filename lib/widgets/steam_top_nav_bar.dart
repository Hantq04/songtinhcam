import 'package:flutter/material.dart';

/// Top Navigation Bar dùng chung cho cả CalculatorScreen và ResultScreen
/// Thiết kế theo phong cách tối ưu của SteamDB
class SteamTopNavBar extends StatelessWidget {
  final bool isMobile;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final String activeTab;

  const SteamTopNavBar({
    super.key,
    required this.isMobile,
    this.showBackButton = false,
    this.onBack,
    this.showMenuButton = false,
    this.onMenuTap,
    this.activeTab = 'Calculator',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F17),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1E2638),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back button hoặc Menu button
          if (showBackButton)
            InkWell(
              onTap: onBack ?? () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF182030),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2B3A52), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (showMenuButton)
            InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF182030),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2B3A52), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (showBackButton || showMenuButton) const SizedBox(width: 14),

          // Logo SongTinhCam SteamDB style
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A9FFF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_esports,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SongTinhCam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Navigation Links on Desktop/Tablet
          if (!isMobile && MediaQuery.of(context).size.width >= 960) ...[
            _buildNavLink('Sales', isActive: activeTab == 'Sales'),
            _buildNavLink('Charts', isActive: activeTab == 'Charts'),
            _buildNavLink('Calculator', isActive: activeTab == 'Calculator'),
            _buildNavLink('Calendar', isActive: activeTab == 'Calendar'),
            _buildNavLink('Patches', isActive: activeTab == 'Patches'),
            const SizedBox(width: 8),
            _buildSupportLink(),
            const SizedBox(width: 16),
          ],

          // Profile / Avatar pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF131B26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF28384E),
                  child: Icon(Icons.person, size: 16, color: Colors.white70),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSupportLink() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite, size: 13, color: Color(0xFFD946EF)),
        SizedBox(width: 4),
        Text(
          'Support us',
          style: TextStyle(
            color: Color(0xFFD946EF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
