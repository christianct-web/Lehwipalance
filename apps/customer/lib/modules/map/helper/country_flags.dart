// Country flag emoji mapping
class CountryFlags {
  static final Map<String, String> flags = {
    'United States': '🇺🇸',
    'USA': '🇺🇸',
    'US': '🇺🇸',
    'Canada': '🇨🇦',
    'United Kingdom': '🇬🇧',
    'UK': '🇬🇧',
    'Trinidad and Tobago': '🇹🇹',
    'Trinidad & Tobago': '🇹🇹',
    'Australia': '🇦🇺',
    'Germany': '🇩🇪',
    'France': '🇫🇷',
    'Japan': '🇯🇵',
    'China': '🇨🇳',
    'India': '🇮🇳',
    'Brazil': '🇧🇷',
    'Mexico': '🇲🇽',
    'Spain': '🇪🇸',
    'Italy': '🇮🇹',
    'Russia': '🇷🇺',
    'South Africa': '🇿🇦',
    'New Zealand': '🇳🇿',
    'Singapore': '🇸🇬',
    'South Korea': '🇰🇷',
    'Netherlands': '🇳🇱',
    'Switzerland': '🇨🇭',
    'Sweden': '🇸🇪',
    'Norway': '🇳🇴',
    'Denmark': '🇩🇰',
    'Finland': '🇫🇮',
    'Ireland': '🇮🇪',
    'Portugal': '🇵🇹',
    'Greece': '🇬🇷',
    'Turkey': '🇹🇷',
    'Egypt': '🇪🇬',
    'Saudi Arabia': '🇸🇦',
    'United Arab Emirates': '🇦🇪',
    'UAE': '🇦🇪',
    'Thailand': '🇹🇭',
    'Vietnam': '🇻🇳',
    'Indonesia': '🇮🇩',
    'Malaysia': '🇲🇾',
    'Philippines': '🇵🇭',
    'Pakistan': '🇵🇰',
    'Bangladesh': '🇧🇩',
    'Argentina': '🇦🇷',
    'Chile': '🇨🇱',
    'Colombia': '🇨🇴',
    'Peru': '🇵🇪',
    'Venezuela': '🇻🇪',
  };

  static String getFlagEmoji(String countryName) {
    // Try exact match first
    if (flags.containsKey(countryName)) {
      return flags[countryName]!;
    }

    // Try case-insensitive match
    final lowerName = countryName.toLowerCase();
    for (var entry in flags.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }

    // Try partial match
    for (var entry in flags.entries) {
      if (entry.key.toLowerCase().contains(lowerName) ||
          lowerName.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Fallback emojis
    if (countryName == 'Select Country') {
      return '🌍';
    }
    return '🏳️';
  }
}
