import 'package:flutter/material.dart';
import 'authorization/login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return; 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Center(
        child: FractionalTranslation(
          translation: const Offset(0, -0.1),
          child: Image.asset(
            "assets/images/y2logo.png",
            width: size.width * 0.45,
            height: size.height * 0.18,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}