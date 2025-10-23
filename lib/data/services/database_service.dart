/// BBZCloud Mobile - Database Service
/// 
/// SQLite database management
/// 
/// @version 0.1.0

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/exceptions/app_exceptions.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/models/user.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConfig.databaseName);

    return await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_apps (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        user_id INTEGER,
        order_index INTEGER DEFAULT 0,
        is_visible INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_visibility (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        is_visible INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_order (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        UNIQUE(app_id, user_id),
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE browser_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_id TEXT NOT NULL,
        url TEXT NOT NULL,
        title TEXT,
        visited_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations here
  }

  // ============================================================================
  // USER OPERATIONS
  // ============================================================================

  /// Insert or update user
  Future<int> saveUser(User user) async {
    try {
      final db = await database;
      
      return await db.transaction((txn) async {
        // Check if user exists
        final existing = await txn.query(
          'user_profile',
          where: 'email = ?',
          whereArgs: [user.email],
        );

        if (existing.isNotEmpty) {
          // Update existing user
          await txn.update(
            'user_profile',
            {
              ...user.toMap(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'email = ?',
            whereArgs: [user.email],
          );
          logger.info('User updated: ${user.email}');
          return existing.first['id'] as int;
        } else {
          // Insert new user
          final id = await txn.insert('user_profile', {
            ...user.toMap(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          logger.info('User created: ${user.email} (ID: $id)');
          return id;
        }
      });
    } catch (e, stackTrace) {
      logger.error('Error saving user: ${user.email}', e, stackTrace);
      throw DatabaseException.transaction('Failed to save user: $e');
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'user_profile',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Get current user (should only be one)
  Future<User?> getCurrentUser() async {
    final db = await database;
    final results = await db.query(
      'user_profile',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  // ============================================================================
  // SETTINGS OPERATIONS
  // ============================================================================

  /// Get setting by key
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// Save setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all settings as map
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final results = await db.query('settings');
    
    return {
      for (var row in results)
        row['key'] as String: row['value'] as String,
    };
  }

  // ============================================================================
  // CUSTOM APPS OPERATIONS
  // ============================================================================

  /// Get all custom apps for a user
  Future<List<CustomApp>> getCustomApps(int? userId) async {
    final db = await database;
    final results = await db.query(
      'custom_apps',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'order_index ASC',
    );

    return results.map((map) => CustomApp.fromMap(map)).toList();
  }

  /// Save custom app
  Future<void> saveCustomApp(CustomApp app) async {
    final db = await database;
    await db.insert(
      'custom_apps',
      app.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update custom app
  Future<void> updateCustomApp(CustomApp app) async {
    final db = await database;
    await db.update(
      'custom_apps',
      {
        ...app.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [app.id],
    );
  }

  /// Delete custom app
  Future<void> deleteCustomApp(String appId) async {
    final db = await database;
    await db.delete(
      'custom_apps',
      where: 'id = ?',
      whereArgs: [appId],
    );
  }

  // ============================================================================
  // APP VISIBILITY OPERATIONS
  // ============================================================================

  /// Get app visibility for user
  Future<Map<String, bool>> getAppVisibility(int userId) async {
    final db = await database;
    final results = await db.query(
      'app_visibility',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return {
      for (var row in results)
        row['app_id'] as String: (row['is_visible'] as int) == 1,
    };
  }

  /// Set app visibility
  Future<void> setAppVisibility(int userId, String appId, bool isVisible) async {
    final db = await database;
    
    await db.insert(
      'app_visibility',
      {
        'app_id': appId,
        'user_id': userId,
        'is_visible': isVisible ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================================================================
  // APP ORDER OPERATIONS
  // ============================================================================

  /// Get app order for user
  Future<Map<String, int>> getAppOrder(int userId) async {
    final db = await database;
    final results = await db.query(
      'app_order',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return {
      for (var row in results)
        row['app_id'] as String: row['order_index'] as int,
    };
  }

  /// Set app order
  Future<void> setAppOrder(int userId, String appId, int orderIndex) async {
    final db = await database;
    
    await db.insert(
      'app_order',
      {
        'app_id': appId,
        'user_id': userId,
        'order_index': orderIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch update app orders with transaction safety
  Future<void> updateAppOrders(int userId, Map<String, int> orders) async {
    try {
      final db = await database;
      
      await db.transaction((txn) async {
        final batch = txn.batch();

        for (var entry in orders.entries) {
          batch.insert(
            'app_order',
            {
              'app_id': entry.key,
              'user_id': userId,
              'order_index': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });
      
      logger.info('Updated ${orders.length} app orders for user $userId');
    } catch (e, stackTrace) {
      logger.error('Error updating app orders for user $userId', e, stackTrace);
      throw DatabaseException.transaction('Failed to update app orders: $e');
    }
  }

  // ============================================================================
  // BROWSER HISTORY OPERATIONS
  // ============================================================================

  /// Add to browser history
  Future<void> addBrowserHistory({
    required String appId,
    required String url,
    String? title,
  }) async {
    final db = await database;
    await db.insert('browser_history', {
      'app_id': appId,
      'url': url,
      'title': title,
      'visited_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get browser history
  Future<List<Map<String, dynamic>>> getBrowserHistory({
    String? appId,
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      'browser_history',
      where: appId != null ? 'app_id = ?' : null,
      whereArgs: appId != null ? [appId] : null,
      orderBy: 'visited_at DESC',
      limit: limit,
    );
  }

  /// Clear browser history
  Future<void> clearBrowserHistory({String? appId}) async {
    final db = await database;
    
    if (appId != null) {
      await db.delete(
        'browser_history',
        where: 'app_id = ?',
        whereArgs: [appId],
      );
    } else {
      await db.delete('browser_history');
    }
  }

  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing or reset)
  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConfig.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
