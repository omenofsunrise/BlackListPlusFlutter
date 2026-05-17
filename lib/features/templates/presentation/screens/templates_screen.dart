import 'package:blacklist_plus_flutter/features/templates/data/document_template.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.white),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Шаблоны документов',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _DisclaimerBanner(),
            const SizedBox(height: 16),
            for (final template in kDocumentTemplates) ...[
              _TemplateCard(
                template: template,
                onTap: () => context.pushNamed(
                  Routes.templateDetailScreen.toName,
                  extra: template,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF92400E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Документы являются шаблонами-заготовками для самостоятельного '
              'заполнения и не заменяют юридическую консультацию. '
              'Юридическую силу приобретают после собственноручного подписания '
              'сторонами на бумажном носителе.',
              style: AppStyle.manrope(
                size: 12,
                weight: FontWeight.w400,
                height: 1.45,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(AppColors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(AppColors.uncomfPayment)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(AppColors.greenTie),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 22,
                  color: Color(AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      template.shortDescription,
                      style: AppStyle.manrope(
                        size: 13,
                        weight: FontWeight.w400,
                        height: 1.4,
                        color: const Color(AppColors.uiBorder),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Word (.docx) · нажмите для подробностей',
                      style: AppStyle.manrope(
                        size: 11,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.borderColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
