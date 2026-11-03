import 'package:flutter/material.dart';

import '../../widgets/brand_header.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [BrandHeader(), SizedBox(height: 32), CircularProgressIndicator()],
        ),
      ),
    );
  }
}
