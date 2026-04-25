import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../providers/favorite_provider.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';
import '../services/sound_service.dart';
import '../utils/type_colors.dart';
import 'pokemon_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Pokemon> _pokemons = [];
  List<Pokemon> _filteredPokemons = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSearching = false;
  double _progress = 0.0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late ApiService _apiService;
  late GeminiService _geminiService;
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _geminiService = GeminiService();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    SoundService.instance.init(); // pre-load plink asset
    _fetchPokemons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fabAnimController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchPokemons() async {
    try {
      final pokemons = await _apiService.fetchPokemons(onProgress: (progress) {
        setState(() => _progress = progress);
      });
      setState(() {
        _pokemons = pokemons;
        _filteredPokemons = pokemons;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Timer? _debounce;

  void _filterPokemons(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      setState(() {
        _filteredPokemons = _pokemons.where((pokemon) =>
            pokemon.name.toLowerCase().contains(query.toLowerCase())).toList();
      });
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _fabAnimController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _fabAnimController.reverse();
        _searchController.clear();
        _filteredPokemons = _pokemons;
        _searchFocusNode.unfocus();
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final result = await _geminiService.identifyPokemon(pickedFile.path);
      _navigateToPokemonDetail(result);
    }
  }

  void _navigateToPokemonDetail(String responseText) {
    final pokemonName = _extractPokemonName(responseText);
    final matchedPokemon = _pokemons.firstWhere(
          (pokemon) => pokemon.name.toLowerCase() == pokemonName.toLowerCase(),
      orElse: () => Pokemon(
        id: -1, name: '', height: 0, weight: 0, baseExperience: 0,
        abilities: [], types: [], sprites: {}, cryUrl: '',
        encounterLocations: [], artwork: '', stats: {},
      ),
    );

    if (matchedPokemon.id != -1) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(pokemonId: matchedPokemon.id),
      ));
    } else {
      _showErrorDialog(responseText);
    }
  }

  String _extractPokemonName(String responseText) {
    final patterns = [
      RegExp(r'\b(?:This is|That pokemon is|It is|The Pokémon is)\s+(\w+)\b', caseSensitive: false),
      RegExp(r'\b(?:This looks like|It looks like|Appears to be|Looks like)\s+(\w+)\b', caseSensitive: false),
      RegExp(r'\b(?:Identified as|Recognized as)\s+(\w+)\b', caseSensitive: false),
    ];
    for (var pattern in patterns) {
      final match = pattern.firstMatch(responseText);
      if (match != null) return match.group(1)!.replaceAll('.', '');
    }
    return responseText.replaceAll('.', '');
  }

  void _showErrorDialog(String responseText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pokémon not found', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gemini responded:', style: GoogleFonts.nunito(color: Colors.grey)),
            const SizedBox(height: 8),
            SelectableText(responseText, style: GoogleFonts.nunito(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: responseText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied!', style: GoogleFonts.nunito()),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Copy', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_isSearching) _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pokédex',
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                if (!_isLoading)
                  Text(
                    '${_filteredPokemons.length} Pokémon',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          _buildHeaderButton(
            icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.camera_alt_rounded,
            onTap: _pickImage,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.settings_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Icon(icon, size: 22, color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _filterPokemons,
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Search by name…',
            hintStyle: GoogleFonts.nunito(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
            prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => _forceRefetch(),
      child: _isLoading ? _buildLoadingState()
          : _hasError   ? _buildErrorState()
          : _filteredPokemons.isEmpty ? _buildEmptyState()
          : _buildGrid(),
    );
  }

  Future<void> _forceRefetch() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final pokemons = await _apiService.fetchPokemons(onProgress: (p) => setState(() => _progress = p));
      setState(() {
        _pokemons = pokemons;
        _filteredPokemons = pokemons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _hasError = true; _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Widget _buildLoadingState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 6,
              backgroundColor: cs.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Pokédex…',
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% complete',
            style: GoogleFonts.nunito(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(_errorMessage,
                style: GoogleFonts.nunito(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchPokemons,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Try again', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No Pokémon found',
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Try a different name',
              style: GoogleFonts.nunito(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredPokemons.length,
      itemBuilder: (context, index) {
        final pokemon = _filteredPokemons[index];
        return _PokemonCard(
          pokemon: pokemon,
          onTap: () {
            SoundService.instance.playPlink();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => PokemonDetailScreen(pokemonId: pokemon.id),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
        );
      },
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const _PokemonCard({required this.pokemon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first : 'normal';
    final baseColor = TypeColors.getColor(primaryType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? TypeColors.getDarkColor(primaryType)
        : TypeColors.getLightColor(primaryType);
    final nameColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final favorites = context.watch<FavoriteProvider>();
    final isFav = favorites.isFavorite(pokemon);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${pokemon.id.toString().padLeft(3, '0')}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: baseColor.withOpacity(isDark ? 0.9 : 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _capitalize(pokemon.name),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: nameColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: pokemon.types.map((type) => _TypeChip(
                            type: type,
                            color: TypeColors.getColor(type),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isFav) {
                            favorites.removeFavorite(pokemon);
                          } else {
                            favorites.addFavorite(pokemon);
                          }
                        },
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Hero(
                  tag: 'pokemon-${pokemon.id}',
                  child: CachedNetworkImage(
                    imageUrl: pokemon.artwork,
                    height: 90,
                    width: 90,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => SizedBox(
                      height: 90,
                      width: 90,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Icon(Icons.catching_pokemon, size: 60, color: baseColor.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _TypeChip extends StatelessWidget {
  final String type;
  final Color color;

  const _TypeChip({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}