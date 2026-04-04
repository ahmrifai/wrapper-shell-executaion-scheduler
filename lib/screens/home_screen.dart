// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_entry.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../widgets/log_entry_tile.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settings;

  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SyncService _syncService = SyncService();
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  late Timer _clockTimer;
  Timer? _autoSyncTimer;
  DateTime _now = DateTime.now();
  bool _isSyncing = false;
  DateTime? _lastSync;

  static const _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  static const _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();

    _lastSync = widget.settings.lastSync;

    // Clock ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    // Listen to log stream
    _syncService.logStream.listen((entry) {
      setState(() {
        _logs.add(entry);
      });
      // Auto scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    // Listen to syncing state
    _syncService.syncingStream.listen((syncing) {
      setState(() {
        _isSyncing = syncing;
        if (!syncing && _syncService.lastSync != null) {
          _lastSync = _syncService.lastSync;
          widget.settings.lastSync = _lastSync;
        }
      });
    });

    _setupAutoSync();
  }

  void _setupAutoSync() {
    _autoSyncTimer?.cancel();
    if (widget.settings.autoSync) {
      final interval = Duration(minutes: widget.settings.autoSyncInterval);
      _autoSyncTimer = Timer.periodic(interval, (_) => _runSync());
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _autoSyncTimer?.cancel();
    _syncService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _runSync() {
    if (_isSyncing) return;
    final scriptPath = widget.settings.scriptPath;
    if (scriptPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️  Script path not configured. Open Settings first.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    final args = widget.settings.arguments.trim().isEmpty
        ? <String>[]
        : widget.settings.arguments.trim().split(' ');

    _syncService.runSync(
      pythonPath: widget.settings.pythonPath,
      scriptPath: scriptPath,
      arguments: args,
    );
  }

  String get _formattedDate {
    final day = _days[_now.weekday - 1];
    final month = _months[_now.month];
    return '$day, ${_now.day} $month ${_now.year}';
  }

  String get _formattedTime {
    return DateFormat('HH:mm:ss').format(_now);
  }

  String _formatLastSync(DateTime? dt) {
    if (dt == null) return 'Never';
    final day = _days[dt.weekday - 1];
    final month = _months[dt.month];
    final time = DateFormat('HH:mm:ss').format(dt);
    return '$day, ${dt.day} $month ${dt.year} $time';
  }

  void _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        settings: widget.settings,
        onSaved: () {
          setState(() {});
          _setupAutoSync();
        },
      ),
    ));
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildLogPanel(),
                    const SizedBox(height: 12),
                    _buildFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Clock + Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  fontFamily: 'monospace',
                  letterSpacing: -1,
                ),
              ),
              Text(
                _formattedDate.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Action buttons
          Row(
            children: [
              // Clear logs button
              _HeaderIconButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: 'Clear Logs',
                color: const Color(0xFF64748B),
                onTap: _logs.isEmpty ? null : _clearLogs,
              ),
              const SizedBox(width: 10),
              // Settings
              _HeaderIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                color: const Color(0xFF475569),
                onTap: _openSettings,
              ),
              const SizedBox(width: 10),
              // Sync button
              _SyncButton(
                isSyncing: _isSyncing,
                onTap: _isSyncing ? null : _runSync,
                onStop: _isSyncing ? _syncService.stopSync : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Panel header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded,
                      color: Color(0xFF94A3B8), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'SYNC LOGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (_isSyncing)
                    Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Running...',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (!_isSyncing)
                    Text(
                      '${_logs.length} entries',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // Log list
            Expanded(
              child: _logs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => LogEntryTile(entry: _logs[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal_rounded,
              size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'No logs yet',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Press Sync to run the script',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        const Icon(Icons.sync_rounded, color: Color(0xFF3B82F6), size: 16),
        const SizedBox(width: 8),
        Text(
          'Last sync:  ${_formatLastSync(_lastSync)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (widget.settings.autoSync)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: Color(0xFF3B82F6), size: 12),
                const SizedBox(width: 4),
                Text(
                  'Auto sync every ${widget.settings.autoSyncInterval}m',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Header icon button ────────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
              color: onTap == null ? const Color(0xFFF8FAFC) : Colors.white,
            ),
            child: Icon(
              icon,
              color: onTap == null ? const Color(0xFFCBD5E1) : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Sync button ──────────────────────────────────────────────────────

class _SyncButton extends StatefulWidget {
  final bool isSyncing;
  final VoidCallback? onTap;
  final VoidCallback? onStop;

  const _SyncButton({
    required this.isSyncing,
    this.onTap,
    this.onStop,
  });

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(_SyncButton old) {
    super.didUpdateWidget(old);
    if (widget.isSyncing) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isSyncing ? 'Stop Sync' : 'Run Sync Now',
      child: GestureDetector(
        onTap: widget.isSyncing ? widget.onStop : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSyncing
                ? const Color(0xFFFEF2F2)
                : const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSyncing
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFF2563EB),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              RotationTransition(
                turns: _ctrl,
                child: Icon(
                  widget.isSyncing ? Icons.stop_rounded : Icons.sync_rounded,
                  color: widget.isSyncing
                      ? const Color(0xFFEF4444)
                      : Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isSyncing ? 'Stop' : 'Sync Now',
                style: TextStyle(
                  color: widget.isSyncing
                      ? const Color(0xFFEF4444)
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
