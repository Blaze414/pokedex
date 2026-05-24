# REST API Implementation Mind Map (Pokédex App)

Use this as a speaking guide for internship interviews.

## 1) Big Picture (Mind Map)

```mermaid
mindmap
  root((REST API in Pokédex))
    API Layer
      ApiService
        baseUrl: pokeapi.co/api/v2
        timeout: 30s
        _get()
      Endpoints
        pokemon?limit=200
        pokemon/{id}
        pokemon/{name}
        pokemon/{id}/encounters
        pokemon-species/{id}
        evolution-chain URL (from species)
    Domain Models
      Pokemon.fromJson()
      Pokemon.fromCache()
      EvolutionChain.fromJson()
    Cache Layer
      CacheService
        SharedPreferences
          pokemon list
          detail by id
          sprite URL by name
          timestamp
        TTL 24 hours
        prime caches from list
    Settings Gate
      SettingsProvider.shouldUseCache()
      if true -> cache-first
      if false -> network-first
    UI Consumers
      HomeScreen
        fetchPokemons(onProgress)
      PokemonDetailScreen
        fetchPokemonDetails(id)
        fetchEvolutionChain(id)
        fetchPokemonDetailsByName(name)
    Error Strategy
      Non-200 -> throw Exception
      encounters endpoint failures -> []
```

## 2) Request/Response Flow Charts

### A. Pokémon List Loading (`fetchPokemons`)

```mermaid
flowchart TD
  A[HomeScreen initState] --> B[ApiService.fetchPokemons]
  B --> C{Cache enabled?}
  C -->|No| H[GET /pokemon?limit=200]
  C -->|Yes| D{Cache valid TTL < 24h?}
  D -->|Yes| E[Load cached list]
  E --> F{Cached list non-empty?}
  F -->|Yes| G[Prime per-pokemon detail + sprite cache; return list]
  F -->|No| H
  D -->|No| H

  H --> I{List call status 200?}
  I -->|No| X[Throw Failed to load Pokémon list]
  I -->|Yes| J[Loop each list item URL]
  J --> K[GET /pokemon/{id} via provided URL]
  K --> L{status 200?}
  L -->|No| N[Skip item]
  L -->|Yes| M[Pokemon.fromJson]
  M --> O[GET /pokemon/{id}/encounters]
  O --> P[Attach encounterLocations]
  P --> Q[Add to result + update progress]
  N --> Q
  Q --> R{More items?}
  R -->|Yes| J
  R -->|No| S{Cache enabled?}
  S -->|Yes| T[savePokemonList + timestamp + prime caches]
  S -->|No| U[Return list]
  T --> U
```

### B. Pokémon Detail Loading (`fetchPokemonDetails`)

```mermaid
flowchart TD
  A[PokemonDetailScreen _fetchDetails] --> B[ApiService.fetchPokemonDetails(id)]
  B --> C{Cache enabled?}
  C -->|Yes| D[Try cached detail by id]
  D --> E{Found?}
  E -->|Yes| F[Return cached pokemon]
  E -->|No| G[Try cached item from list by id]
  G --> H{Found?}
  H -->|Yes| I[Save detail + sprite cache; return]
  H -->|No| J[GET /pokemon/{id}]
  C -->|No| J
  J --> K{status 200?}
  K -->|No| X[Throw Failed to load Pokémon details]
  K -->|Yes| L[Pokemon.fromJson]
  L --> M[GET /pokemon/{id}/encounters]
  M --> N[Attach encounterLocations]
  N --> O{Cache enabled?}
  O -->|Yes| P[savePokemonDetail + saveSprite]
  O -->|No| Q[Return pokemon]
  P --> Q
```

### C. Evolution Chain Loading (`fetchEvolutionChain`)

```mermaid
flowchart TD
  A[PokemonDetailScreen after detail success] --> B[ApiService.fetchEvolutionChain(speciesId)]
  B --> C[GET /pokemon-species/{speciesId}]
  C --> D{status 200?}
  D -->|No| X[Throw Failed to load species data]
  D -->|Yes| E[Read evolution_chain.url]
  E --> F[GET evolution_chain.url]
  F --> G{status 200?}
  G -->|No| Y[Throw Failed to load evolution chain]
  G -->|Yes| H[EvolutionChain.fromJson]
  H --> I[UI renders evolution stages]
```

## 3) Interview Talking Points (Short Script)

- The app uses a dedicated **service layer** (`ApiService`) so UI screens do not call HTTP directly.
- Each call goes through a shared `_get()` wrapper with a **30-second timeout**.
- Data loading is **cache-aware** and controlled by a user setting (`shouldUseCache`).
- The cache strategy is **cache-first with TTL** (24 hours), then fallback to network.
- Pokémon list loading is a **fan-out workflow**: list endpoint first, then detail endpoint per Pokémon, then encounters per Pokémon.
- Detail flow supports **multiple cache sources**: exact detail cache, then list cache by id/name, then network.
- Models separate parsing for **network JSON** vs **cached JSON** (`fromJson` and `fromCache`) to keep serialization robust.
- Evolution chain requires a **2-step REST traversal**: species endpoint → evolution chain URL.
- Failures are explicit for critical endpoints (throw exceptions), but non-critical encounter lookup is resilient and returns an empty list.

## 4) Endpoints Mapped to Features

| Feature in UI | Service Method | REST Endpoint(s) |
|---|---|---|
| Home grid of 200 Pokémon | `fetchPokemons` | `/pokemon?limit=200`, each item URL, `/pokemon/{id}/encounters` |
| Detail page core info | `fetchPokemonDetails` | `/pokemon/{id}`, `/pokemon/{id}/encounters` |
| Tap evolution stage | `fetchPokemonDetailsByName` | `/pokemon/{name}` |
| Evolution tab chain | `fetchEvolutionChain` | `/pokemon-species/{id}` then returned `evolution_chain.url` |
| Sprite fallback/lookup | `fetchPokemonSprite` | `/pokemon/{name}` (if cache miss) |

---

If you want, I can also generate a **one-page simplified version** (super minimal, non-technical) for non-engineer interviewers.
