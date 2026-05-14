/// BBZCloud Mobile - In-App Log Viewer
///
/// Reads from AppLogger.getBuffer() so Logs auch ohne USB-Kabel
/// auf dem Telefon angeschaut, kopiert oder geteilt werden können.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart' show Level;

import 'package:bbzcloud_mobil/core/utils/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _logger = AppLogger();
  final _scrollController = ScrollController();
  Level _minLevel = Level.info;
  bool _autoScroll = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _logger.addListener(_onLogChange);
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogChange() {
    if (!mounted) return;
    setState(() {});
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  List<LogEntry> get _filteredLogs {
    final all = _logger.getBuffer();
    return all.where((e) {
      if (e.level.index < _minLevel.index) return false;
      if (_filter.isEmpty) return true;
      final needle = _filter.toLowerCase();
      return e.message.toLowerCase().contains(needle) ||
          (e.error?.toLowerCase().contains(needle) ?? false);
    }).toList();
  }

  String _allLogsAsText() {
    return _filteredLogs.map((e) => e.formatLine()).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Kopieren',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final text = _allLogsAsText();
              await Clipboard.setData(ClipboardData(text: text));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs in die Zwischenablage kopiert'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Leeren',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _logger.clearBuffer();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                      hintText: 'Filtern (z.B. push, fcm, http)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<Level>(
                  value: _minLevel,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: Level.trace, child: Text('Alles')),
                    DropdownMenuItem(value: Level.debug, child: Text('Debug+')),
                    DropdownMenuItem(value: Level.info, child: Text('Info+')),
                    DropdownMenuItem(value: Level.warning, child: Text('Warn+')),
                    DropdownMenuItem(value: Level.error, child: Text('Error+')),
                  ],
                  onChanged: (v) =>
                      setState(() => _minLevel = v ?? Level.info),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  '${logs.length} Einträge',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text('Auto-Scroll', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _autoScroll,
                      onChanged: (v) => setState(() => _autoScroll = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Keine Logs vorhanden.\n'
                        'Öffne z.B. den Chat oder eine andere App, um Push-/Login-'
                        'Logs zu erzeugen.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final entry = logs[index];
                      return _LogTile(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});
  final LogEntry entry;

  Color _colorFor(BuildContext context, Level level) {
    final cs = Theme.of(context).colorScheme;
    switch (level) {
      case Level.error:
      case Level.fatal:
        return cs.error;
      case Level.warning:
        return Colors.orange;
      case Level.info:
        return cs.primary;
      case Level.debug:
        return cs.onSurfaceVariant;
      default:
        return cs.onSurfaceVariant.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, entry.level);
    final time = entry.timestamp.toIso8601String().substring(11, 23);
    return InkWell(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: entry.formatLine()));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zeile kopiert'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 3),
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.level.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SelectableText(
              entry.message,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            if (entry.error != null) ...[
              const SizedBox(height: 2),
              SelectableText(
                entry.error!,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
