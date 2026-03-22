import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';


class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> {
  String _type = 'Sick Leave';
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date != null) {
      ctrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_fromCtrl.text.isEmpty || _toCtrl.text.isEmpty || _reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final auth = context.read<AppAuthProvider>();
      // Calculate days between from and to dates
      final fromDate = DateTime.parse(_fromCtrl.text);
      final toDate = DateTime.parse(_toCtrl.text);
      final days = toDate.difference(fromDate).inDays + 1;
      await context.read<DataProvider>().addLeave({
        'name': auth.user?['name'] ?? 'Teacher',
        'userId': auth.uid ?? '',
        'role': 'teacher',
        'type': _type,
        'from': _fromCtrl.text,
        'to': _toCtrl.text,
        'days': days,
        'reason': _reasonCtrl.text,
        'status': 'pending',
        'zone': auth.user?['zone'] ?? '',
        'centre': auth.user?['centre'] ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted!'), backgroundColor: Colors.green));
        _fromCtrl.clear();
        _toCtrl.clear();
        _reasonCtrl.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      child: Column(
        children: [
          const AppHeader(title: 'Leave Request', backTo: '/teacher'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppFormField(label: 'Leave Type', child: DropdownButtonFormField<String>(
                    value: _type,
                    items: ['Sick Leave', 'Personal', 'Vacation', 'Emergency'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                    decoration: const InputDecoration(),
                  )),
                  const SizedBox(height: 16),
                  AppFormField(label: 'From Date', child: TextField(controller: _fromCtrl, readOnly: true, onTap: () => _pickDate(_fromCtrl), decoration: const InputDecoration(hintText: 'Select start date', suffixIcon: Icon(Icons.calendar_today)))),
                  const SizedBox(height: 16),
                  AppFormField(label: 'To Date', child: TextField(controller: _toCtrl, readOnly: true, onTap: () => _pickDate(_toCtrl), decoration: const InputDecoration(hintText: 'Select end date', suffixIcon: Icon(Icons.calendar_today)))),
                  const SizedBox(height: 16),
                  AppFormField(label: 'Reason', child: TextField(controller: _reasonCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe your reason for leave...'))),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.send), label: const Text('Submit Request')),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
