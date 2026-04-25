# Pokédex

A Flutter Pokédex app for browsing and identifying Pokémon using PokéAPI and Google Gemini AI.

## Features

- **Pokémon Browser** — Grid view of all 200 Pokémon with search, type chips, and official artwork
- **Detail View** — Stats, abilities, encounter locations, sprites, cries, and evolution chains
- **Camera Identification** — Snap a photo and Gemini AI identifies the Pokémon
- **Audio Cries** — Play each Pokémon's cry on demand
- **Dark Mode** — Theme-aware home, settings, and Pokémon detail screens
- **Configurable Data Loading** — Choose between cached Pokémon data or always fetching fresh data from PokéAPI
- **Offline-Friendly Cache** — Pokémon list, details, and sprite metadata are cached locally for 24 hours

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| State | Provider |
| Network | http + PokeAPI |
| AI | Google Gemini |
| Cache | SharedPreferences + flutter_cache_manager |
| Fonts | Nunito (Google Fonts) |
| Images | cached_network_image |

## Setup

1. **Clone and install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

3. **Choose a device if needed**
   ```bash
   flutter devices
   flutter run -d <device_id>
   ```

4. **Camera Identification**
   The Gemini API key is currently hardcoded in `lib/services/gemini_service.dart`. Replace it with your own key before shipping the app.

## Settings

- **Dark mode** — Switch between light and dark themes
- **Use cached Pokémon data** — Load saved Pokémon data when available, or disable cache usage and always fetch fresh data from PokéAPI
- **Cache stats** — View last cache time, expiry, estimated size, cached details, and cached sprites
- **Clear cache** — Remove saved Pokémon data and image cache

## Project Structure

```
lib/
├── main.dart                  # App entry, theme setup, Provider bootstrap
├── models/
│   ├── pokemon.dart           # Pokemon data class with JSON serialization
│   └── evolution_chain.dart
├── providers/
│   ├── favorite_provider.dart   # In-memory favorites
│   └── settings_provider.dart   # Theme and cache preferences
├── screens/
│   ├── home_screen.dart            # Main grid + search + camera
│   ├── pokemon_detail_screen.dart  # Tabbed detail view
│   ├── settings_screen.dart
│   ├── camera_screen.dart
│   └── display_picture_screen.dart
├── services/
│   ├── api_service.dart         # PokeAPI calls + cache-aware loading
│   ├── cache_service.dart       # Local cache storage and cache stats
│   ├── gemini_service.dart      # Gemini AI integration
│   └── sound_service.dart       # Audio playback
└── utils/
    ├── type_colors.dart         # Pokémon type → color mapping
    └── loading_dialog.dart
```

## API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `pokeapi.co/api/v2/pokemon?limit=200` | Pokémon list |
| `pokeapi.co/api/v2/pokemon/{id}` | Pokémon detail |
| `pokeapi.co/api/v2/pokemon/{id}/encounters` | Wild encounter locations |
| `pokeapi.co/api/v2/pokemon-species/{id}` | Species data |
| `pokeapi.co/api/v2/evolution-chain/{id}` | Evolution chain |
| `pokemoncries.com/cries/{id}.mp3` | Pokémon cry |
