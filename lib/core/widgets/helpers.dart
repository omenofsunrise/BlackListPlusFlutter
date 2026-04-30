import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  String title = 'Подтвердите удаление',
  String content = 'Вы действительно хотите удалить клиента?',
  String cancelText = 'Отмена',
  String confirmText = 'Подтвердить',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Color(AppColors.background),
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(backgroundColor: Colors.transparent),
          child: Text(cancelText, style: const TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            backgroundColor: const Color(AppColors.primary),
          ),
          child: Text(confirmText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  return result == true;
}

void showMessage(String message, BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

final _avatarColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.brown,
  Colors.indigo,
];

String? _resolvePhotoUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return 'https://file.waypay.one${path.startsWith('/') ? '' : '/'}$path';
}

Color _getColorFromName(String name) {
  final hash = name.hashCode;
  final index = hash.abs() % _avatarColors.length;
  return _avatarColors[index];
}

String _getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return '';

  if (parts.length == 1) {
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
  }

  final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
  final last = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';

  return '$first$last';
}

Widget buildAvatar({String? fullName, String? photoPath, double radius = 70}) {
  if (fullName != null && fullName.isNotEmpty) {
    return _buildAvatarWidget(fullName, photoPath, radius);
  }

  return FutureBuilder<Map<String, dynamic>>(
    future: getIt<AuthRemoteDataSource>().getAuthInfo(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      }

      if (!snapshot.hasData) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey,
          child: const Icon(Icons.person, color: Colors.white),
        );
      }

      final employee = snapshot.data?['employee'] as Map<String, dynamic>?;
      final fetchedName = employee?['fullName'] as String? ?? '';
      final fetchedPhoto = employee?['photoPath'] as String?;

      return _buildAvatarWidget(fetchedName, fetchedPhoto, radius);
    },
  );
}

Widget _buildAvatarWidget(String fullName, String? photoPath, double radius) {
  final resolvedUrl = _resolvePhotoUrl(photoPath);

  if (resolvedUrl != null) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(resolvedUrl),
    );
  }

  final initials = _getInitials(fullName);

  return CircleAvatar(
    radius: radius,
    backgroundColor: _getColorFromName(fullName),
    child: Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.75,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
    ),
  );
}
