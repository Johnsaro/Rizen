import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;
import '../models/expense_entry.dart';
import '../models/expense_tag.dart';
import 'merchant_log_db.dart';

class MerchantLogService {
  // ── Tags ──────────────────────────────────────────────

  /// All tags sorted by useCount desc, then alphabetical.
  Future<List<ExpenseTag>> loadTags() async {
    final db = await MerchantLogDb.database;
    final rows = await db.query(
      'expense_tags',
      orderBy: 'use_count DESC, label ASC',
    );
    return rows.map((r) => ExpenseTag.fromMap(r)).toList();
  }

  /// Creates a custom tag. Returns the new tag.
  Future<ExpenseTag> createTag(String label) async {
    final db = await MerchantLogDb.database;
    final now = DateTime.now();
    final id = 'tag_${now.microsecondsSinceEpoch}';
    final tag = ExpenseTag(id: id, label: label.trim(), createdAt: now);
    await db.insert('expense_tags', tag.toMap());
    return tag;
  }

  /// Deletes a tag. Reassigns orphaned expenses to "Other".
  Future<void> deleteTag(String tagId) async {
    final db = await MerchantLogDb.database;
    // Find the "Other" tag to reassign orphans
    final otherRows = await db.query(
      'expense_tags',
      where: 'label = ?',
      whereArgs: ['Other'],
      limit: 1,
    );
    if (otherRows.isEmpty) return; // safety
    final otherId = otherRows.first['id'] as String;

    await db.transaction((txn) async {
      await txn.update(
        'expenses',
        {'tag_id': otherId},
        where: 'tag_id = ?',
        whereArgs: [tagId],
      );
      await txn.delete('expense_tags', where: 'id = ?', whereArgs: [tagId]);
    });
  }

  // ── Expenses ──────────────────────────────────────────

  /// Inserts a new expense. Increments the tag's useCount.
  Future<ExpenseEntry> addExpense({
    required double amount,
    required String tagId,
    String note = '',
    String receiptPath = '',
  }) async {
    final db = await MerchantLogDb.database;
    final now = DateTime.now();
    final id = 'exp_${now.microsecondsSinceEpoch}';

    final entry = ExpenseEntry(
      id: id,
      amount: amount,
      tagId: tagId,
      note: note,
      receiptPath: receiptPath,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('expenses', entry.toMap());
      await txn.rawUpdate(
        'UPDATE expense_tags SET use_count = use_count + 1 WHERE id = ?',
        [tagId],
      );
    });

    // Return with tag label populated
    final tagRows = await db.query(
      'expense_tags',
      columns: ['label'],
      where: 'id = ?',
      whereArgs: [tagId],
      limit: 1,
    );
    final label = tagRows.isNotEmpty ? tagRows.first['label'] as String : '';

    return ExpenseEntry(
      id: entry.id,
      amount: entry.amount,
      tagId: entry.tagId,
      tagLabel: label,
      note: entry.note,
      receiptPath: entry.receiptPath,
      createdAt: entry.createdAt,
    );
  }

  /// All expenses for a given date range, newest first.
  Future<List<ExpenseEntry>> loadExpenses({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await MerchantLogDb.database;
    final rows = await db.rawQuery('''
      SELECT e.*, t.label AS tag_label
      FROM expenses e
      JOIN expense_tags t ON e.tag_id = t.id
      WHERE e.created_at >= ? AND e.created_at <= ?
      ORDER BY e.created_at DESC
    ''', [from.toUtc().toIso8601String(), to.toUtc().toIso8601String()]);
    return rows.map((r) => ExpenseEntry.fromMap(r)).toList();
  }

  /// Weekly totals grouped by tag label.
  Future<Map<String, double>> weeklyTotalsByTag({
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final db = await MerchantLogDb.database;
    final rows = await db.rawQuery('''
      SELECT t.label, SUM(e.amount) AS total
      FROM expenses e
      JOIN expense_tags t ON e.tag_id = t.id
      WHERE e.created_at >= ? AND e.created_at <= ?
      GROUP BY t.label
      ORDER BY total DESC
    ''', [
      weekStart.toUtc().toIso8601String(),
      weekEnd.toUtc().toIso8601String(),
    ]);
    return {
      for (final r in rows) r['label'] as String: (r['total'] as num).toDouble()
    };
  }

  /// Grand total for a date range.
  Future<double> totalSpent({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await MerchantLogDb.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses WHERE created_at >= ? AND created_at <= ?',
      [from.toUtc().toIso8601String(), to.toUtc().toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Today's total.
  Future<double> todayTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return totalSpent(from: start, to: end);
  }

  // ── Shred ─────────────────────────────────────────────

  /// Deletes all expenses in the given date range and their receipt photos.
  Future<int> shredExpenses({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await MerchantLogDb.database;
    final fromStr = from.toUtc().toIso8601String();
    final toStr = to.toUtc().toIso8601String();

    // Collect receipt paths before deleting
    final rows = await db.rawQuery(
      "SELECT receipt_path FROM expenses WHERE created_at >= ? AND created_at <= ? AND receipt_path != ''",
      [fromStr, toStr],
    );
    for (final row in rows) {
      await deleteReceiptPhoto(row['receipt_path'] as String);
    }

    final count = await db.delete(
      'expenses',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [fromStr, toStr],
    );
    return count;
  }

  // ── Receipt Photos ────────────────────────────────────

  Future<String> get _receiptDir async {
    final appDir = await pp.getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'merchant_log', 'receipts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Saves a photo from ImagePicker. Returns the relative path for DB storage.
  Future<String> saveReceiptPhoto(XFile photo) async {
    final dir = await _receiptDir;
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(dir, filename);
    await photo.saveTo(destPath);
    return 'merchant_log/receipts/$filename';
  }

  /// Resolves a relative receipt path to an absolute File path.
  Future<String> resolveReceiptPath(String relativePath) async {
    final appDir = await pp.getApplicationDocumentsDirectory();
    return p.join(appDir.path, relativePath);
  }

  /// Deletes a receipt photo file from disk.
  Future<void> deleteReceiptPhoto(String relativePath) async {
    if (relativePath.isEmpty) return;
    try {
      final fullPath = await resolveReceiptPath(relativePath);
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // File already gone — ignore
    }
  }
}
