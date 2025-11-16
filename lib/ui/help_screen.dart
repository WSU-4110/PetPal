// lib/ui/help_screen.dart
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqItems = [
      // Dogs
      {
        'q': 'How often should I take my dog to the vet?',
        'a': 'Adult dogs: at least once per year. Puppies & seniors may need more frequent check-ups.'
      },
      {
        'q': 'How do I introduce a new dog to my household?',
        'a': 'Do slow introductions in a neutral area. Allow scent swapping first and supervise initial meetings.'
      },
      {
        'q': 'What are warning signs of illness in dogs?',
        'a': 'Lethargy, vomiting, diarrhea, coughing, loss of appetite. Contact your vet promptly.'
      },

      // Cats
      {
        'q': 'My cat stopped eating - what should I do?',
        'a': 'If a cat doesn\'t eat for 24-48 hours, it can be dangerous. Check for other symptoms & contact a vet immediately.'
      },
      {
        'q': 'How often should I groom my cat?',
        'a': 'Long-haired cats: daily brushing. Short-haired cats: weekly brushing helps remove loose hair.'
      },
      {
        'q': 'How do I introduce a new cat?',
        'a': 'Use slow introductions: keep cats in separate rooms initially, swap bedding for scent familiarity, and allow gradual face-to-face contact.'
      },

      // Rabbits
      {
        'q': 'How often should I clean my rabbit\'s cage?',
        'a': 'Spot-clean daily and do a full cage clean once a week to maintain hygiene.'
      },
      {
        'q': 'What are signs of sickness in rabbits?',
        'a': 'Loss of appetite, diarrhea, lethargy, sneezing, or changes in droppings. See a vet immediately.'
      },
      {
        'q': 'Can rabbits live indoors?',
        'a': 'Yes, in a rabbit-proofed area with safe toys and hiding spaces. Ensure they have social interaction and exercise.'
      },

      // General tips
      {
        'q': 'Emergency preparedness for pets',
        'a': 'Keep vaccination records updated, maintain a small first-aid kit, and know emergency vet locations.'
      },
      {
        'q': 'Pet nutrition basics',
        'a': 'Feed species-appropriate diets, avoid harmful foods (chocolate, grapes, onions), and provide clean water daily.'
      },
      {
        'q': 'Mental stimulation for pets',
        'a': 'Provide toys, puzzles, training, and safe spaces to prevent boredom and anxiety.'
      },
      {
        'q': 'Contact support',
        'a': 'Email: support@example.com'
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Help & FAQ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality if needed
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: faqItems.map((it) {
                return Card(
                  color: Colors.white.withValues(alpha: 0.06),
                  child: ExpansionTile(
                    collapsedIconColor: Colors.white70,
                    iconColor: Colors.white,
                    title: Text(it['q']!, style: const TextStyle(color: Colors.white)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(it['a']!, style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}