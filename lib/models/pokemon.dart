class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final int baseExperience;
  final List<String> abilities;
  final List<String> types;
  final Map<String, String> sprites;
  final String cryUrl;
  List<String> encounterLocations;
  String artwork;
  Map<String, int> stats;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.abilities,
    required this.types,
    required this.sprites,
    required this.cryUrl,
    required this.encounterLocations,
    required this.artwork,
    required this.stats,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    List<String> abilities = [];
    for (var ability in json['abilities']) {
      abilities.add(ability['ability']['name']);
    }

    List<String> types = [];
    for (var type in json['types']) {
      types.add(type['type']['name']);
    }

    Map<String, String> sprites = {};
    sprites['front_default'] = json['sprites']['front_default'] ?? '';
    sprites['back_default']  = json['sprites']['back_default']  ?? '';
    sprites['front_shiny']   = json['sprites']['front_shiny']   ?? '';
    sprites['back_shiny']    = json['sprites']['back_shiny']    ?? '';

    Map<String, int> stats = {};
    if (json['stats'] != null) {
      for (var stat in json['stats']) {
        stats[stat['stat']['name']] = stat['base_stat'] as int;
      }
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      height: json['height'],
      weight: json['weight'],
      baseExperience: json['base_experience'] ?? 0,
      abilities: abilities,
      types: types,
      sprites: sprites,
      cryUrl: 'https://pokemoncries.com/cries/${json['id']}.mp3',
      encounterLocations: List<String>.from(json['encounterLocations'] ?? []),
      artwork: json['sprites']['other']?['official-artwork']?['front_default'] ?? '',
      stats: stats,
    );
  }

  /// Used when restoring from cache (already-processed flat structure).
  factory Pokemon.fromCache(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      height: json['height'],
      weight: json['weight'],
      baseExperience: json['baseExperience'] ?? 0,
      abilities: List<String>.from(json['abilities'] ?? []),
      types: List<String>.from(json['types'] ?? []),
      sprites: Map<String, String>.from(json['sprites'] ?? {}),
      cryUrl: json['cryUrl'] ?? '',
      encounterLocations: List<String>.from(json['encounterLocations'] ?? []),
      artwork: json['artwork'] ?? '',
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'baseExperience': baseExperience,
      'abilities': abilities,
      'types': types,
      'sprites': sprites,
      'cryUrl': cryUrl,
      'encounterLocations': encounterLocations,
      'artwork': artwork,
      'stats': stats,
    };
  }
}