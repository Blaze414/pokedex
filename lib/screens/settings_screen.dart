import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/cache_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CacheService _cache = CacheService();

  DateTime? _lastCached;
  DateTime? _expiresAt;
  double?   _sizeKB;
  int?      _detailCount;
  int?      _spriteCount;
  bool      _statsLoading = true;
  bool      _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    final results = await Future.wait([
      _cache.lastCachedAt(),
      _cache.expiresAt(),
      _cache.estimatedSizeKB(),
      _cache.cachedDetailCount(),
      _cache.cachedSpriteCount(),
    ]);
    if (!mounted) return;
    setState(() {
      _lastCached   = results[0] as DateTime?;
      _expiresAt    = results[1] as DateTime?;
      _sizeKB       = results[2] as double;
      _detailCount  = results[3] as int;
      _spriteCount  = results[4] as int;
      _statsLoading = false;
    });
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear cache?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
          'All locally saved Pokémon data will be deleted. The full list will re-download the next time you open the app.',
          style: GoogleFonts.nunito(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[400]),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    await _cache.clearAll();
    await _loadStats();
    setState(() => _clearing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache cleared — data will reload on next launch.',
            style: GoogleFonts.nunito()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return 'in ${diff.inDays}d';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(cs),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Appearance ────────────────────────────────────────────
                _SectionLabel(label: 'Appearance'),
                _SettingsCard(children: [
                  _ToggleRow(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: isDark ? const Color(0xFF7C83FD) : const Color(0xFFFFC107),
                    title: 'Dark mode',
                    subtitle: isDark ? 'On — dark theme active' : 'Off — light theme active',
                    value: isDark,
                    onChanged: (_) => settings.toggleDarkMode(),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Cache ─────────────────────────────────────────────────
                _SectionLabel(label: 'Cache'),
                _SettingsCard(children: [
                  _ToggleRow(
                    icon: settings.useCache
                        ? Icons.offline_bolt_rounded
                        : Icons.cloud_sync_rounded,
                    iconColor: settings.useCache
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF3D9BE9),
                    title: 'Use cached Pokemon data',
                    subtitle: settings.useCache
                        ? 'On — load saved Pokemon data when available'
                        : 'Off — always fetch fresh data from PokéAPI',
                    value: settings.useCache,
                    onChanged: settings.setUseCache,
                  ),
                  _Divider(),
                  _statsLoading
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : _lastCached == null
                      ? _NoCacheRow()
                      : _CacheStatsBlock(
                    lastCached: _lastCached!,
                    expiresAt: _expiresAt!,
                    sizeKB: _sizeKB ?? 0,
                    detailCount: _detailCount ?? 0,
                    spriteCount: _spriteCount ?? 0,
                    formatDateTime: _formatDateTime,
                    formatExpiry: _formatExpiry,
                  ),
                ]),

                const SizedBox(height: 12),

                // Clear button
                _ClearCacheButton(
                  onTap: _lastCached == null || _clearing ? null : _clearCache,
                  isLoading: _clearing,
                ),

                const SizedBox(height: 24),

                // ── About ─────────────────────────────────────────────────
                _SectionLabel(label: 'About'),
                _SettingsCard(children: [
                  _InfoRow(
                    icon: Icons.catching_pokemon_rounded,
                    iconColor: const Color(0xFFE53935),
                    title: 'Pokédex',
                    value: 'v1.0.0',
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: Icons.api_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Data source',
                    value: 'PokéAPI v2',
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF3D9BE9),
                    title: 'Cache TTL',
                    value: '24 hours',
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(ColorScheme cs) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.onSurface)),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface)),
          ),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _NoCacheRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.inbox_rounded, size: 32, color: cs.outlineVariant),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No cache yet',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, color: cs.onSurface)),
              Text('Data will be cached after first load',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CacheStatsBlock extends StatelessWidget {
  final DateTime lastCached;
  final DateTime expiresAt;
  final double sizeKB;
  final int detailCount;
  final int spriteCount;
  final String Function(DateTime) formatDateTime;
  final String Function(DateTime) formatExpiry;

  const _CacheStatsBlock({
    required this.lastCached,
    required this.expiresAt,
    required this.sizeKB,
    required this.detailCount,
    required this.spriteCount,
    required this.formatDateTime,
    required this.formatExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = expiresAt.isBefore(DateTime.now());
    final expiryColor = isExpired ? Colors.red[400]! : Colors.green[600]!;

    return Column(
      children: [
        _StatRow(
          icon: Icons.schedule_rounded,
          iconColor: const Color(0xFF3D9BE9),
          label: 'Last cached',
          value: formatDateTime(lastCached),
        ),
        _Divider(),
        _StatRow(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: expiryColor,
          label: 'Expires',
          value: formatExpiry(expiresAt),
          valueColor: expiryColor,
        ),
        _Divider(),
        _StatRow(
          icon: Icons.storage_rounded,
          iconColor: const Color(0xFF9C27B0),
          label: 'Cache size',
          value: sizeKB >= 1024
              ? '${(sizeKB / 1024).toStringAsFixed(1)} MB'
              : '${sizeKB.toStringAsFixed(0)} KB',
        ),
        _Divider(),
        _StatRow(
          icon: Icons.catching_pokemon_rounded,
          iconColor: const Color(0xFFE53935),
          label: 'Pokémon details',
          value: '$detailCount cached',
        ),
        _Divider(),
        _StatRow(
          icon: Icons.image_rounded,
          iconColor: const Color(0xFFF7C948),
          label: 'Sprites',
          value: '$spriteCount cached',
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface)),
          ),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ClearCacheButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _ClearCacheButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled
          ? Colors.red.withOpacity(0.05)
          : Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: disabled
                  ? Colors.red.withOpacity(0.15)
                  : Colors.red.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              _IconBox(
                icon: isLoading ? Icons.hourglass_top_rounded : Icons.delete_sweep_rounded,
                color: disabled ? Colors.red.withOpacity(0.4) : Colors.red,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear all cache',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: disabled
                            ? Colors.red.withOpacity(0.4)
                            : Colors.red[600],
                      ),
                    ),
                    Text(
                      disabled
                          ? 'Nothing cached yet'
                          : 'Forces a fresh download on next launch',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: disabled
                            ? Colors.red.withOpacity(0.3)
                            : Colors.red.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: disabled
                        ? Colors.red.withOpacity(0.2)
                        : Colors.red.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
