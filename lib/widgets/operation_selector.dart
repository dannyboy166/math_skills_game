// lib/widgets/operation_selector.dart
import 'package:flutter/material.dart';

class OperationSelector extends StatelessWidget {
  final String currentOperation;
  final Function(String) onOperationSelected;

  const OperationSelector({
    Key? key,
    required this.currentOperation,
    required this.onOperationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(width: 8), // Left padding
          _buildOperationChip('addition', '+', Colors.green),
          _buildOperationChip('subtraction', '-', Colors.purple),
          _buildOperationChip('multiplication', '×', Colors.blue),
          _buildOperationChip('division', '÷', Colors.orange),
          SizedBox(width: 8), // Right padding
        ],
      ),
    );
  }

  Widget _buildOperationChip(String operation, String symbol, Color color) {
    final bool isSelected = currentOperation == operation;
    final String displayName = operation.substring(0, 1).toUpperCase() + operation.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: GestureDetector(
        onTap: () => onOperationSelected(operation),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                  ? color.withValues(alpha: 0.4) 
                  : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}