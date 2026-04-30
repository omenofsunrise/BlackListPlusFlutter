import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/core/network/token_storage.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/session_model.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final _auth = getIt<AuthRemoteDataSource>();
  final _tokenStorage = TokenStorage();
  final _fmt = DateFormat('dd-MM-yyyy');

  bool _loading = true;
  String? _error;
  List<SessionModel> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await _auth.getSessions();
      setState(() => _sessions = sessions);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(SessionModel s) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Завершить сессию?'),
        content: Text(
          s.isCurrentSession
              ? 'Вы собираетесь завершить ТЕКУЩУЮ сессию. После этого потребуется повторный вход.'
              : 'Вы уверены, что хотите завершить выбранную сессию?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _auth.revokeSession(s.id);

      if (s.isCurrentSession) {
        await _tokenStorage.clearAll();
        if (!mounted) return;
        Navigator.pop(context);
        context.goNamed(Routes.phoneAuthScreen.toName);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сессия завершена')));
      _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка завершения: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final teal = const Color(AppColors.primary);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Header(
                title: 'Профиль',
                showBackButton: true,
                showNotifications: false,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 46,
                            ),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 160,
                              child: DefaultButton(
                                text: 'Повторить',
                                onPressed: _load,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _SessionCard(
                          s: _sessions[i],
                          onRevoke: () => _revoke(_sessions[i]),
                          dateFmt: _fmt,
                          accentColor: teal,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel s;
  final VoidCallback onRevoke;
  final DateFormat dateFmt;
  final Color accentColor;

  const _SessionCard({
    required this.s,
    required this.onRevoke,
    required this.dateFmt,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(color: Color(0x05000809), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'IP: ${s.ipAddress}',
                    style: AppStyle.manrope(size: 16, weight: FontWeight.w500),
                  ),
                ),
                if (s.isCurrentSession)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primaryLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Текущая',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SessionInfoRow(
              label: 'Создана:',
              value: dateFmt.format(s.createdAt.toLocal()),
            ),
            const SizedBox(height: 8),
            _SessionInfoRow(
              label: 'Последняя активность:',
              value: dateFmt.format(s.lastUsedAt.toLocal()),
            ),
            const SizedBox(height: 8),
            _SessionInfoRow(
              label: 'Истекает:',
              value: dateFmt.format(s.expiresAt.toLocal()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DefaultButton(
                text: 'Завершить',
                color: accentColor,
                textColor: Colors.white,
                onPressed: onRevoke,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SessionInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: AppStyle.manrope(
            size: 16,
            weight: FontWeight.w500,
            color: const Color(AppColors.black),
          ),
        ),
      ],
    );
  }
}
