import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';

class AddZone extends StatefulWidget {
  const AddZone({super.key});
  @override
  State<AddZone> createState() => _AddZoneState();
}

class _AddZoneState extends State<AddZone> {
  final _nameCtrl = TextEditingController();
  final _coordCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _coordCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter zone name.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      await context.read<DataProvider>().addZone({'name': _nameCtrl.text, 'coordinator': _coordCtrl.text.isEmpty ? 'Pending' : _coordCtrl.text});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zone added!'), backgroundColor: Colors.green));
        context.go('/admin/zones');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(child: Column(children: [
      const AppHeader(title: 'Add Zone', backTo: '/admin/zones'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        AppFormField(label: 'Zone Name', child: TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. North Zone'))),
        const SizedBox(height: 16),
        AppFormField(label: 'Coordinator (optional)', child: TextField(controller: _coordCtrl, decoration: const InputDecoration(hintText: 'Assign coordinator'))),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.add_location), label: const Text('Create Zone'))),
        const SizedBox(height: 100),
      ]))),
    ]));
  }
}
