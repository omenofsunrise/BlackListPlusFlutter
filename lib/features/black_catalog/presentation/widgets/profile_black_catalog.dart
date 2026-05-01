import 'dart:async';

import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/cubit/my_black_catalog_cubit.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/widgets/black_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ProfileBlackCatalog extends StatefulWidget {
  final int pageSize;

  final bool allowEdit;

  final void Function(BlackCatalogItem item)? onOpenDossier;

  final void Function(BlackCatalogItem item)? onEdit;

  const ProfileBlackCatalog({
    super.key,
    this.pageSize = 10,
    this.allowEdit = true,
    this.onOpenDossier,
    this.onEdit,
  });

  @override
  State<ProfileBlackCatalog> createState() => _ProfileBlackCatalogState();
}

class _ProfileBlackCatalogState extends State<ProfileBlackCatalog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late final MyBlackCatalogCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MyBlackCatalogCubit(pageSize: widget.pageSize);
    _cubit.loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        _cubit.loadMore();
      }
    }
    return false;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isEmpty || value.length >= 5) {
        _cubit.loadInitial(query: value);
      }
    });
  }

  Future<void> _confirmDelete(BlackCatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
          'Вы уверены, что хотите удалить ${item.fullname} из чёрного каталога?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cubit.deleteItem(item.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при удалении: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: BlocBuilder<MyBlackCatalogCubit, MyBlackCatalogState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state),
                const SizedBox(height: 12),
                _buildContent(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(MyBlackCatalogState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 20,
                color: Color(0xFF007D88),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Мой чёрный список',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          hintText: 'Поиск по ФИО (минимум 5 символов)',
        ),
      ],
    );
  }

  Widget _buildContent(MyBlackCatalogState state) {
    if (state is MyBlackCatalogLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is MyBlackCatalogError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Ошибка: ${state.message}',
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
      );
    }
    if (state is! MyBlackCatalogLoaded) {
      return const SizedBox.shrink();
    }

    if (state.items.isEmpty) {
      final hasSearched = state.query.length >= 5;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              const Text('📋', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Мой чёрный список',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearched
                    ? 'По запросу "${state.query}" ничего не найдено.'
                    : 'Введите ФИО клиента (минимум 5 символов) для поиска в вашем чёрном каталоге.',
                style: const TextStyle(color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: state.isLoadingMore
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Прокрутите для загрузки ещё',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
            ),
          );
        }
        final item = state.items[index];
        return BlackCatalogCard(
          item: item,
          allowEdit: widget.allowEdit && widget.onEdit != null,
          allowDelete: widget.allowEdit,
          onTap: widget.onOpenDossier != null
              ? () => widget.onOpenDossier!.call(item)
              : null,
          onEdit: widget.onEdit != null
              ? () => widget.onEdit!.call(item)
              : null,
          onDelete: widget.allowEdit ? () => _confirmDelete(item) : null,
        );
      },
    );
  }
}
