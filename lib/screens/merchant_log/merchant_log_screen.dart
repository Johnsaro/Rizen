import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_state.dart';
import '../../models/expense_entry.dart';
import '../../models/expense_tag.dart';
import '../../theme/app_theme.dart';
import '../../theme/night_guild_background.dart';

class MerchantLogScreen extends StatefulWidget {
  const MerchantLogScreen({super.key});

  @override
  State<MerchantLogScreen> createState() => _MerchantLogScreenState();
}

class _MerchantLogScreenState extends State<MerchantLogScreen> {
  int _selectedTab = 0; // 0 = Coin Purse, 1 = Ledger

  // ── Coin Purse state ──────────────────────────────────
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  List<ExpenseTag> _tags = [];
  String? _selectedTagId;
  XFile? _receiptPhoto;
  bool _isSubmitting = false;
  double _todayTotal = 0;

  // ── Ledger state ──────────────────────────────────────
  DateTime _weekStart = _mondayOfWeek(DateTime.now());
  List<ExpenseEntry> _weekExpenses = [];
  Map<String, double> _tagBreakdown = {};
  double _weekTotal = 0;
  bool _isLoadingLedger = false;
  bool _isShredding = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadTodayTotal();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static DateTime _mondayOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime get _weekEnd =>
      _weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  Future<void> _loadTags() async {
    final tags = await merchantLogService.loadTags();
    if (mounted) setState(() => _tags = tags);
  }

  Future<void> _loadTodayTotal() async {
    final total = await merchantLogService.todayTotal();
    if (mounted) setState(() => _todayTotal = total);
  }

  Future<void> _loadLedger() async {
    setState(() => _isLoadingLedger = true);
    final expenses = await merchantLogService.loadExpenses(
      from: _weekStart,
      to: _weekEnd,
    );
    final breakdown = await merchantLogService.weeklyTotalsByTag(
      weekStart: _weekStart,
      weekEnd: _weekEnd,
    );
    final total = await merchantLogService.totalSpent(
      from: _weekStart,
      to: _weekEnd,
    );
    if (mounted) {
      setState(() {
        _weekExpenses = expenses;
        _tagBreakdown = breakdown;
        _weekTotal = total;
        _isLoadingLedger = false;
      });
    }
  }

