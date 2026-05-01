import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/debt.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BlackCatalogCard extends StatelessWidget {
  final BlackCatalogItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool allowEdit;
  final bool allowDelete;

  const BlackCatalogCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.allowEdit = true,
    this.allowDelete = true,
  });

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Не указана';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd.MM.yyyy', 'ru_RU').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final validDebts = item.activeDebts;
    final hasValidDebts = validDebts.isNotEmpty;
    final isBlacklisted = item.isSwindler ?? false;
    final isDebtStatus = !isBlacklisted && hasValidDebts;
    final hasStatusBadge = isBlacklisted || isDebtStatus;
    final hasActions =
        (allowEdit && onEdit != null) || (allowDelete && onDelete != null);

    final borderColor = isDebtStatus
        ? const Color(0xFFF59E0B)
        : isBlacklisted
        ? const Color(0xFFEF4444)
        : const Color(0xFFD1D5DB);
    final gradientStart = Colors.white;
    final gradientEnd = isDebtStatus
        ? const Color(0xFFFFFBEB)
        : isBlacklisted
        ? const Color(0xFFFFF5F5)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (hasActions)
                Positioned(
                  top: 8,
                  right: 4,
                  child: PopupMenuButton<String>(
                    tooltip: 'Действия',
                    icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (allowEdit && onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Редактировать'),
                        ),
                      if (allowDelete && onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 56, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasStatusBadge) ...[
                      Row(
                        children: [
                          if (isBlacklisted)
                            const _Badge(
                              text: 'Чёрный список',
                              background: Color(0xFF000000),
                              foreground: Color(0xFFEF4444),
                            ),
                          if (isDebtStatus)
                            const _Badge(
                              text: 'Оформлен',
                              background: Color(0xFFF59E0B),
                              foreground: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    Text(
                      item.fullname.isEmpty ? 'Не указано' : item.fullname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _InfoBlock(
                          icon: Icons.badge_outlined,
                          label: 'ID',
                          value: item.id.toString(),
                          isWarning: isBlacklisted,
                          isDebt: isDebtStatus,
                        ),
                        _InfoBlock(
                          icon: Icons.cake_outlined,
                          label: 'Дата рождения',
                          value: _formatDate(item.birthdate),
                          isWarning: isBlacklisted,
                          isDebt: isDebtStatus,
                        ),
                        _InfoBlock(
                          icon: Icons.description_outlined,
                          label: 'Документ',
                          value: (item.doc?.isNotEmpty ?? false)
                              ? item.doc!
                              : 'Не указан',
                          isWarning: isBlacklisted,
                          isDebt: isDebtStatus,
                        ),
                        _InfoBlock(
                          icon: Icons.location_on_outlined,
                          label: 'Адрес',
                          value: (item.address?.isNotEmpty ?? false)
                              ? item.address!
                              : 'Не указан',
                          isWarning: isBlacklisted,
                          isDebt: isDebtStatus,
                        ),
                      ],
                    ),

                    if (hasValidDebts) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...validDebts.map(
                            (d) => _DebtBadge(debt: d, expired: false),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  final bool isDebt;

  const _InfoBlock({
    required this.icon,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: const Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtBadge extends StatelessWidget {
  final Debt debt;
  final bool expired;
  const _DebtBadge({required this.debt, required this.expired});

  @override
  Widget build(BuildContext context) {
    final bg = expired ? const Color(0xFF9CA3AF) : const Color(0xFFFEF3C7);
    final fg = expired ? const Color(0xFF4B5563) : const Color(0xFFB45309);
    final border = expired ? const Color(0xFFD1D5DB) : const Color(0xFFFDE68A);
    final dateStr = BlackCatalogCard._formatDate(debt.debtEndingAt);

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
            expired ? 'закрыто $dateStr' : 'до $dateStr',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
