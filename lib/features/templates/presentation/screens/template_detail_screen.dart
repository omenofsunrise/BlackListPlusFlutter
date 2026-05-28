import 'dart:io';

import 'package:blacklist_plus_flutter/features/templates/data/document_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chs_ui/chs_styles.dart';

class TemplateDetailScreen extends StatefulWidget {
  final DocumentTemplate template;

  const TemplateDetailScreen({super.key, required this.template});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  bool _busy = false;

  Future<File> _copyAssetToTemp() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${widget.template.fileName}');
    final data = await rootBundle.load(widget.template.assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _copyAssetToTemp();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: _docxMime)],
        subject: widget.template.title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть шаблон: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return Scaffold(
      backgroundColor: const Color(AppColors.white),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: t.title,
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    t.shortDescription,
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w400,
                      height: 1.5,
                      color: const Color(AppColors.uiBorder),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    icon: Icons.help_outline,
                    title: 'Когда использовать',
                    body: Text(
                      t.whenToUse,
                      style: _bodyStyle,
                    ),
                  ),
                  _Section(
                    icon: Icons.checklist_rtl,
                    title: 'Что нужно заполнить',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final field in t.fieldsToFill)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: _bodyStyle),
                                Expanded(
                                  child: Text(field, style: _bodyStyle),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Section(
                    icon: Icons.edit_outlined,
                    title: 'Кто подписывает',
                    body: Text(t.whoSigns, style: _bodyStyle),
                  ),
                  _Section(
                    icon: Icons.content_copy_outlined,
                    title: 'Количество экземпляров',
                    body: Text(t.copies, style: _bodyStyle),
                  ),
                  _Section(
                    icon: Icons.arrow_forward,
                    title: 'Что делать дальше',
                    body: Text(t.whatNext, style: _bodyStyle),
                  ),
                  if (t.legalNote != null)
                    _Section(
                      icon: Icons.gavel_outlined,
                      title: 'Юридическая справка',
                      body: Text(t.legalNote!, style: _bodyStyle),
                    ),
                  const SizedBox(height: 8),
                  const _DisclaimerBanner(),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: DefaultButton(
                  text: _busy ? 'Подготовка...' : 'Скачать в Word',
                  isPrimary: true,
                  showIcon: true,
                  iconWidget: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(AppColors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.ios_share,
                          size: 18,
                          color: Color(AppColors.white),
                        ),
                  onPressed: _busy ? null : _share,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _docxMime =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

final TextStyle _bodyStyle = AppStyle.manrope(
  size: 14,
  weight: FontWeight.w400,
  height: 1.5,
  color: const Color(AppColors.black),
);

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget body;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(AppColors.primary)),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppStyle.manrope(
                  size: 15,
                  weight: FontWeight.w600,
                  color: const Color(AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: body,
          ),
        ],
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
              'Документ является шаблоном для самостоятельного заполнения '
              'и не заменяет юридическую консультацию. Юридическую силу '
              'приобретает после собственноручного подписания сторонами '
              'на бумажном носителе.',
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
