enum GameMode {
  timesTableRing,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.timesTableRing:
        return 'Times Table Ring Mode';
    }
  }
  
  String get description {
    switch (this) {
      case GameMode.timesTableRing:
        return 'Complete times table with all 12 answers';
    }
  }
}