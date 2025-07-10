import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final TextStyle? textStyle; 

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textStyle, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: textStyle ??
              const TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
        ),
      ),
    );
  }
}
