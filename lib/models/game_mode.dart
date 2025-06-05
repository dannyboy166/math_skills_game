enum GameMode {
  standard,
  timesTableRing,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.standard:
        return 'Standard Mode';
      case GameMode.timesTableRing:
        return 'Times Table Ring Mode';
    }
  }
  
  String get description {
    switch (this) {
      case GameMode.standard:
        return 'Classic puzzle with 4 correct answers';
      case GameMode.timesTableRing:
        return 'Complete times table with all 12 answers';
    }
  }
}