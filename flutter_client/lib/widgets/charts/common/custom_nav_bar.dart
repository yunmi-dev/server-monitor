// lib/widgets/common/custom_nav_bar.dart
import 'package:flutter/material.dart';
// import 'package:animations/animations.dart';
// import 'package:fl_nav_bar/fl_nav_bar.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.grey[900],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.insert_chart_outlined),
          selectedIcon: Icon(Icons.insert_chart),
          label: 'Stats',
        ),
        NavigationDestination(
          icon: Icon(Icons.computer_outlined),
          selectedIcon: Icon(Icons.computer),
          label: 'Servers',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu),
          selectedIcon: Icon(Icons.menu),
          label: 'Menu',
        ),
      ],
    );
  }
}
