import 'package:flutter/material.dart';

class ImageDemoPage extends StatelessWidget {
  const ImageDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Image Test', style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('pro.png'),
            const SizedBox(height: 8),
            Image.asset(
              'assets/images/pro.png',
              width: 100,
              height: 100,
              errorBuilder: (_, __, ___) =>
                  const Text('FAILED', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 32),
            const Text('pro_img.png'),
            const SizedBox(height: 8),
            Image.asset(
              'assets/images/pro_img.png',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Text('FAILED', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
