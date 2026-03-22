import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class AddCentre extends StatefulWidget {
  const AddCentre({super.key});
  @override
  State<AddCentre> createState() => _AddCentreState();
}

class _AddCentreState extends State<AddCentre> {
  final _nameCtrl = TextEditingController();
  String? _selectedZoneId;
  String? _selectedZoneName;

  @override
  void dispose() { 
    _nameCtrl.dispose(); 
    super.dispose(); 
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter centre name and select a zone.'), 
        backgroundColor: Colors.orange
      ));
      return;
    }
    
    try {
      await context.read<DataProvider>().addCentre({
        'name': _nameCtrl.text,
        'zoneId': _selectedZoneId,
        'zone': _selectedZoneName,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Centre added! Spreadsheet tab will be created shortly.'), 
          backgroundColor: Colors.green
        ));
        context.go('/admin/zones');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.red
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<DataProvider>().zones;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminLayout(
      child: Column(children: [
        const AppHeader(title: 'Add Centre', backTo: '/admin/zones'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              AppFormField(
                label: 'Centre Name', 
                child: TextField(
                  controller: _nameCtrl, 
                  decoration: const InputDecoration(hintText: 'e.g. Tejaswini')
                )
              ),
              const SizedBox(height: 16),
              AppFormField(
                label: 'Zone',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedZoneId,
                      hint: const Text('Select Zone'),
                      items: zones.map((z) => DropdownMenuItem(
                        value: z['id'] as String,
                        child: Text(z['name']),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedZoneId = val;
                          _selectedZoneName = zones.firstWhere((z) => z['id'] == val)['name'];
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, 
                height: 56, 
                child: ElevatedButton.icon(
                  onPressed: _submit, 
                  icon: const Icon(Icons.add_business), 
                  label: const Text('Add Centre')
                )
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ]),
    );
  }
}
