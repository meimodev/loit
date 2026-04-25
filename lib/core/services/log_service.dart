import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized logger for LOIT.
///
/// All app logging routes through this class. Terminal output is color-coded
/// and prefixed with the source tag for quick scanning. Errors are forwarded
/// to Sentry automatically. PostHog/Sentry SDK noise is kept out of terminal
/// by filtering via [_suppressedPackages].
///
/// Usage:
/// ```dart
/// Log.d('SyncService', 'Starting auto-sync');
/// Log.i('PushService', 'FCM token refreshed');
/// Log.w('CurrencyService', 'Using stale FX rate');
/// Log.e('ScannerService', 'Scan failed', error: e, stack: st);
/// ```
class Log {
  Log._();

  // ANSI color codes for terminal readability
  static const _reset = '\x1B[0m';
  static const _gray = '\x1B[90m';
  static const _blue = '\x1B[34m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _cyan = '\x1B[36m';

  /// Packages whose verbose SDK logs we suppress in terminal.
  /// Their errors still reach Sentry via the SDK's own transport.
  static const _suppressedPackages = {
    'posthog',
    'sentry',
    'sentry_flutter',
    'supabase',
    'supabase_flutter',
    'firebase',
    'firebase_messaging',
    'firebase_core',
  };

  /// Whether to print logs. Automatically false in release mode.
  static bool _enabled = kDebugMode;

  /// Minimum level to print. Defaults to debug in debug mode.
  static LogLevel _minLevel = LogLevel.debug;

  /// Initialize logger settings. Call once in main().
  static void init({bool? enabled, LogLevel? minLevel}) {
    if (enabled != null) _enabled = enabled;
    if (minLevel != null) _minLevel = minLevel;
  }

  /// Debug — verbose tracing, stripped in release.
  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  /// Info — normal operational events.
  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  /// Warning — recoverable issues, degraded behavior.
  static void w(String tag, String message, {Object? error}) =>
      _log(LogLevel.warning, tag, message, error: error);

  /// Error — failures that need attention. Auto-sent to Sentry.
  static void e(String tag, String message, {Object? error, StackTrace? stack}) {
    _log(LogLevel.error, tag, message, error: error, stack: stack);
    // Forward to Sentry in all modes (debug + release)
    Sentry.captureException(
      error ?? Exception('[$tag] $message'),
      stackTrace: stack,
      withScope: (scope) {
        scope.setTag('log.tag', tag);
        scope.setContexts('log', {'message': message});
      },
    );
  }

  /// Lifecycle — app startup/shutdown milestones. Always visible.
  static void lifecycle(String message) {
    if (!_enabled) return;
    final time = _timestamp();
    debugPrint('$_green$time $_cyan▶ $_green$message$_reset');
  }

  /// Simplified one-liner for PostHog events in terminal.
  /// Shows: `12:34:56 📊 event_name {prop: val}`
  /// Instead of PostHog SDK's verbose multi-line output.
  static void analytics(String eventName, [Map<String, dynamic>? props]) {
    if (!_enabled || _minLevel.index > LogLevel.info.index) return;
    final time = _timestamp();
    final propsStr = props != null && props.isNotEmpty ? ' $props' : '';
    debugPrint('$_gray$time $_cyan📊 $eventName$propsStr$_reset');
  }

  /// Simplified Sentry breadcrumb log for terminal.
  /// Shows: `12:34:56 🛡️ category: message`
  static void sentry(String category, String message) {
    if (!_enabled || _minLevel.index > LogLevel.debug.index) return;
    final time = _timestamp();
    debugPrint('$_gray$time 🛡️ $category: $message$_reset');
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    if (!_enabled || level.index < _minLevel.index) return;

    // Suppress noisy SDK logs
    final tagLower = tag.toLowerCase();
    if (_suppressedPackages.any((p) => tagLower.contains(p)) &&
        level.index < LogLevel.warning.index) {
      return;
    }

    final time = _timestamp();
    final prefix = level.prefix;
    final color = level.color;

    final buf = StringBuffer('$color$time $prefix [$tag] $message$_reset');
    if (error != null) buf.write('\n${_red}Error: $error$_reset');
    if (stack != null) buf.write('\n$_gray$stack$_reset');

    debugPrint(buf.toString());

    // Also log to dart:developer for DevTools integration
    developer.log(
      message,
      name: tag,
      level: level.devToolsLevel,
      error: error,
      stackTrace: stack,
    );
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Log severity levels.
enum LogLevel {
  debug,
  info,
  warning,
  error;

  String get prefix => switch (this) {
    debug => '🔍',
    info => 'ℹ️',
    warning => '⚠️',
    error => '❌',
  };

  String get color => switch (this) {
    debug => Log._gray,
    info => Log._blue,
    warning => Log._yellow,
    error => Log._red,
  };

  int get devToolsLevel => switch (this) {
    debug => 500,
    info => 800,
    warning => 900,
    error => 1000,
  };
}
