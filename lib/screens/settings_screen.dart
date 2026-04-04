// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;
  final VoidCallback? onSaved;

  const SettingsScreen({
    super.key,
    required this.settings,
    this.onSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _pythonPathCtrl;
  late TextEditingController _scriptPathCtrl;
  late TextEditingController _argumentsCtrl;
  late TextEditingController _intervalCtrl;
  late bool _autoSync;

  @override
  void initState() {
    super.initState();
    _pythonPathCtrl =
        TextEditingController(text: widget.settings.pythonPath);
    _scriptPathCtrl =
        TextEditingController(text: widget.settings.scriptPath);
    _argumentsCtrl =
        TextEditingController(text: widget.settings.arguments);
    _intervalCtrl =
        TextEditingController(text: widget.settings.autoSyncInterval.toString());
    _autoSync = widget.settings.autoSync;
  }

  @override
  void dispose() {
    _pythonPathCtrl.dispose();
    _scriptPathCtrl.dispose();
    _argumentsCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.settings.pythonPath = _pythonPathCtrl.text.trim();
    widget.settings.scriptPath = _scriptPathCtrl.text.trim();
    widget.settings.arguments = _argumentsCtrl.text.trim();
    widget.settings.autoSync = _autoSync;
    widget.settings.autoSyncInterval =
        int.tryParse(_intervalCtrl.text) ?? 30;
    widget.onSaved?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved!'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'monospace',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: 'Python Configuration'),
            const SizedBox(height: 12),
            _FieldCard(
              label: 'Python Executable Path',
              hint: 'e.g. python3 or C:\\Python311\\python.exe',
              controller: _pythonPathCtrl,
              icon: Icons.terminal_rounded,
            ),
            const SizedBox(height: 12),
            _FieldCard(
              label: 'Script Path',
              hint: 'e.g. /home/user/sync_script.py',
              controller: _scriptPathCtrl,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            _FieldCard(
              label: 'Arguments (optional)',
              hint: 'e.g. --mode full --verbose',
              controller: _argumentsCtrl,
              icon: Icons.settings_input_component_rounded,
            ),
            const SizedBox(height: 24),
            _SectionHeader(label: 'Auto Sync'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable Auto Sync',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Automatically run sync on a schedule',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    value: _autoSync,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (v) => setState(() => _autoSync = v),
                  ),
                  if (_autoSync) ...[
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Color(0xFF64748B), size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Interval (minutes)',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _intervalCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF3B82F6), width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'Save Settings',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const _FieldCard({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1), fontFamily: 'monospace'),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
