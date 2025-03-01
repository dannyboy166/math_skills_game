import 'package:flutter/material.dart';

class CenterTarget extends StatelessWidget {
  final int targetNumber;
  
  const CenterTarget({
    Key? key,
    required this.targetNumber,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
        border: Border.all(color: Colors.teal, width: 3),
      ),
      child: Center(
        child: Text(
          '$targetNumber',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }
}