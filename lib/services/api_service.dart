import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/evolution_chain.dart';
import '../providers/settings_provider.dart';
import 'cache_service.dart';

class ApiService {
  final String baseUrl = 'https://pokeapi.co/api/v2';
  final CacheService _cache = CacheService();

  static const Duration _timeout = Duration(seconds: 30);

  Future<http.Response> _get(Uri url) async {
    return await http.get(url).timeout(_timeout);
  }

  Future<bool> _shouldUseCache() => SettingsProvider.shouldUseCache();

  // ── Pokémon list ──────────────────────────────────────────────────────────

  Future<List<Pokemon>> fetchPokemons({Function(double)? onProgress}) async {
    final useCache = await _shouldUseCache();

    if (useCache && await _cache.isCacheValid()) {
      final cached = await _cache.loadPokemonList();
      if (cached != null && cached.isNotEmpty) {
        await _cache.primePokemonCaches(cached);
        onProgress?.call(1.0);
        return cached;
      }
    }

    final response = await _get(Uri.parse('$baseUrl/pokemon?limit=200'));
    if (response.statusCode != 200) throw Exception('Failed to load Pokémon list');

    final List<dynamic> data = json.decode(response.body)['results'];
    final List<Pokemon> pokemons = [];

    for (int i = 0; i < data.length; i++) {
      final pokeDetails = await _get(Uri.parse(data[i]['url']));
      if (pokeDetails.statusCode == 200) {
        final pokemon = Pokemon.fromJson(json.decode(pokeDetails.body));
        final locations = await fetchEncounterLocations(pokemon.id);
        pokemon.encounterLocations = locations;
        pokemons.add(pokemon);
      }
      onProgress?.call((i + 1) / data.length);
    }

    if (useCache) {
      await _cache.savePokemonList(pokemons);
    }
    return pokemons;
  }

  // ── Single Pokémon detail ─────────────────────────────────────────────────

  Future<Pokemon> fetchPokemonDetails(int id) async {
    final useCache = await _shouldUseCache();

    if (useCache) {
      final cached = await _cache.loadPokemonDetail(id);
      if (cached != null) return cached;

      final cachedFromList = await _cache.loadPokemonFromListById(id);
      if (cachedFromList != null) {
        await _cache.savePokemonDetail(cachedFromList);
        await _cache.saveSprite(
          cachedFromList.name,
          cachedFromList.sprites['front_default'] ?? '',
        );
        return cachedFromList;
      }
    }

    final response = await _get(Uri.parse('$baseUrl/pokemon/$id'));
    if (response.statusCode != 200) throw Exception('Failed to load Pokémon details');

    final pokemon = Pokemon.fromJson(json.decode(response.body));
    pokemon.encounterLocations = await fetchEncounterLocations(pokemon.id);
    if (useCache) {
      await _cache.savePokemonDetail(pokemon);
      await _cache.saveSprite(pokemon.name, pokemon.sprites['front_default'] ?? '');
    }
    return pokemon;
  }

  // ── Pokémon detail by name (for evolution navigation) ─────────────────────

  Future<Pokemon> fetchPokemonDetailsByName(String name) async {
    final useCache = await _shouldUseCache();

    if (useCache) {
      final cachedFromList = await _cache.loadPokemonFromListByName(name);
      if (cachedFromList != null) {
        await _cache.savePokemonDetail(cachedFromList);
        await _cache.saveSprite(
          cachedFromList.name,
          cachedFromList.sprites['front_default'] ?? '',
        );
        return cachedFromList;
      }
    }

    final response = await _get(Uri.parse('$baseUrl/pokemon/${name.toLowerCase()}'));
    if (response.statusCode != 200) throw Exception('Failed to load Pokémon: $name');

    final pokemon = Pokemon.fromJson(json.decode(response.body));
    pokemon.encounterLocations = await fetchEncounterLocations(pokemon.id);
    if (useCache) {
      await _cache.savePokemonDetail(pokemon);
      await _cache.saveSprite(pokemon.name, pokemon.sprites['front_default'] ?? '');
    }
    return pokemon;
  }

  // ── Encounter locations ───────────────────────────────────────────────────

  Future<List<String>> fetchEncounterLocations(int id) async {
    try {
      final response = await _get(Uri.parse('$baseUrl/pokemon/$id/encounters'));
      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body);
      return data.map<String>((loc) => loc['location_area']['name'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Evolution chain ───────────────────────────────────────────────────────

  Future<EvolutionChain> fetchEvolutionChain(int speciesId) async {
    final speciesResponse = await _get(Uri.parse('$baseUrl/pokemon-species/$speciesId'));
    if (speciesResponse.statusCode != 200) throw Exception('Failed to load species data');

    final evolutionUrl = json.decode(speciesResponse.body)['evolution_chain']['url'];
    final evolutionResponse = await _get(Uri.parse(evolutionUrl));
    if (evolutionResponse.statusCode != 200) throw Exception('Failed to load evolution chain');

    return EvolutionChain.fromJson(json.decode(evolutionResponse.body));
  }

  // ── Sprite (with cache) ───────────────────────────────────────────────────

  Future<String> fetchPokemonSprite(String name) async {
    final useCache = await _shouldUseCache();

    if (useCache) {
      final cached = await _cache.loadSprite(name);
      if (cached != null) return cached;

      final cachedPokemon = await _cache.loadPokemonFromListByName(name);
      final cachedSprite = cachedPokemon?.sprites['front_default'] ?? '';
      if (cachedSprite.isNotEmpty) {
        await _cache.saveSprite(name, cachedSprite);
        return cachedSprite;
      }
    }

    final response = await _get(Uri.parse('$baseUrl/pokemon/$name'));
    if (response.statusCode != 200) throw Exception('Failed to load sprite for $name');

    final url = json.decode(response.body)['sprites']['front_default'] as String;
    if (useCache) {
      await _cache.saveSprite(name, url);
    }
    return url;
  }
}
