import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/widgets/profile_black_catalog.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chs_ui/chs_styles.dart';

class ProfileScreen extends StatefulWidget {
  final int? employeeId;

  const ProfileScreen({super.key, this.employeeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRemoteDataSource _authDataSource = getIt<AuthRemoteDataSource>();

  bool _loading = true;
  bool _loggingOut = false;
  String _name = '';
  String _phone = '';
  String? _error;

  static const _bgGrey = Color(0xFFF6F8FA);
  static const _cardWhite = Colors.white;
  static const _accentBrand = Color(0xFF2563EB);
  static const _logoutRed = Color(0xFFDC3545);
  static const _logoutRedHover = Color(0xFFC82333);
  static const _textDark = Color(0xFF333333);
  static const _textGrey = Color(0xFF666666);
  static const _infoBg = Color(0xFFF9FAFA);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authDataSource.getSessionInfo();
      if (!mounted) return;

      final clientRaw = session?['client'];
      final client = clientRaw is Map
          ? Map<String, dynamic>.from(clientRaw)
          : null;

      setState(() {
        _name = (client?['name'] as String?)?.trim().isNotEmpty == true
            ? client!['name'] as String
            : 'Пользователь';
        _phone = (client?['phone'] as String?) ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _name = 'Пользователь';
        _phone = '';
        _loading = false;
        _error = 'Не удалось загрузить данные пользователя';
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _loggingOut = true);
    try {
      await _authDataSource.logout();
    } catch (_) {
    } finally {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      context.goNamed(Routes.phoneAuthScreen.toName);
    }
  }

  String get _avatarLetter {
    if (_name.isEmpty) return '?';
    return _name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserData,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],
                    _ProfileCard(
                      name: _name,
                      phone: _phone,
                      avatarLetter: _avatarLetter,
                      cardColor: _cardWhite,
                      avatarColor: _accentBrand,
                      textColor: _textDark,
                      secondaryTextColor: _textGrey,
                      infoBg: _infoBg,
                      logoutRed: _logoutRed,
                      logoutRedHover: _logoutRedHover,
                      isLoggingOut: _loggingOut,
                      onLogout: _loggingOut ? null : _handleLogout,
                    ),
                    const SizedBox(height: 16),
                    _NavTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Статистика и долги',
                      subtitle:
                          'Стрик, активность и журнал долгов в рублях (локально)',
                      onTap: () => context.goNamed(
                        Routes.statsScreen.toName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NavTile(
                      icon: Icons.description_outlined,
                      title: 'Шаблоны документов',
                      subtitle: 'Бланки расписки, акта и уведомления (.docx)',
                      onTap: () => context.goNamed(
                        Routes.templatesScreen.toName,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const ProfileBlackCatalog(allowEdit: true, pageSize: 10),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String phone;
  final String avatarLetter;
  final Color cardColor;
  final Color avatarColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color infoBg;
  final Color logoutRed;
  final Color logoutRedHover;
  final bool isLoggingOut;
  final VoidCallback? onLogout;

  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.avatarLetter,
    required this.cardColor,
    required this.avatarColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.infoBg,
    required this.logoutRed,
    required this.logoutRedHover,
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Профиль пользователя',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone.isEmpty ? '—' : phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: _LogoutButton(
              isLoading: isLoggingOut,
              normalColor: logoutRed,
              hoverColor: logoutRedHover,
              onPressed: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final bool isLoading;
  final Color normalColor;
  final Color hoverColor;
  final VoidCallback? onPressed;

  const _LogoutButton({
    required this.isLoading,
    required this.normalColor,
    required this.hoverColor,
    required this.onPressed,
  });

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final color = (_hovered && !disabled)
        ? widget.hoverColor
        : widget.normalColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Выйти из аккаунта',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(AppColors.white),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(AppColors.greenTie),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: const Color(AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppStyle.manrope(
                        size: 13,
                        weight: FontWeight.w400,
                        color: const Color(AppColors.uiBorder),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(AppColors.borderColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCCC7)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFCF1322))),
    );
  }
}
