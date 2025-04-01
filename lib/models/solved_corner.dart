class SolvedCorner {
  /// Whether this corner is locked (solved)
  final bool isLocked;

  /// The number from the inner ring at this corner
  final int innerNumber;

  /// The number from the outer ring at this corner
  final int outerNumber;

  /// The equation represented by this corner (for display)
  final String equationString;

  const SolvedCorner({
    required this.isLocked,
    required this.innerNumber,
    required this.outerNumber,
    required this.equationString,
  });

  /// Create a copy of this corner with updated values
  SolvedCorner copyWith({
    bool? isLocked,
    int? innerNumber,
    int? outerNumber,
    String? equationString,
  }) {
    return SolvedCorner(
      isLocked: isLocked ?? this.isLocked,
      innerNumber: innerNumber ?? this.innerNumber,
      outerNumber: outerNumber ?? this.outerNumber,
      equationString: equationString ?? this.equationString,
    );
  }
}
