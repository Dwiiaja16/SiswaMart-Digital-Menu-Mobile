import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'how_to_order_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int? _pressedIndex;
  String? _catalogSearch;
  int? _catalogCategoryId;
  int _catalogKeyCounter = 0;

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToCatalog({String? search, int? categoryId}) {
    setState(() {
      _catalogSearch = search;
      _catalogCategoryId = categoryId;
      _catalogKeyCounter++;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        onNavigateToCatalog: _navigateToCatalog,
      ),
      CatalogScreen(
        key: ValueKey(
            'catalog-$_catalogKeyCounter-$_catalogSearch-$_catalogCategoryId'),
        initialSearch: _catalogSearch,
        initialKategoriId: _catalogCategoryId,
      ),
      const HowToOrderScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(pages.length, (index) {
          final isActive = _currentIndex == index;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: isActive ? 1.0 : 0.0,
            child: pages[index],
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 2),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.border,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  activeIcon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Beranda',
                ),
                _buildNavItem(
                  index: 1,
                  activeIcon: Icons.storefront_rounded,
                  inactiveIcon: Icons.storefront_outlined,
                  label: 'Katalog',
                ),
                _buildNavItem(
                  index: 2,
                  activeIcon: Icons.chat_bubble_rounded,
                  inactiveIcon: Icons.chat_bubble_outline_rounded,
                  label: 'Cara Pesan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    final bool isPressed = _pressedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressedIndex = index),
        onTapUp: (_) {
          setState(() => _pressedIndex = null);
          _onTabTapped(index);
        },
        onTapCancel: () => setState(() => _pressedIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          transform: Matrix4.translationValues(
            isPressed ? 1.5 : 0,
            isPressed ? 1.5 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.border : Colors.transparent,
              width: 1.8,
            ),
            boxShadow: isSelected && !isPressed
                ? const [
                    BoxShadow(
                      color: AppColors.border,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: 17,
                  color: isSelected ? AppColors.border : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? AppColors.border : AppColors.textMuted,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}