import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TeacherDiary extends StatefulWidget {
  const TeacherDiary({super.key});

  @override
  State<TeacherDiary> createState() => _TeacherDiaryState();
}

class _TeacherDiaryState extends State<TeacherDiary> {
  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _category = 'general';
  final _scrollCtrl = ScrollController();
  String? _editingId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _editEntry(Map<String, dynamic> e) {
    setState(() {
      _showForm = true;
      _editingId = e['id'];
      _titleCtrl.text = e['title'] ?? '';
      _bodyCtrl.text = e['body'] ?? '';
      _category = e['category'] ?? 'general';
    });
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await context.read<DataProvider>().deleteDiaryEntry(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diary entry deleted'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _addEntry() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final now = DateTime.now();
      final auth = context.read<AppAuthProvider>();
      final dataProvider = context.read<DataProvider>();
      
      final entryData = {
        'title': _titleCtrl.text,
        'body': _bodyCtrl.text,
        'category': _category,
        'time': DateFormat('hh:mm a').format(now),
        'date': DateFormat('yyyy-MM-dd').format(now),
      };

      if (_editingId != null) {
        await dataProvider.updateDiaryEntry(_editingId!, entryData);
      } else {
        await dataProvider.addDiaryEntry(entryData); // addDiaryEntry automatically appends teacher_id
      }

      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        setState(() {
          _showForm = false;
          _editingId = null;
        });
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingId != null ? 'Diary entry updated!' : 'Diary entry added!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawEntries = context.watch<DataProvider>().diaryEntries;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort entries newest first by date + time
    final entries = List<Map<String, dynamic>>.from(rawEntries);
    entries.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      final cmp = dateB.compareTo(dateA);
      if (cmp != 0) return cmp;
      final timeA = a['time']?.toString() ?? '';
      final timeB = b['time']?.toString() ?? '';
      return timeB.compareTo(timeA);
    });

    final categoryColors = {
      'event': const Color(0xFF3B82F6),
      'planning': const Color(0xFFF59E0B),
      'general': const Color(0xFF64748B),
    };

    return TeacherLayout(
      child: Column(
        children: [
          AppHeader(
            title: 'Teacher Diary',
            backTo: '/teacher',
            rightActions: [
              IconButton(icon: Icon(_showForm ? Icons.close : Icons.add, color: AppTheme.primary), onPressed: () => setState(() => _showForm = !_showForm)),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_showForm) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Entry title')),
                          const SizedBox(height: 12),
                          TextField(controller: _bodyCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Write your notes...')),
                          const SizedBox(height: 12),
                          Row(
                            children: ['general', 'event', 'planning'].map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChipWidget(label: c[0].toUpperCase() + c.substring(1), active: _category == c, onTap: () => setState(() => _category = c)),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton(onPressed: _addEntry, child: const Text('Save Entry')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ─── Diary Entries (newest first) ───
                  ...entries.map((e) => _buildEntryCard(e, categoryColors, isDark)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> e, Map<String, Color> categoryColors, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(e['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (categoryColors[e['category']] ?? Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text((e['category'] ?? 'general').toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColors[e['category']] ?? Colors.grey)),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _editEntry(e);
                  } else if (val == 'delete' && e['id'] != null) {
                    _deleteEntry(e['id']);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(e['body'] ?? '', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 8),
          Text('${e['time']} · ${e['date']}', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))),
          if (e['tags'] != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: (e['tags'] as List).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(t.toString(), style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
