import 'dart:convert';

import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';

/// Codec to encode and decode full Ledgerly JSON backup archives.
class BackupJsonCodec {
  const BackupJsonCodec({this.appVersion = '1.0.0+1'});

  static const int currentVersion = 1;
  final String appVersion;

  /// Serializes database snapshot into a formatted JSON string.
  String encode({
    required Map<String, String> settings,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> transactions,
    int? exportedAtUtcMillis,
  }) {
    final payload = <String, dynamic>{
      'ledgerly_backup_version': currentVersion,
      'app_version': appVersion,
      'exported_at':
          exportedAtUtcMillis ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      'settings': settings,
      'categories': categories,
      'transactions': transactions,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Deserializes [jsonString] into a structured backup map and verifies validity.
  Map<String, dynamic> decode(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup: root must be a JSON object');
    }

    final version = decoded['ledgerly_backup_version'];
    if (version == null || version is! int) {
      throw const FormatException(
        'Invalid backup: missing ledgerly_backup_version',
      );
    }

    if (version > currentVersion) {
      throw FormatException(
        'Backup version $version is newer than current app version $currentVersion. Please update Ledgerly.',
      );
    }

    final categories = decoded['categories'];
    if (categories != null && categories is! List) {
      throw const FormatException('Invalid backup: categories must be a list');
    }

    final transactions = decoded['transactions'];
    if (transactions != null && transactions is! List) {
      throw const FormatException(
        'Invalid backup: transactions must be a list',
      );
    }

    return decoded;
  }

  /// Extracts metadata from raw [jsonString] without parsing entire body.
  BackupMetadata extractMetadata(String jsonString) {
    final decoded = decode(jsonString);
    return BackupMetadata(
      version: decoded['ledgerly_backup_version'] as int,
      exportedAtUtcMillis: decoded['exported_at'] as int? ?? 0,
      appVersion: decoded['app_version'] as String? ?? 'unknown',
      categoryCount: (decoded['categories'] as List?)?.length ?? 0,
      transactionCount: (decoded['transactions'] as List?)?.length ?? 0,
    );
  }
}