  Future<void> _submitExpense() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || _selectedTagId == null) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0 || amount > 999999.99) return;

    setState(() => _isSubmitting = true);

    try {
      String receiptPath = '';
      if (_receiptPhoto != null) {
        receiptPath = await merchantLogService.saveReceiptPhoto(_receiptPhoto!);
      }

      await merchantLogService.addExpense(
        amount: amount,
        tagId: _selectedTagId!,
        note: _noteController.text.trim(),
        receiptPath: receiptPath,
      );

      await gameService.awardMerchantLogQi();

      // Reset form
      _amountController.clear();
      _noteController.clear();
      _receiptPhoto = null;
      _selectedTagId = null;

      await _loadTodayTotal();
      await _loadTags(); // refresh use counts

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense logged. +10 Qi.',
              style: GoogleFonts.inter(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log expense: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickReceipt() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 70,
    );
    if (photo != null && mounted) {
      setState(() => _receiptPhoto = photo);
    }
  }

  Future<void> _shredLedger() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text(
            'Shred the Ledger?',
            style: AppTheme.sectionHeaderStyle.copyWith(fontSize: 16),
          ),
          content: Text(
            'This will permanently delete all expenses from '
            '${_formatDate(_weekStart)} to ${_formatDate(_weekEnd)} '
            'and their receipt photos. This cannot be undone.',
            style: GoogleFonts.inter(color: cs.onSurface, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('SHRED', style: TextStyle(color: cs.error)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isShredding = true);
    await merchantLogService.shredExpenses(from: _weekStart, to: _weekEnd);
    await _loadLedger();
    await _loadTodayTotal();
    if (mounted) {
      setState(() => _isShredding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ledger shredded.', style: GoogleFonts.inter()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddTagDialog() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text('New Tag', style: AppTheme.sectionHeaderStyle.copyWith(fontSize: 14)),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Tag name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (label != null && label.isNotEmpty) {
      // Sanitize: 2-20 chars, letters/numbers/spaces only
      if (label.length < 2 || label.length > 20 || !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(label)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tag must be 2-20 characters, letters and numbers only.')),
          );
        }
        return;
      }
      try {
        final tag = await merchantLogService.createTag(label);
        await _loadTags();
        if (mounted) setState(() => _selectedTagId = tag.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tag already exists or invalid.')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _formatAmount(double amount) => amount.toStringAsFixed(2);

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(cs),
              _buildTabRow(cs),
              Expanded(
                child: _selectedTab == 0
                    ? _buildCoinPurse(cs)
                    : _buildLedger(cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios,
                color: cs.onSurface.withValues(alpha: 0.5), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            "MERCHANT'S LOG",
            style: AppTheme.sectionHeaderStyle,
          ),
          const Spacer(),
          Text(
            'TODAY: ${_formatAmount(_todayTotal)}',
            style: AppTheme.statNumberStyle.copyWith(color: cs.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTab('COIN PURSE', 0, cs),
          const SizedBox(width: 24),
          _buildTab('LEDGER', 1, cs),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, ColorScheme cs) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 1) _loadLedger();
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? cs.secondary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.sectionHeaderStyle.copyWith(
            fontSize: 11,
            color: isSelected ? cs.secondary : cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  // ── COIN PURSE TAB ────────────────────────────────────

  Widget _buildCoinPurse(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount input
          _buildAmountInput(cs),
          const SizedBox(height: 20),

          // Tag selector
          Text('TAG', style: AppTheme.sectionHeaderStyle.copyWith(fontSize: 10)),
          const SizedBox(height: 8),
          _buildTagSelector(cs),
          const SizedBox(height: 20),

          // Note field
          TextField(
            controller: _noteController,
            style: GoogleFonts.inter(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Note (optional)',
              prefixIcon: Icon(Icons.note_outlined, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 16),

          // Receipt photo
          _buildReceiptRow(cs),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitExpense,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: cs.onPrimary),
                        const SizedBox(width: 8),
                        Text('LOG EXPENSE', style: GoogleFonts.cinzel(
                            fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'PHP',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.8), // Gold accent
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                LengthLimitingTextInputFormatter(10), // max "999999.99" + margin
              ],
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: cs.secondary.withValues(alpha: 0.2),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._tags.map((tag) {
          final isSelected = _selectedTagId == tag.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedTagId = tag.id),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cs.secondary.withValues(alpha: 0.15) : cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.secondary : cs.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  tag.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? cs.secondary : cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }),
        // Add tag button
        GestureDetector(
          onTap: _showAddTagDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: cs.primary),
                const SizedBox(width: 4),
                Text('New', style: GoogleFonts.inter(fontSize: 13, color: cs.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(ColorScheme cs) {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickReceipt,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_outlined, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  _receiptPhoto != null ? 'Receipt attached' : 'Add receipt',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_receiptPhoto != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _receiptPhoto = null),
            child: Icon(Icons.close, size: 18, color: cs.error),
          ),
        ],
      ],
    );
  }

  // ── LEDGER TAB ────────────────────────────────────────

  Widget _buildLedger(ColorScheme cs) {
    if (_isLoadingLedger) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week selector
          _buildWeekSelector(cs),
          const SizedBox(height: 20),

          // Weekly total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              children: [
                Text('WEEKLY TOTAL', style: AppTheme.sectionHeaderStyle.copyWith(fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  _formatAmount(_weekTotal),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tag breakdown
          if (_tagBreakdown.isNotEmpty) ...[
            Text('BY CATEGORY', style: AppTheme.sectionHeaderStyle.copyWith(fontSize: 10)),
            const SizedBox(height: 8),
            ..._buildTagBreakdown(cs),
            const SizedBox(height: 20),
          ],

          // Expense list
          if (_weekExpenses.isNotEmpty) ...[
            Text('ENTRIES', style: AppTheme.sectionHeaderStyle.copyWith(fontSize: 10)),
            const SizedBox(height: 8),
            ..._weekExpenses.map((e) => _buildExpenseCard(e, cs)),
            const SizedBox(height: 20),
          ],

          if (_weekExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No entries this week.',
                  style: GoogleFonts.inter(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Shred button
          if (_weekExpenses.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: GestureDetector(
                onTap: _isShredding ? null : _shredLedger,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    border: Border.all(color: cs.error.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _isShredding
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.error,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department_outlined, size: 18, color: cs.error),
                            const SizedBox(width: 8),
                            Text(
                              'SHRED THE LEDGER',
                              style: GoogleFonts.cinzel(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: cs.error,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(ColorScheme cs) {
    final now = DateTime.now();
    final currentWeekStart = _mondayOfWeek(now);
    final isCurrentWeek = _weekStart == currentWeekStart;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
            _loadLedger();
          },
          child: Icon(Icons.chevron_left, color: cs.onSurface, size: 28),
        ),
        const SizedBox(width: 16),
        Text(
          '${_formatDate(_weekStart)} - ${_formatDate(_weekEnd)}',
          style: AppTheme.statNumberStyle.copyWith(fontSize: 14, color: cs.onSurface),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: isCurrentWeek
              ? null
              : () {
                  setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
                  _loadLedger();
                },
          child: Icon(
            Icons.chevron_right,
            color: isCurrentWeek ? cs.onSurface.withValues(alpha: 0.2) : cs.onSurface,
            size: 28,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTagBreakdown(ColorScheme cs) {
    final maxAmount = _tagBreakdown.values.fold(0.0, (a, b) => a > b ? a : b);
    return _tagBreakdown.entries.map((entry) {
      final fraction = maxAmount > 0 ? entry.value / maxAmount : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface)),
                Text(
                  _formatAmount(entry.value),
                  style: AppTheme.statNumberStyle.copyWith(color: cs.secondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: cs.outline,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildExpenseCard(ExpenseEntry entry, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          if (entry.hasReceipt)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<String>(
                  future: merchantLogService.resolveReceiptPath(entry.receiptPath),
                  builder: (_, snap) {
                    if (!snap.hasData) return const SizedBox(width: 40, height: 40);
                    return Image.file(
                      File(snap.data!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.image_not_supported,
                        size: 24,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.tagLabel,
                          style: GoogleFonts.inter(fontSize: 11, color: cs.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatAmount(entry.amount),
                      style: AppTheme.statNumberStyle.copyWith(
                        fontSize: 14,
                        color: cs.secondary,
                      ),
                    ),
                  ],
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                  style: AppTheme.skillHintStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
