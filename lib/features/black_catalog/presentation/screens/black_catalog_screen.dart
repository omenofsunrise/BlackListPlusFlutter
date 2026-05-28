import 'dart:async';

import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/cubit/black_catalog_list_cubit.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/widgets/add_debt_modal.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/widgets/black_catalog_card.dart';
import 'package:blacklist_plus_flutter/core/widgets/app_dialog.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/widgets/black_catalog_form_modal.dart';
import 'package:blacklist_plus_flutter/features/stats/data/local_stats_service.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class BlackCatalogScreen extends StatefulWidget {
  const BlackCatalogScreen({super.key});

  @override
  State<BlackCatalogScreen> createState() => _BlackCatalogScreenState();
}

class _BlackCatalogScreenState extends State<BlackCatalogScreen> {
  late final BlackCatalogListCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _cubit = BlackCatalogListCubit();
    _cubit.refreshTotalCount();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final session = await getIt<AuthRemoteDataSource>().getSessionInfo();
      final clientRaw = session?['client'];
      final client = clientRaw is Map
          ? Map<String, dynamic>.from(clientRaw)
          : null;
      final id = (client?['id'] as String?) ?? '';
      if (!mounted) return;
      setState(() {
        _currentUserId = id;
      });
    } catch (_) {}
  }

  bool _canEditItem(BlackCatalogItem item) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    if (item.creatorId == null || item.creatorId!.isEmpty) return false;
    return item.creatorId == _currentUserId;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _cubit.search(value);
    });
  }

  Future<void> _showAddMenu() async {
    final option = await showModalBottomSheet<BlackCatalogAddOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Добавить',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.add_box_outlined,
                  color: Color(0xFF94A3B8),
                ),
                title: const Text('Чёрный список'),
                onTap: () =>
                    Navigator.pop(ctx, BlackCatalogAddOption.blacklist),
              ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF64748B),
                ),
                title: const Text('Оформленный'),
                onTap: () =>
                    Navigator.pop(ctx, BlackCatalogAddOption.completed),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (option == null) return;
    final result = await showBlackCatalogFormModal(
      context: context,
      option: option,
    );
    if (result == null) return;
    try {
      await _cubit.createItem(
        fullname: result.fullname,
        doc: result.doc,
        address: result.address,
        birthdate: result.birthdate,
        comment: result.comment,
        isSwindler: result.isSwindler,
        debtEndingAt: result.debtEndingAt,
      );
      unawaited(getIt<LocalStatsService>().recordAdd());
    } catch (e) {
      _showError('Ошибка при сохранении: $e');
    }
  }

  Future<void> _editItem(BlackCatalogItem item) async {
    final result = await showBlackCatalogFormModal(
      context: context,
      editing: item,
    );
    if (result == null) return;
    try {
      await _cubit.updateItem(
        id: item.id,
        fullname: result.fullname,
        doc: result.doc,
        address: result.address,
        birthdate: result.birthdate,
        comment: result.comment,
        isSwindler: result.isSwindler,
        debtEndingAt: result.debtEndingAt,
      );
    } catch (e) {
      _showError('Ошибка при сохранении: $e');
    }
  }

  Future<void> _addDebt(BlackCatalogItem item) async {
    final ending = await showAddDebtModal(
      context: context,
      itemName: item.fullname,
    );
    if (ending == null) return;
    try {
      await _cubit.addDebt(item.id, ending);
    } catch (e) {
      _showError('Не удалось добавить долг: $e');
    }
  }

  Future<void> _confirmDelete(BlackCatalogItem item) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Удалить запись?',
      message:
          'Вы уверены, что хотите удалить ${item.fullname} из чёрного каталога?',
      confirmText: 'Удалить',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _cubit.deleteItem(item.id);
      unawaited(getIt<LocalStatsService>().recordDelete());
    } catch (e) {
      _showError('Не удалось удалить: $e');
    }
  }

  void _openDossier(BlackCatalogItem item) {
    unawaited(getIt<LocalStatsService>().recordView());
    context.pushNamed(Routes.blackCatalogDossierScreen.toName, extra: item);
  }

  Future<void> _showItemMenu(BlackCatalogItem item) async {
    final canEdit = _canEditItem(item);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редактировать'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Добавить долг'),
              onTap: () => Navigator.pop(ctx, 'add_debt'),
            ),
            if (canEdit)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  'Удалить',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (action == null) return;
    if (action == 'edit') {
      if (!canEdit) {
        _showError('У вас нет прав на редактирование этой записи');
        return;
      }
      _editItem(item);
    } else if (action == 'add_debt') {
      _addDebt(item);
    } else if (action == 'delete') {
      _confirmDelete(item);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF007D88),
          onPressed: _showAddMenu,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child:
                    BlocBuilder<BlackCatalogListCubit, BlackCatalogListState>(
                      builder: (context, state) => _buildBody(state),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Header(
            title: 'Чёрный список',
            showBackButton: true,
            showNotifications: false,
          ),
          const SizedBox(height: 12),
          SearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            hintText: 'ФИО (минимум 5 символов)',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BlackCatalogListState state) {
    if (state is BlackCatalogListLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is BlackCatalogListError) {
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
    if (state is BlackCatalogListEmpty) {
      return _buildEmpty(state);
    }
    if (state is BlackCatalogListLoaded) {
      return _buildList(state);
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmpty(BlackCatalogListEmpty state) {
    final hasSearched = state.hasSearched;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasSearched ? '🔍' : '📋',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearched
                  ? 'Запись в чёрном каталоге не найдена'
                  : 'Чёрный список',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearched
                  ? 'По вашему запросу "${state.query}" ничего не найдено.'
                  : 'Введите ФИО клиента (минимум 5 символов) для поиска в чёрном каталоге.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BlackCatalogListLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => _cubit.refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          final canEdit = _canEditItem(item);
          return BlackCatalogCard(
            item: item,
            allowEdit: canEdit,
            allowDelete: canEdit,
            onTap: () => _openDossier(item),
            onLongPress: () => _showItemMenu(item),
            onEdit: canEdit ? () => _editItem(item) : null,
            onDelete: canEdit ? () => _confirmDelete(item) : null,
          );
        },
      ),
    );
  }
}
