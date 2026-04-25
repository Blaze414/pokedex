import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokedex/models/pokemon.dart';
import 'package:pokedex/providers/settings_provider.dart';
import 'package:pokedex/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saving the Pokemon list primes detail and sprite caches', () async {
    SharedPreferences.setMockInitialValues({});

    final cache = CacheService();
    final bulbasaur = Pokemon(
      id: 1,
      name: 'bulbasaur',
      height: 7,
      weight: 69,
      baseExperience: 64,
      abilities: const ['overgrow'],
      types: const ['grass', 'poison'],
      sprites: const {
        'front_default': 'https://example.com/front.png',
        'back_default': 'https://example.com/back.png',
        'front_shiny': 'https://example.com/front_shiny.png',
        'back_shiny': 'https://example.com/back_shiny.png',
      },
      cryUrl: 'https://pokemoncries.com/cries/1.mp3',
      encounterLocations: const ['kanto-route-1'],
      artwork: 'https://example.com/artwork.png',
      stats: const {'hp': 45},
    );

    await cache.savePokemonList([bulbasaur]);

    final cachedDetail = await cache.loadPokemonDetail(1);
    final cachedById = await cache.loadPokemonFromListById(1);
    final cachedByName = await cache.loadPokemonFromListByName('Bulbasaur');
    final cachedSprite = await cache.loadSprite('Bulbasaur');

    expect(cachedDetail?.name, 'bulbasaur');
    expect(cachedById?.encounterLocations, ['kanto-route-1']);
    expect(cachedByName?.id, 1);
    expect(cachedSprite, 'https://example.com/front.png');
    expect(await cache.cachedDetailCount(), 1);
    expect(await cache.cachedSpriteCount(), 1);
  });

  test('cache preference defaults to enabled and can be disabled', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SettingsProvider.shouldUseCache(), isTrue);

    SharedPreferences.setMockInitialValues({'use_cache': false});
    expect(await SettingsProvider.shouldUseCache(), isFalse);
  });
}
