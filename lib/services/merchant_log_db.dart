import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class MerchantLogDb {
  static Database? _db;
  static const _dbName = 'merchant_log.db';
  static const _dbVersion = 1;

  static final _defaultTags = [
    'Food',
    'Transport',
    'Bills',
    'Health',
    'Leisure',
    'Work',
    'Gifts',
    'Other',
  ];

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expense_tags (
        id         TEXT PRIMARY KEY,
        label      TEXT NOT NULL UNIQUE,
        use_count  INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id           TEXT PRIMARY KEY,
        amount       REAL NOT NULL,
        tag_id       TEXT NOT NULL,
        note         TEXT DEFAULT '',
        receipt_path TEXT DEFAULT '',
        created_at   TEXT NOT NULL,
        FOREIGN KEY (tag_id) REFERENCES expense_tags(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expenses_created_at ON expenses(created_at)',
    );

    // Seed default tags
    final now = DateTime.now().toUtc().toIso8601String();
    final batch = db.batch();
    for (var i = 0; i < _defaultTags.length; i++) {
      batch.insert('expense_tags', {
        'id': 'tag_default_$i',
        'label': _defaultTags[i],
        'use_count': 0,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations go here
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
