import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/notification.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/cubit/notifications_cubit.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chs_ui/chs_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = NotificationsCubit()..loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final now = DateTime.now();
    final diff = now.difference(d);
    final mins = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;
    if (mins < 1) return 'Только что';
    if (mins < 60) return '$mins мин назад';
    if (hours < 24) return '$hours ч назад';
    if (days == 1) return 'Вчера';
    if (days < 7) return '$days дня назад';
    return DateFormat('d MMM, HH:mm', 'ru_RU').format(d);
  }

  Future<void> _onNotificationTap(BlackCatalogNotification n) async {
    if (!n.isRead) {
      await _cubit.markAsRead(n.id);
    }
    if (n.entityId == null || n.entityId!.isEmpty) return;
    final id = int.tryParse(n.entityId!);
    if (id == null) return;

    try {
      final response = await getIt<BlackCatalogRemoteDataSource>().search(
        id: id,
        pageSize: 1,
      );
      if (!mounted) return;
      if (response.blackCatalogs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Запись не найдена')));
        return;
      }
      context.pushNamed(
        Routes.blackCatalogDossierScreen.toName,
        extra: response.blackCatalogs.first,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось открыть запись: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) => _buildBody(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Header(
        title: 'Уведомления',
        showBackButton: true,
        showNotifications: false,
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state is NotificationsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is NotificationsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ошибка: ${state.message}',
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
      );
    }
    if (state is! NotificationsLoaded) return const SizedBox.shrink();

    if (state.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔔', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text(
                'Нет уведомлений',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Здесь будут отображаться все уведомления о новых записях и изменениях',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _cubit.loadInitial(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }
          final n = state.items[index];
          return _NotificationCard(
            notification: n,
            dateLabel: _formatDate(n.createdAt),
            onTap: () => _onNotificationTap(n),
            onMarkAsRead: () => _cubit.markAsRead(n.id),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final BlackCatalogNotification notification;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const _NotificationCard({
    required this.notification,
    required this.dateLabel,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return Material(
      color: isRead ? Colors.white : const Color(0xFFE0F2F2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRead ? const Color(0xFFE5E7EB) : const Color(0xFF2563EB),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (!isRead)
                    InkWell(
                      onTap: onMarkAsRead,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
