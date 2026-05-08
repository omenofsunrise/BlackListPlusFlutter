import 'package:blacklist_plus_flutter/assets/resources.dart';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/core/utils/bottom_nav_controller.dart';
import 'package:blacklist_plus_flutter/core/utils/moderation_utils.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late final Future<bool> _isModeratedFuture;

  static const _navConfigs = [
    _NavItemConfig(icon: SvgIcons.calculator, branchIndex: 0),
    _NavItemConfig(icon: SvgIcons.notebook, branchIndex: 1),
    _NavItemConfig(icon: SvgIcons.bell, branchIndex: 2),
    _NavItemConfig(icon: SvgIcons.users, branchIndex: 3),
  ];

  @override
  void initState() {
    super.initState();
    _isModeratedFuture = _loadModerationStatus();
  }

  Future<bool> _loadModerationStatus() async {
    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final authInfo = await authDataSource.getAuthInfo();
      return isUserModerated(authInfo);
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: BottomNavController.instance,
        builder: (context, visible, _) {
          if (!visible) return const SizedBox.shrink();
          return FutureBuilder<bool>(
            future: _isModeratedFuture,
            builder: (context, snapshot) {
              final isModerated = snapshot.data ?? true;
              final items = isModerated
                  ? _navConfigs
                  : _navConfigs
                        .where((item) => item.branchIndex != 0)
                        .toList();
              final currentUiIndex = items.indexWhere(
                (item) => item.branchIndex == navigationShell.currentIndex,
              );

              return _AppBottomNavBar(
                currentIndex: currentUiIndex < 0 ? 0 : currentUiIndex,
                items: items,
                onTap: (index) {
                  final branchIndex = items[index].branchIndex;
                  navigationShell.goBranch(
                    branchIndex,
                    initialLocation: branchIndex == navigationShell.currentIndex,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemConfig> items;

  static const _barBg = Color(AppColors.white);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: _barBg,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: _barBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final config = items[index];
            final selected = currentIndex == index;
            return _NavItem(
              icon: config.icon,
              selected: selected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  static const _brand = Color(AppColors.primary);
  static const _iconColor = Color(AppColors.uiBorder);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 56,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _brand : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SvgPicture.asset(
          icon,
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(
            selected ? const Color(AppColors.white) : _iconColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _NavItemConfig {
  const _NavItemConfig({required this.icon, required this.branchIndex});

  final String icon;
  final int branchIndex;
}
