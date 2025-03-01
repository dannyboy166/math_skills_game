import 'package:flutter/material.dart';

class NumberTile extends StatelessWidget {
  final int number;
  final Color color;
  final bool isDisabled;
  final VoidCallback? onTap;

  const NumberTile({
    Key? key,
    required this.number,
    required this.color,
    this.isDisabled = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 45,
        height: 45,
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
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}