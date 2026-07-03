import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reading surface theme for the article reader.
enum ReaderTheme { light, sepia, dark }

extension ReaderThemeColors on ReaderTheme {
  Color get background => switch (this) {
    ReaderTheme.light => const Color(0xFFFFFFFF),
    ReaderTheme.sepia => const Color(0xFFF4ECD8),
    ReaderTheme.dark => const Color(0xFF15171C),
  };

  Color get text => switch (this) {
    ReaderTheme.light => const Color(0xFF1A1A1A),
    ReaderTheme.sepia => const Color(0xFF4B3E2A),
    ReaderTheme.dark => const Color(0xFFE6E6E6),
  };

  Color get muted => text.withValues(alpha: .6);
  bool get isDark => this == ReaderTheme.dark;
}

class ReaderSettings {
  final double fontScale; // 0.85 – 1.6
  final ReaderTheme theme;
  const ReaderSettings({this.fontScale = 1.0, this.theme = ReaderTheme.light});

  ReaderSettings copyWith({double? fontScale, ReaderTheme? theme}) =>
      ReaderSettings(fontScale: fontScale ?? this.fontScale, theme: theme ?? this.theme);
}

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = ReaderSettings(
      fontScale: p.getDouble('reader_font_scale') ?? 1.0,
      theme: ReaderTheme.values[(p.getInt('reader_theme') ?? 0).clamp(0, ReaderTheme.values.length - 1)],
    );
  }

  Future<void> setFontScale(double v) async {
    state = state.copyWith(fontScale: v.clamp(0.85, 1.6));
    (await SharedPreferences.getInstance()).setDouble('reader_font_scale', state.fontScale);
  }

  Future<void> setTheme(ReaderTheme t) async {
    state = state.copyWith(theme: t);
    (await SharedPreferences.getInstance()).setInt('reader_theme', t.index);
  }
}

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((_) => ReaderSettingsNotifier());
