import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/translations.dart';

// ── Exchange rates relative to INR ───────────────────────────────────────────
const _rates = {
  'INR': 1.0,
  'USD': 0.012,
  'EUR': 0.011,
  'AED': 0.044,
  'GBP': 0.0095,
};

const _symbols = {
  'INR': '₹',
  'USD': '\$',
  'EUR': '€',
  'AED': 'د.إ',
  'GBP': '£',
};

// ── State ─────────────────────────────────────────────────────────────────────
class LocaleState {
  final String language;
  final String currency;

  const LocaleState({
    this.language = 'English',
    this.currency = 'INR',
  });

  LocaleState copyWith({String? language, String? currency}) => LocaleState(
        language: language ?? this.language,
        currency: currency ?? this.currency,
      );

  String get currencySymbol => _symbols[currency] ?? '₹';
  double get exchangeRate => _rates[currency] ?? 1.0;

  /// Format a price originally in INR into the user's chosen currency.
  /// Uses L/K shorthand for INR; standard K notation for foreign currencies.
  String formatPrice(num priceInr) {
    if (currency == 'INR') {
      if (priceInr >= 10000000) {
        final crore = priceInr / 10000000;
        return '₹${crore.toStringAsFixed(crore % 1 == 0 ? 0 : 1)}Cr';
      } else if (priceInr >= 100000) {
        final lakh = priceInr / 100000;
        return '₹${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 1)}L';
      } else if (priceInr >= 1000) {
        final k = priceInr / 1000;
        return '₹${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}K';
      }
      return '₹${priceInr.toStringAsFixed(0)}';
    }

    final converted = priceInr * exchangeRate;
    final symbol = currencySymbol;
    if (converted >= 1000) {
      final k = converted / 1000;
      return '$symbol${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}K';
    }
    return '$symbol${converted.toStringAsFixed(0)}';
  }

  /// Format a price per night label.
  String formatPricePerNight(num priceInr) => '${formatPrice(priceInr)} / night';

  /// Translate a UI key into the current language.
  String t(String key) => AppTranslations.t(key, language);
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class LocaleNotifier extends Notifier<LocaleState> {
  static const _keyLanguage = 'locale_language';
  static const _keyCurrency = 'locale_currency';

  // Maps native-script names (old storage format) → English code (current format)
  static const _nativeToCode = {
    'हिन्दी': 'Hindi',
    'தமிழ்': 'Tamil',
    'తెలుగు': 'Telugu',
    'বাংলা': 'Bengali',
    'मराठी': 'Marathi',
    'English': 'English',
  };

  static String _normalize(String lang) => _nativeToCode[lang] ?? lang;

  @override
  LocaleState build() {
    _load();
    return const LocaleState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_keyLanguage);
    final curr = prefs.getString(_keyCurrency);
    // Normalize: old code stored native script names, new code stores English codes
    final newLang = lang != null ? _normalize(lang) : state.language;
    final newCurr = curr ?? state.currency;
    if (newLang != state.language || newCurr != state.currency) {
      state = LocaleState(language: newLang, currency: newCurr);
    }
  }

  Future<void> setLanguage(String language) async {
    final code = _normalize(language);
    state = state.copyWith(language: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  Future<void> setCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final localeProvider =
    NotifierProvider<LocaleNotifier, LocaleState>(LocaleNotifier.new);
