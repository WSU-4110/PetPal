// lib/ui/search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  String? _species;
  String? _breed;
  int? _minAge;
  int? _maxAge;
  String? _resourceCategory; // New filter for resource categories
  Map<String, List<String>> _breedOptions = {};
  List<String> _speciesOptions = [];

  // Map of resource title -> category
  final Map<String, String> resourceCategories = {
    // Dogs
    'Top 10 puppy training tips': 'Dogs',
    'Dog socialization guide': 'Dogs',
    'Dog nutrition basics': 'Dogs',
    'Common dog health issues': 'Dogs',
    'How to housetrain your dog': 'Dogs',
    'First aid for dogs': 'Dogs',

    // Cats
    'How to socialize your cat': 'Cats',
    'Cat litter training tips': 'Cats',
    'Understanding cat behavior': 'Cats',
    'Cat nutrition basics': 'Cats',
    'Common cat health issues': 'Cats',
    'First aid for cats': 'Cats',

    // Rabbits
    'Rabbit-safe houseplants': 'Rabbits',
    'Rabbit diet guide': 'Rabbits',
    'Rabbit housing tips': 'Rabbits',

    // Birds
    'Bird care basics': 'Birds',
    'Common pet bird health issues': 'Birds',

    // All (General pet care)
    'Basic pet first-aid': 'All',
    'Traveling with pets': 'All',
    'Pet dental care tips': 'All',
    'Signs of pet stress': 'All',
    'Pet exercise tips': 'All',
    'Pet safety at home': 'All',
    'Pet grooming DIY tips': 'All',
    'Pet mental stimulation': 'All',
    'Preventing pet obesity': 'All',
  };

  // Map of resource title -> external URL
  final Map<String, String> resourcesMap = {
    // Dogs
    'Top 10 puppy training tips': 'https://www.akc.org/expert-advice/training/10-important-things-to-teach-your-puppy/',
    'Dog socialization guide': 'https://www.k9resorts.com/about-us/articles/tips/dog-socialization-101-the-complete-guide-for-dog/',
    'Dog nutrition basics': 'https://www.petmd.com/dog/nutrition/evr_dg_whats_in_a_balanced_dog_food',
    'Common dog health issues': 'https://www.aspca.org/pet-care/dog-care/common-dog-diseases',
    'How to housetrain your dog': 'https://www.animalhumanesociety.org/resource/housetraining-survival-guide',
    'First aid for dogs': 'https://vcahospitals.com/know-your-pet/first-aid-for-dogs',

    // Cats
    'How to socialize your cat': 'https://www.alleycat.org/resources/cat-socialization-continuum-guide/?utm_source=google_cpc&utm_medium=ad_grant&utm_campaign=aca_cpa&gad_source=1&gad_campaignid=18715802556&gbraid=0AAAAAD41gx3kaxjyfTuLxzMZvBpfPjljM&gclid=CjwKCAiA8bvIBhBJEiwAu5ayrKt-btBfQLtJ-jCQ6Y-dRqLREY9WSYa7PO4LmpRyJB8nKIKq2lqhaxoCyfsQAvD_BwE',
    'Cat litter training tips': 'https://www.animalhumanesociety.org/resource/preventing-and-solving-litter-box-problems',
    'Understanding cat behavior': 'https://www.tuftandpaw.com/blogs/cat-guides/the-definitive-guide-to-cat-behavior-and-body-language?srsltid=AfmBOoqNvDuv9jvl4etLSwfDalYreaz3HKUa-rum7UOSEgZy2eqjO25z',
    'Cat nutrition basics': 'https://www.vet.cornell.edu/departments-centers-and-institutes/cornell-feline-health-center/health-information/feline-health-topics/feeding-your-cat',
    'Common cat health issues': 'https://www.aspca.org/pet-care/cat-care/common-cat-diseases',
    'First aid for cats': 'https://vcahospitals.com/know-your-pet/first-aid-for-cats',

    // Rabbits
    'Rabbit-safe houseplants': 'https://shop.bunloaf.com/rabbit-safe-houseplants/',
    'Rabbit diet guide': 'https://rabbit.org/care/food-diet/?gad_source=1&gad_campaignid=23226859415&gbraid=0AAAAA9aCQqtcoymunB22CvbrtW_Sg172d&gclid=CjwKCAiA8bvIBhBJEiwAu5ayrJUhZwAVoSrJ8JlB5SqUgseUaT_GJsVqAt8Y5G5Gs_sFYJzTQ41RthoCMMoQAvD_BwE',
    'Rabbit housing tips': 'https://rabbit.org/care/habitat/pens-the-modern-housing-preference/',

    // Birds
    'Bird care basics': 'https://smallanimal.vethospital.ufl.edu/clinical-services/zoological-medicine/how-to-care-for-your-pet-bird/',
    'Common pet bird health issues': 'https://vcahospitals.com/know-your-pet/common-conditions-of-birds',

    // General pet care
    'Basic pet first-aid': 'https://www.animalhumanesociety.org/resource/first-aid-tips-pet-parents',
    'Traveling with pets': 'https://www.aspca.org/pet-care/general-pet-care/travel-safety-tips',
    'Pet dental care tips': 'https://veterinarypartner.vin.com/default.aspx?pid=19239&id=11934338',
    'Signs of pet stress': 'https://sdhumane.org/resources/stress-in-pets-what-to-look-for/',
    'Pet exercise tips': 'https://www.baywoodanimaljax.com/diet-and-exercise-tips-to-keep-your-pet-in-fit-shape',
    'Pet safety at home': 'https://www.animalhealthfoundation.org/blog/2022/01/the-ultimate-guide-to-pet-safety-at-home/?utm_source=google&utm_medium=cpc&gad_source=1&gad_campaignid=12266384074&gbraid=0AAAAADy0rxDzE3X4X8Lsy5uX-jmG0TRXL&gclid=CjwKCAiA8bvIBhBJEiwAu5ayrNMyYa7FlF88ljZSIfP1cHLLxCYOfTY86xbfkYHhH7OcelL7sVu42BoCmCkQAvD_BwE',
    'Pet grooming DIY tips': 'https://www.fallsroad.com/site/tips-resources-blog-baltimore-vet/2021/09/30/dog-cat-grooming',
    'Pet mental stimulation': 'https://easyvet.com/mental-stimulation-for-pets-enrichment-activities-and-their-importance/',
    'Preventing pet obesity': 'https://www.alpinehospital.com/services/other/blog/understanding-pet-obesity-causes-risks-and-prevention#:~:text=How%20to%20Prevent%20Pet%20Obesity,simply%20seeking%20attention%20or%20comfort.',
  };

  final Map<String, String> resourcesContent = {
    // same as before...
  };

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    try {
      final raw = await rootBundle.loadString('assets/breeds.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      setState(() {
        _breedOptions = decoded.map(
          (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
        );
        _speciesOptions = _breedOptions.keys.toList();
      });
    } catch (_) {
      setState(() {
        _breedOptions = {'Other': ['Other']};
        _speciesOptions = ['Other'];
      });
    }
  }

  List<dynamic> _filterAll(AppState appState) {
    final q = _query.trim().toLowerCase();
    final List<Pet> pets = appState.pets;
    final List<MedicalRecord> records = appState.medicalRecords;
    final resources = resourcesMap.keys.toList();

    final petResults = pets.where((p) {
      if (q.isNotEmpty &&
          !('${p.name} ${p.species} ${p.breed}'.toLowerCase().contains(q))) return false;
      if ((_species ?? '').isNotEmpty && p.species.toLowerCase() != _species!.toLowerCase()) return false;
      if ((_breed ?? '').isNotEmpty && _breed != 'Other' && p.breed.toLowerCase() != _breed!.toLowerCase()) return false;
      if (_minAge != null && p.age < _minAge!) return false;
      if (_maxAge != null && p.age > _maxAge!) return false;
      return true;
    }).toList();

    final recordResults = records.where((r) {
      final haystack = '${r.title} ${r.vetName} ${r.description}'.toLowerCase();
      return q.isEmpty || haystack.contains(q);
    }).toList();

    final resourceResults = resources.where((r) {
      if (!r.toLowerCase().contains(q)) return false;
      if (_resourceCategory != null && _resourceCategory!.isNotEmpty) {
        final category = resourceCategories[r];
        return category == _resourceCategory;
      }
      return true;
    }).toList();

    return [...petResults, ...recordResults, ...resourceResults];
  }

  Future<void> _openResource(String title) async {
    final url = resourcesMap[title];
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) _showResourceSheet(title);
      } catch (_) {
        _showResourceSheet(title);
      }
    } else {
      _showResourceSheet(title);
    }
  }

  void _showResourceSheet(String title) {
    final content = resourcesContent[title] ??
        'Sorry — no info available offline. Search the web for "$title".';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 12, right: 12, top: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(content, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final results = _filterAll(appState);

    final List<DropdownMenuItem<String?>> speciesItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Any')),
      ..._speciesOptions.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
    ];

    List<String> breedList = [];
    if (_species != null && _breedOptions.containsKey(_species)) breedList = List<String>.from(_breedOptions[_species]!);

    final List<DropdownMenuItem<String?>> breedItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Any')),
      ...breedList.map((b) => DropdownMenuItem<String?>(value: b, child: Text(b))),
    ];

    final List<DropdownMenuItem<String?>> categoryItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('All Tips')),
      const DropdownMenuItem<String?>(value: 'Dogs', child: Text('Dogs')),
      const DropdownMenuItem<String?>(value: 'Cats', child: Text('Cats')),
      const DropdownMenuItem<String?>(value: 'Rabbits', child: Text('Rabbits')),
      const DropdownMenuItem<String?>(value: 'Birds', child: Text('Birds')),
      const DropdownMenuItem<String?>(value: 'All', child: Text('General')),
    ];

    // Group resources by category for displaying labels
    final Map<String, List<String>> groupedResources = {};
    for (final item in results.whereType<String>()) {
      final category = resourceCategories[item] ?? 'Other';
      groupedResources.putIfAbsent(category, () => []).add(item);
    }

    // Prepare list of items for display with headers
    final List<Widget> displayItems = [];
    
    // Add pets
    if (results.whereType<Pet>().isNotEmpty) {
      displayItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Pets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      );
      displayItems.addAll(
        results.whereType<Pet>().map((item) {
          final image = item.image ?? Pet.imageFor(item.species, item.breed);
          final ImageProvider imageProvider =
              image.startsWith('http') ? NetworkImage(image) : AssetImage(image);
          return Card(
            color: Colors.white.withValues(alpha: 0.06),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: imageProvider,
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.24),
              ),
              title: Text(item.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('${item.breed} • ${item.species} • Age: ${item.age}',
                  style: const TextStyle(color: Colors.white70)),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'view') {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Breed: ${item.breed}'),
                            Text('Species: ${item.species}'),
                            Text('Age: ${item.age}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close')),
                          ],
                        ),
                      ),
                    );
                  } else if (v == 'delete') {
                    final messenger = ScaffoldMessenger.of(context);
                    final asDyn =
                        Provider.of<AppState>(context, listen: false) as dynamic;
                    if (asDyn.deletePet is Function) {
                      await asDyn.deletePet(item.id);
                      if (!mounted) return;
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Pet deleted')));
                      setState(() {});
                    }
                  }
                },
                itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit (TODO)')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // Add medical records
    if (results.whereType<MedicalRecord>().isNotEmpty) {
      displayItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Medical Records',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      );
      displayItems.addAll(
        results.whereType<MedicalRecord>().map((item) {
          return Card(
            color: Colors.white.withValues(alpha: 0.06),
            child: ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.white70),
              title: Text('${item.title} • ${item.vetName}',
                  style: const TextStyle(color: Colors.white)),
              subtitle:
                  // Fixed: Use null-aware operator to handle nullable description
                  Text(item.description ?? 'No description', style: const TextStyle(color: Colors.white70)),
            ),
          );
        }).toList(),
      );
    }

    // Add resources by category
    final categories = ['Dogs', 'Cats', 'Rabbits', 'Birds', 'All'];
    for (final category in categories) {
      if (groupedResources.containsKey(category) && groupedResources[category]!.isNotEmpty) {
        displayItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              category == 'All' ? 'General Pet Care' : category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        );
        displayItems.addAll(
          groupedResources[category]!.map((title) {
            final hasUrl = resourcesMap.containsKey(title) &&
                (resourcesMap[title]?.isNotEmpty ?? false);
            return Card(
              color: Colors.white.withValues(alpha: 0.06),
              child: ListTile(
                title: Text(title, style: const TextStyle(color: Colors.white)),
                trailing: hasUrl ? const Icon(Icons.open_in_new, color: Colors.white70) : null,
                onTap: () => _openResource(title),
              ),
            );
          }).toList(),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search', style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search pets, medical records, resources...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),

                // Filters row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: 'Species',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _species,
                        items: speciesItems,
                        onChanged: (v) => setState(() {
                          _species = v;
                          _breed = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: 'Breed',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _breed,
                        items: breedItems,
                        onChanged: (v) => setState(() => _breed = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Resource category filter
                DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: 'Resource Category',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  value: _resourceCategory,
                  items: categoryItems,
                  onChanged: (v) => setState(() => _resourceCategory = v),
                ),
                const SizedBox(height: 8),

                // Age range + Reset
                Row(
                  children: [
                    Flexible(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Min age',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _minAge = int.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Max age',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _maxAge = int.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _query = '';
                        _species = null;
                        _breed = null;
                        _minAge = null;
                        _maxAge = null;
                        _resourceCategory = null;
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Results
                Expanded(
                  child: displayItems.isEmpty
                      ? const Center(child: Text('No results', style: TextStyle(color: Colors.white70)))
                      : ListView(
                          children: displayItems,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}