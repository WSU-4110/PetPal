// lib/ui/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import 'owner_home_screen.dart';
import 'vet_home_screen.dart';
import 'groomer_home_screen.dart';
import 'trainer_home_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Show different home screen based on user role
    if (appState.isVet) {
      return const VetHomeScreen();
    } else if (appState.isGroomer) {
      return const GroomerHomeScreen();
    } else if (appState.isTrainer) {
      return const TrainerHomeScreen();
    } else {
      // Default to owner home screen
      return const OwnerHomeScreen();
    }
  }
}