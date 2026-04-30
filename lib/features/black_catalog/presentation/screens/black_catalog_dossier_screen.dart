import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/comment.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/debt.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/cubit/comments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Полный порт BlackCatalogDossier.tsx из waypay-react.
///
/// Что отображается:
///   • Кнопка «Назад к поиску».
///   • Заголовок: ФИО, ID, бейдж статуса (Чёрный список/Есть оформления).
///   • Секция «Общая информация» (дата рождения, адрес, документ).
///   • Секция «Оформления» — активные и просроченные долги. Свои долги
///     можно удалить (проверка по creator_id == userId).
///   • Секция «Комментарии» — список + поле добавления + редактирование/
///     удаление своих комментариев.
class BlackCatalogDossierScreen extends StatefulWidget {
  /// Запись, по которой открыто досье. Перезагрузка свежих данных
  /// (например, после удаления долга) идёт через searchEntries(id=...).
  final BlackCatalogItem initialItem;

  const BlackCatalogDossierScreen({super.key, required this.initialItem});

  @override
  State<BlackCatalogDossierScreen> createState() =>
      _BlackCatalogDossierScreenState();
}

class _BlackCatalogDossierScreenState
    extends State<BlackCatalogDossierScreen> {
  late BlackCatalogItem _item;
  String? _currentUserId;

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final session = await getIt<AuthRemoteDataSource>().getSessionInfo();
      final clientRaw = session?['client'];
      final client =
          clientRaw is Map ? Map<String, dynamic>.from(clientRaw) : null;
      final id = (client?['id'] as String?) ?? '';
      if (!mounted) return;
      setState(() => _currentUserId = id);
    } catch (_) {/* ignore */}
  }

  Future<void> _refreshItem() async {
    try {
      final response = await _dataSource.search(id: _item.id, pageSize: 1);
      if (response.blackCatalogs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _item = response.blackCatalogs.first);
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _deleteDebt(int debtId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить долг?'),
        content: const Text('Вы уверены, что хотите удалить этот долг?'),
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
    if (confirmed != true) return;
    try {
      await _dataSource.deleteDebt(debtId);
      await _refreshItem();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить долг: $e')),
      );
    }
  }

  bool _canDeleteDebt(Debt debt) {
    return _currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        debt.creatorId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = _item.activeDebts;
    final expiredDebts = _item.expiredDebts;
    final hasActiveDebt = activeDebts.isNotEmpty;
    final isBlacklist = (_item.isSwindler ?? false) || !hasActiveDebt;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BackButton — «Назад к поиску»
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад к поиску'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Заголовок: ФИО, ID, бейдж статуса
              Text(
                _item.fullname,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${_item.id}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 10),
              _StatusBadge(isBlacklist: isBlacklist),
              const SizedBox(height: 18),

              // Секция «Общая информация»
              const _SectionTitle('Общая информация'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _InfoCell(
                    label: 'Дата рождения',
                    value: _formatDate(_item.birthdate),
                    isWarning: isBlacklist,
                    isDebt: !isBlacklist,
                  ),
                  _InfoCell(
                    label: 'Адрес',
                    value: (_item.address?.isNotEmpty ?? false)
                        ? _item.address!
                        : 'Не указан',
                    isWarning: isBlacklist,
                    isDebt: !isBlacklist,
                  ),
                  _InfoCell(
                    label: 'Документ',
                    value: (_item.doc?.isNotEmpty ?? false)
                        ? _item.doc!
                        : 'Не указан',
                    isWarning: isBlacklist,
                    isDebt: !isBlacklist,
                  ),
                ],
              ),

              // Секция «Оформления» (долги)
              if (activeDebts.isNotEmpty || expiredDebts.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFD1D5DB)),
                const SizedBox(height: 8),
                const _SectionTitle('Оформления'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...activeDebts.map(
                      (d) => _DebtBadgeRow(
                        debt: d,
                        expired: false,
                        canDelete: _canDeleteDebt(d),
                        onDelete: () => _deleteDebt(d.id),
                      ),
                    ),
                    ...expiredDebts.map(
                      (d) => _DebtBadgeRow(
                        debt: d,
                        expired: true,
                        canDelete: _canDeleteDebt(d),
                        onDelete: () => _deleteDebt(d.id),
                      ),
                    ),
                  ],
                ),
              ],

              // Секция «Комментарии»
              const SizedBox(height: 24),
              const _SectionTitle('Комментарии'),
              const SizedBox(height: 8),
              if (_currentUserId != null)
                BlocProvider(
                  create: (_) => CommentsCubit(
                    blacklistId: _item.id,
                    currentUserId: _currentUserId!,
                  )..load(),
                  child: _CommentsSection(currentUserId: _currentUserId!),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Не указана';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('dd.MM.yyyy', 'ru_RU').format(parsed);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  final bool isDebt;

  const _InfoCell({
    required this.label,
    required this.value,
    this.isWarning = false,
    this.isDebt = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? const Color(0xFFEF4444)
        : isDebt
            ? const Color(0xFFB45309)
            : const Color(0xFF111827);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isBlacklist;
  const _StatusBadge({required this.isBlacklist});

  @override
  Widget build(BuildContext context) {
    final bg = isBlacklist ? Colors.black : const Color(0xFFF59E0B);
    final fg = isBlacklist ? const Color(0xFFEF4444) : Colors.white;
    final text = isBlacklist ? 'Чёрный список' : 'Есть оформления';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: (isBlacklist
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B))
                .withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DebtBadgeRow extends StatelessWidget {
  final Debt debt;
  final bool expired;
  final bool canDelete;
  final VoidCallback onDelete;

  const _DebtBadgeRow({
    required this.debt,
    required this.expired,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = expired ? const Color(0xFF9CA3AF) : const Color(0xFFFEF3C7);
    final fg = expired ? const Color(0xFF4B5563) : const Color(0xFFB45309);
    final border =
        expired ? const Color(0xFFD1D5DB) : const Color(0xFFFDE68A);
    final dateStr = _formatDate(debt.debtEndingAt);
    final label = expired ? 'просрочено $dateStr' : 'до $dateStr';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.access_time : Icons.warning_amber_rounded,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  final String currentUserId;
  const _CommentsSection({required this.currentUserId});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  String? _editingId;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _startEdit(CatalogComment comment) {
    setState(() {
      _editingId = comment.id;
      _editController.text = comment.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(CommentsCubit cubit) async {
    if (_editingId == null) return;
    await cubit.updateOne(_editingId!, _editController.text);
    setState(() {
      _editingId = null;
      _editController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        final cubit = context.read<CommentsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state is CommentsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is CommentsError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCCC7)),
                ),
                child: Text(
                  'Ошибка: ${state.message}',
                  style: const TextStyle(color: Color(0xFFCF1322)),
                ),
              ),
            ] else if (state is CommentsLoaded) ...[
              if (state.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Комментариев пока нет',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                Column(
                  children: state.comments
                      .where((c) => c.parentId == null)
                      .map((c) => _commentCard(c, cubit))
                      .toList(),
                ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Добавить комментарий',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF007D88),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await cubit.create(text);
                  _controller.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007D88),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Добавить'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _commentCard(CatalogComment comment, CommentsCubit cubit) {
    final canModify = comment.userId == widget.currentUserId;
    final isEditingThis = _editingId == comment.id;
    String createdAt = comment.createdAt;
    final parsed = DateTime.tryParse(comment.createdAt);
    if (parsed != null) {
      createdAt = DateFormat('dd.MM.yyyy', 'ru_RU').format(parsed);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            createdAt,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          if (isEditingThis) ...[
            TextField(
              controller: _editController,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => _saveEdit(cubit),
                  child: const Text('Сохранить'),
                ),
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ] else ...[
            Text(
              comment.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
            if (canModify) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _startEdit(comment),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => cubit.deleteOne(comment.id),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
