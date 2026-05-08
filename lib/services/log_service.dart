import '../models/models.dart';
import 'database_service.dart';

// Alias so other files can use it without importing models directly
typedef SyncLogTypeAlias = SyncLogType;

class LogService {
  static LogService? _instance;
  LogService._();
  static LogService get instance {
    _instance ??= LogService._();
    return _instance!;
  }

  Future<void> log(SyncLogType type, String message,
      {String? details}) async {
    final entry = SyncLog(
      type: type,
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
    await DatabaseService.instance.insertLog(entry);
  }

  Future<List<SyncLog>> getLogs({int limit = 100}) =>
      DatabaseService.instance.getLogs(limit: limit);
}
