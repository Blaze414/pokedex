# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter run                    # Run on connected device/simulator
flutter run -d <device_id>     # Run on specific device
flutter build ios              # iOS simulator build
flutter build apk             # Android APK
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run single test file
flutter analyze               # Run static analysis
flutter pub get               # Install dependencies
```

## Architecture Overview

**State Management:** Provider (ChangeNotifier pattern)
- `FavoriteProvider` — in-memory favorite Pokémon list
- `SettingsProvider` — theme mode (light/dark/system)
- `ApiService` injected directly via `Provider.create`

**Service Layer (`lib/services/`):**
- `ApiService` — PokeAPI network calls (list, detail, evolution chain, encounters)
- `CacheService` — SharedPreferences-backed JSON cache (24hr TTL)
- `GeminiService` — Google Generative AI for camera-based Pokémon identification
- `SoundService` — Audio playback singleton for sound effects

**Models (`lib/models/`):**
- `Pokemon` — full Pokémon data, JSON serialization (fromJson/fromCache)
- `EvolutionChain` — evolution stage chain parsed from PokeAPI

**Screens (`lib/screens/`):**
- `HomeScreen` — main grid view with search, camera button, settings nav
- `PokemonDetailScreen` — tabbed detail view (About/Sprites/Evolution)
- `SettingsScreen` — theme toggle, cache stats
- `CameraScreen`, `DisplayPictureScreen` — camera flow for AI identification

**Key Flow — Camera Identification:**
1. User taps camera button → `ImagePicker` captures photo
2. `GeminiService.identifyPokemon()` sends image to Gemini API
3. Response text parsed for Pokémon name via regex patterns
4. `_navigateToPokemonDetail()` finds matched Pokémon and pushes detail screen

**Caching Strategy:**
- Full Pokémon list cached on fetch (200 Pokémon with encounter locations)
- Individual detail pages cached on demand
- Sprite URLs cached separately
- 24hr TTL — `isCacheValid()` checks timestamp
- `clearAll()` wipes all SharedPreferences

**API Endpoints Used:**
- `GET https://pokeapi.co/api/v2/pokemon?limit=200` — list
- `GET https://pokeapi.co/api/v2/pokemon/{id}` — detail
- `GET https://pokeapi.co/api/v2/pokemon/{id}/encounters` — encounter locations
- `GET https://pokeapi.co/api/v2/pokemon-species/{id}` — species → evolution chain
- `GET https://pokeapi.co/api/v2/evolution-chain/{id}` — evolution data
- `GET https://pokemoncries.com/cries/{id}.mp3` — Pokémon cry

**Theme:** Material 3 with Nunito font, red seed color (#E53935), light/dark variants

## Notes

- Gemini API key is hardcoded in `GeminiService` — should move to environment/config
- `cache_service.dart` uses instance methods but is called statically in some places
- Test file (`test/widget_test.dart`) is the default Flutter counter test — not specific to this app
