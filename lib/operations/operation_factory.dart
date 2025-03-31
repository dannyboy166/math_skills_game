import '../models/game_operation.dart';
import 'addition_operation.dart';
import 'subtraction_operation.dart';
import 'multiplication_operation.dart';
import 'division_operation.dart';

/// Factory class for creating operation instances.
/// 
/// This simplifies getting the right operation implementation
/// based on the operation name.
class OperationFactory {
  /// Returns the appropriate GameOperation instance for the given operation name.
  /// 
  /// @param operationName The name of the operation ("addition", "subtraction", etc.)
  /// @return The corresponding GameOperation implementation
  static GameOperation getOperation(String operationName) {
    switch (operationName) {
      case 'addition':
        return AdditionOperation();
      case 'subtraction':
        return SubtractionOperation();
      case 'multiplication':
        return MultiplicationOperation();
      case 'division':
        return DivisionOperation();
      default:
        // Default to multiplication if unknown operation name is provided
        return MultiplicationOperation();
    }
  }
  
  /// Returns a list of all available operations.
  /// 
  /// This is useful for UI that needs to display all operation options.
  static List<GameOperation> getAllOperations() {
    return [
      AdditionOperation(),
      SubtractionOperation(),
      MultiplicationOperation(),
      DivisionOperation(),
    ];
  }
}