import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/pokemon.dart';
import '../models/evolution_chain.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../utils/type_colors.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailScreen({super.key, required this.pokemonId});

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Pokemon> _pokemonDetails;
  Future<EvolutionChain>? _evolutionChain; // nullable — assigned after detail fetch
  late ApiService _apiService;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _tabController = TabController(length: 3, vsync: this);
    _pokemonDetails = _fetchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Pokemon> _fetchDetails() async {
    final pokemon = await _apiService.fetchPokemonDetails(widget.pokemonId);

    if (pokemon.encounterLocations.isEmpty) {
      final locations = await _apiService.fetchEncounterLocations(widget.pokemonId);
      if (locations.isNotEmpty) {
        pokemon.encounterLocations = locations;
      }
    }

    // Assign evolution chain future — safe even if pokemon fetch succeeded
    // but evolution fetch later fails (handled in FutureBuilder).
    _evolutionChain = _apiService.fetchEvolutionChain(pokemon.id);
    return pokemon;
  }

  void _navigateToEvolution(String speciesName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pokemon = await _apiService.fetchPokemonDetailsByName(speciesName);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loader
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              PokemonDetailScreen(pokemonId: pokemon.id),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load ${_capitalize(speciesName)}',
              style: GoogleFonts.nunito()),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pokemon>(
      future: _pokemonDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('No data')));
        }

        final pokemon = snapshot.data!;
        final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first : 'normal';
        final baseColor = TypeColors.getColor(primaryType);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final headerBg = isDark
            ? TypeColors.getDarkColor(primaryType)
            : TypeColors.getLightColor(primaryType);
        final contentBg = Theme.of(context).scaffoldBackgroundColor;

        return Scaffold(
          backgroundColor: headerBg,
          body: Column(
            children: [
              _buildHeroHeader(pokemon, baseColor, headerBg),
              _buildTabBar(baseColor, headerBg, contentBg),
              Expanded(
                child: Container(
                  color: contentBg,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAboutTab(pokemon, baseColor),
                      _buildSpritesTab(pokemon, baseColor),
                      _buildEvolutionTab(pokemon, baseColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(Pokemon pokemon, Color baseColor, Color headerBg) {
    final nameColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      color: headerBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                    color: baseColor,
                  ),
                  const Spacer(),
                  Text(
                    '#${pokemon.id.toString().padLeft(3, '0')}',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w800, color: baseColor),
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.volume_up_rounded,
                    onTap: () => AudioPlayer().play(UrlSource(pokemon.cryUrl)),
                    color: baseColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalize(pokemon.name),
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: nameColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: pokemon.types
                              .map((t) => _TypeBadge(type: t, color: TypeColors.getColor(t)))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatPill(
                              icon: Icons.straighten_rounded,
                              label: '${(pokemon.height / 10).toStringAsFixed(1)} m',
                              color: baseColor,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              icon: Icons.monitor_weight_rounded,
                              label: '${(pokemon.weight / 10).toStringAsFixed(1)} kg',
                              color: baseColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Hero(
                    tag: 'pokemon-${pokemon.id}',
                    child: CachedNetworkImage(
                      imageUrl: pokemon.artwork,
                      height: 140,
                      width: 140,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => SizedBox(
                        height: 140,
                        width: 140,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.catching_pokemon, size: 100, color: baseColor.withOpacity(0.3)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Color baseColor, Color headerBg, Color contentBg) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: headerBg,
      child: Container(
        decoration: BoxDecoration(
          color: contentBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: baseColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: baseColor,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [Tab(text: 'About'), Tab(text: 'Sprites'), Tab(text: 'Evolution')],
        ),
      ),
    );
  }

  Widget _buildAboutTab(Pokemon pokemon, Color baseColor) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: 'Base Stats',
          color: baseColor,
          child: Column(children: [
            _StatBar(label: 'HP',     value: pokemon.baseExperience, maxValue: 300,  color: baseColor),
            _StatBar(label: 'Height', value: pokemon.height,         maxValue: 100,  color: baseColor),
            _StatBar(label: 'Weight', value: pokemon.weight,         maxValue: 1000, color: baseColor),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Abilities',
          color: baseColor,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pokemon.abilities
                .map((a) => _AbilityChip(label: _capitalize(a), color: baseColor))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Encounter Locations',
          color: baseColor,
          child: pokemon.encounterLocations.isEmpty
              ? Text('No known wild encounter locations',
              style: GoogleFonts.nunito(color: cs.onSurfaceVariant, fontSize: 15))
              : Column(
            children: pokemon.encounterLocations
                .map((loc) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                  BoxDecoration(color: baseColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _capitalize(loc.replaceAll('-', ' ')),
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                  ),
                ),
              ]),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _CacheClearButton(baseColor: baseColor),
      ],
    );
  }

  Widget _buildSpritesTab(Pokemon pokemon, Color baseColor) {
    final cs = Theme.of(context).colorScheme;
    final sprites = [
      {'label': 'Front',       'url': pokemon.sprites['front_default'] ?? ''},
      {'label': 'Back',        'url': pokemon.sprites['back_default']  ?? ''},
      {'label': 'Shiny Front', 'url': pokemon.sprites['front_shiny']   ?? ''},
      {'label': 'Shiny Back',  'url': pokemon.sprites['back_shiny']    ?? ''},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sprites.length,
      itemBuilder: (context, index) {
        final sprite = sprites[index];
        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: sprite['url']!,
                height: 90,
                width: 90,
                placeholder: (_, __) => CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(baseColor)),
                errorWidget: (_, __, ___) =>
                    Icon(Icons.catching_pokemon, color: cs.outlineVariant, size: 48),
              ),
              const SizedBox(height: 8),
              Text(sprite['label']!,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvolutionTab(Pokemon pokemon, Color baseColor) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<EvolutionChain>(
      future: _evolutionChain,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading evolution chain',
                  style: GoogleFonts.nunito(color: cs.onSurfaceVariant)));
        }
        if (!snapshot.hasData) {
          return Center(
              child: Text('No evolution data',
                  style: GoogleFonts.nunito(color: cs.onSurfaceVariant)));
        }

        final chain = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionCard(
              title: 'Evolution Chain',
              color: baseColor,
              child: chain.chain.length == 1
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('This Pokémon does not evolve.',
                      style: GoogleFonts.nunito(
                          color: cs.onSurfaceVariant, fontSize: 15)),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(chain.chain.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    return Column(children: [
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: cs.outlineVariant),
                      const SizedBox(height: 4),
                      Text('Evolves',
                          style: GoogleFonts.nunito(
                              fontSize: 9,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ]);
                  }
                  final stage = chain.chain[i ~/ 2];
                  final isCurrent = stage.speciesName == pokemon.name;
                  return _EvolutionNode(
                    stage: stage,
                    isCurrent: isCurrent,
                    baseColor: baseColor,
                    apiService: _apiService,
                    onTap: isCurrent
                        ? null
                        : () => _navigateToEvolution(stage.speciesName),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;

  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.nunito(
            fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.8),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color color;

  const _SectionCard({required this.title, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatBar extends StatefulWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _StatBar(
      {required this.label, required this.value, required this.maxValue, required this.color});

  @override
  State<_StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<_StatBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = (widget.value / widget.maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(widget.label,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
          ),
          SizedBox(
            width: 42,
            child: Text(widget.value.toString(),
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                color: widget.color.withOpacity(0.12),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (_, __) => FractionallySizedBox(
                    widthFactor: ratio * _animation.value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbilityChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AbilityChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _EvolutionNode extends StatelessWidget {
  final EvolutionStage stage;
  final bool isCurrent;
  final Color baseColor;
  final ApiService apiService;
  final VoidCallback? onTap;

  const _EvolutionNode({
    required this.stage,
    required this.isCurrent,
    required this.baseColor,
    required this.apiService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: baseColor, width: 3)
                  : onTap != null
                  ? Border.all(color: baseColor.withOpacity(0.3), width: 1.5)
                  : null,
              color: isCurrent ? baseColor.withOpacity(0.1) : Colors.transparent,
            ),
            child: FutureBuilder<String>(
              future: apiService.fetchPokemonSprite(stage.speciesName),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CachedNetworkImage(
                    imageUrl: snapshot.data!,
                    height: 72,
                    width: 72,
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.catching_pokemon, size: 48, color: cs.outlineVariant),
                  );
                }
                return SizedBox(
                  height: 72,
                  width: 72,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _capitalize(stage.speciesName),
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
              color: isCurrent ? baseColor : cs.onSurface,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 2),
            Text('Tap to view',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: baseColor.withOpacity(0.6),
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _CacheClearButton extends StatelessWidget {
  final Color baseColor;

  const _CacheClearButton({required this.baseColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Clear cache',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            content: Text(
              'Deletes all locally saved Pokémon data. The app will re-download everything on next launch.',
              style: GoogleFonts.nunito(color: cs.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red[400]),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Clear',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await CacheService().clearAll();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cache cleared. Restart to reload.',
                    style: GoogleFonts.nunito()),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red[400]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clear cache',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.red[400])),
                  Text('Force a fresh download on next launch',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outlineVariant),
          ],
        ),
      ),
    );
  }
}
