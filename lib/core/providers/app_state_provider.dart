/// Shared provider for managing app state across screens
class AppStateProvider {
  static String? _selectedSociety;
  static final List<String> _societyOptions = [
    'Royal City',
    'Royal Smart City',
    'Royal Homes',
  ];

  /// Get selected society
  static String? getSelectedSociety() => _selectedSociety;

  /// Set selected society
  static void setSelectedSociety(String? society) {
    _selectedSociety = society;
  }

  /// Get all society options
  static List<String> getSocietyOptions() => _societyOptions;

  /// Clear selected society
  static void clearSelectedSociety() {
    _selectedSociety = null;
  }

  /// Check if society is selected
  static bool hasSocietySelected() =>
      _selectedSociety != null && _selectedSociety!.isNotEmpty;
}
