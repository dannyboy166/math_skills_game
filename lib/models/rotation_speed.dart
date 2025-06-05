// lib/models/rotation_speed.dart
enum RotationSpeed {
  speed1(1, 'Slowest', 0.5),
  speed2(2, 'Very Slow', 0.625),
  speed3(3, 'Slow', 0.75),
  speed4(4, 'Slower', 0.875),
  speed5(5, 'Normal', 1.0),
  speed6(6, 'Faster', 1.2),
  speed7(7, 'Fast', 1.4),
  speed8(8, 'Very Fast', 1.6),
  speed9(9, 'Fastest', 1.8),
  speed10(10, 'Maximum', 2.0);

  const RotationSpeed(this.level, this.displayName, this.transitionRate);

  final int level;
  final String displayName;
  final double transitionRate;

  static RotationSpeed fromLevel(int level) {
    switch (level) {
      case 1:
        return RotationSpeed.speed1;
      case 2:
        return RotationSpeed.speed2;
      case 3:
        return RotationSpeed.speed3;
      case 4:
        return RotationSpeed.speed4;
      case 5:
        return RotationSpeed.speed5;
      case 6:
        return RotationSpeed.speed6;
      case 7:
        return RotationSpeed.speed7;
      case 8:
        return RotationSpeed.speed8;
      case 9:
        return RotationSpeed.speed9;
      case 10:
        return RotationSpeed.speed10;
      default:
        return RotationSpeed.speed5; // Default to Normal (level 5)
    }
  }

  static RotationSpeed get defaultSpeed => RotationSpeed.speed5; // Level 5 is now the default
}