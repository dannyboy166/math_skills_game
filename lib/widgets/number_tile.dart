import 'package:flutter/material.dart';

class NumberTile extends StatelessWidget {
  final int number;
  final Color color;
  final bool isDisabled;
  final VoidCallback? onTap;
  final double size; // Size parameter

  const NumberTile({
    Key? key,
    required this.number,
    required this.color,
    this.isDisabled = false,
    this.onTap,
    this.size = 45, // Default size is still 45
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isDisabled,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey : color,
            shape: BoxShape.circle,
            boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(size * 0.1), // Add padding to ensure text doesn't get too close to edge
                child: Text(
                  '$number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size * 0.4, // Dynamic font size based on tile size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}