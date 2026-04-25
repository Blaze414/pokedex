import 'package:flutter/material.dart';

class TypeColors {
  static const Map<String, Color> _colors = {
    'normal':   Color(0xFF9E9E9E),
    'fire':     Color(0xFFFF6B35),
    'water':    Color(0xFF3D9BE9),
    'grass':    Color(0xFF4CAF50),
    'electric': Color(0xFFF7C948),
    'ice':      Color(0xFF4DD0E1),
    'fighting': Color(0xFFE64A19),
    'poison':   Color(0xFF9C27B0),
    'ground':   Color(0xFF8D6E63),
    'flying':   Color(0xFF64B5F6),
    'psychic':  Color(0xFFE91E63),
    'bug':      Color(0xFF7CB342),
    'rock':     Color(0xFF78909C),
    'ghost':    Color(0xFF5C6BC0),
    'dragon':   Color(0xFF5C35D1),
    'dark':     Color(0xFF37474F),
    'steel':    Color(0xFF607D8B),
    'fairy':    Color(0xFFF48FB1),
  };

  static const Map<String, Color> _lightColors = {
    'normal':   Color(0xFFF5F5F5),
    'fire':     Color(0xFFFFF0EB),
    'water':    Color(0xFFEBF5FF),
    'grass':    Color(0xFFEBF5EB),
    'electric': Color(0xFFFFFBEB),
    'ice':      Color(0xFFEBFAFB),
    'fighting': Color(0xFFFFF1EE),
    'poison':   Color(0xFFF8EBFF),
    'ground':   Color(0xFFF5EFEB),
    'flying':   Color(0xFFEBF4FF),
    'psychic':  Color(0xFFFFEBF2),
    'bug':      Color(0xFFF1F8E9),
    'rock':     Color(0xFFECEFF1),
    'ghost':    Color(0xFFECEEF8),
    'dragon':   Color(0xFFEEEBFA),
    'dark':     Color(0xFFECEFF1),
    'steel':    Color(0xFFECEFF1),
    'fairy':    Color(0xFFFFF0F5),
  };

  static const Map<String, Color> _darkColors = {
    'normal':   Color(0xFF2A2A2A),
    'fire':     Color(0xFF3D1A0E),
    'water':    Color(0xFF0D2033),
    'grass':    Color(0xFF0D2010),
    'electric': Color(0xFF2E2800),
    'ice':      Color(0xFF082830),
    'fighting': Color(0xFF2E0D05),
    'poison':   Color(0xFF1E0A28),
    'ground':   Color(0xFF1E1208),
    'flying':   Color(0xFF0A1A2E),
    'psychic':  Color(0xFF2E0818),
    'bug':      Color(0xFF141E05),
    'rock':     Color(0xFF141A1E),
    'ghost':    Color(0xFF0A0E28),
    'dragon':   Color(0xFF0E0828),
    'dark':     Color(0xFF0A0E10),
    'steel':    Color(0xFF10181E),
    'fairy':    Color(0xFF280A18),
  };

  static Color getDarkColor(String type) {
    return _darkColors[type.toLowerCase()] ?? const Color(0xFF1E1E1E);
  }

  static Color getColor(String type) {
    return _colors[type.toLowerCase()] ?? const Color(0xFF9E9E9E);
  }

  static Color getLightColor(String type) {
    return _lightColors[type.toLowerCase()] ?? const Color(0xFFF5F5F5);
  }
}