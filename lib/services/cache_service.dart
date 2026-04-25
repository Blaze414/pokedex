import 'dart:convert';
import 'package:file/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';

class CacheService {
  static const String _pokemonListKey      = 'cached_pokemon_list';
  static const String _cacheTimestampKey   = 'cache_timestamp';
  static const String _pokemonDetailPrefix = 'pokemon_detail_';
  static const String _spritePrefix        = 'sprite_';

  static const Duration cacheTTL = Duration(hours: 24);

  String _detailKey(int id) => '$_pokemonDetailPrefix$id';
  String _spriteKey(String name) => '$_spritePrefix${name.toLowerCase()}';

  // ── Validity ───────────────────────────────────────────────────────────────

  Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;
    final saved = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(saved) < cacheTTL;
  }

  // ── Stats (for settings screen) ────────────────────────────────────────────

  Future<DateTime?> lastCachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTimestampKey);
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<DateTime?> expiresAt() async {
    final saved = await lastCachedAt();
    return saved?.add(cacheTTL);
  }

  Future<double> estimatedSizeKB() async {
    final prefs = await SharedPreferences.getInstance();
    int totalBytes = 0;
    for (final key in prefs.getKeys()) {
      final val = prefs.get(key);
      if (val is String) {
        totalBytes += utf8.encode(val).length;
      } else if (val is int || val is double) {
        totalBytes += 8;
      } else if (val is bool) {
        totalBytes += 1;
      } else if (val is List<String>) {
        totalBytes += val.fold<int>(0, (sum, item) => sum + utf8.encode(item).length);
      }
    }

    totalBytes += await _imageCacheSizeBytes();
    return totalBytes / 1024;
  }

  Future<int> cachedDetailCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith(_pokemonDetailPrefix)).length;
  }

  Future<int> cachedSpriteCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith(_spritePrefix)).length;
  }

  // ── Pokemon list ───────────────────────────────────────────────────────────

  Future<void> savePokemonList(List<Pokemon> pokemons) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(pokemons.map((p) => p.toJson()).toList());
    await prefs.setString(_pokemonListKey, encoded);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await _primePokemonCaches(prefs, pokemons);
  }

  Future<void> primePokemonCaches(List<Pokemon> pokemons) async {
    final prefs = await SharedPreferences.getInstance();
    await _primePokemonCaches(prefs, pokemons);
  }

  Future<void> _primePokemonCaches(
    SharedPreferences prefs,
    List<Pokemon> pokemons,
  ) async {
    for (final pokemon in pokemons) {
      await prefs.setString(_detailKey(pokemon.id), jsonEncode(pokemon.toJson()));

      final spriteUrl = pokemon.sprites['front_default'] ?? '';
      if (spriteUrl.isNotEmpty) {
        await prefs.setString(_spriteKey(pokemon.name), spriteUrl);
      }
    }
  }

  Future<List<Pokemon>?> loadPokemonList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pokemonListKey);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((j) => Pokemon.fromCache(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<Pokemon?> loadPokemonFromListById(int id) async {
    final pokemons = await loadPokemonList();
    if (pokemons == null) return null;

    for (final pokemon in pokemons) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  Future<Pokemon?> loadPokemonFromListByName(String name) async {
    final pokemons = await loadPokemonList();
    if (pokemons == null) return null;

    final normalized = name.toLowerCase();
    for (final pokemon in pokemons) {
      if (pokemon.name.toLowerCase() == normalized) return pokemon;
    }
    return null;
  }

  // ── Individual detail ──────────────────────────────────────────────────────

  Future<void> savePokemonDetail(Pokemon pokemon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_detailKey(pokemon.id), jsonEncode(pokemon.toJson()));
  }

  Future<Pokemon?> loadPokemonDetail(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_detailKey(id));
    if (raw == null) return null;
    try {
      return Pokemon.fromCache(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Sprite URLs ────────────────────────────────────────────────────────────

  Future<void> saveSprite(String name, String url) async {
    if (url.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spriteKey(name), url);
  }

  Future<String?> loadSprite(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_spriteKey(name));
  }

  // ── Management ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeys = prefs.getKeys().where((key) {
      return key == _pokemonListKey ||
          key == _cacheTimestampKey ||
          key.startsWith(_pokemonDetailPrefix) ||
          key.startsWith(_spritePrefix);
    }).toList();

    for (final key in cacheKeys) {
      await prefs.remove(key);
    }

    await DefaultCacheManager().emptyCache();
  }

  Future<int> _imageCacheSizeBytes() async {
    try {
      final probeFile = await DefaultCacheManager()
          .store
          .fileSystem
          .createFile('__cache_size_probe__');
      final Directory cacheDir = probeFile.parent;
      if (!await cacheDir.exists()) return 0;

      int totalBytes = 0;
      await for (final entity in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes;
    } catch (_) {
      return 0;
    }
  }
}
