import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:away/services/import_service.dart';
import '../imported/imported_screen.dart';

class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 100),
                  // Ad Carousel placeholder
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      itemCount: 5,
                      controller: PageController(viewportFraction: 0.9),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Ad Space ${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Horizontal ListView for suggestions
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text('Item ${index + 1}')),
                        );
                      },
                    ),
                  ),
                  // Main content area
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: MasonryGridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount:
                          ImportService.instance.importedLocations.isEmpty
                              ? 10
                              : ImportService.instance.importedLocations.length,
                      itemBuilder: (context, index) {
                        final imported =
                            ImportService.instance.importedLocations;
                        final hasImported = imported.isNotEmpty;
                        final pin =
                            hasImported
                                ? imported[index % imported.length]
                                : <String, dynamic>{};
                        final pinName =
                            hasImported
                                ? (pin['name'] as String? ?? 'Unknown')
                                : 'Location ${index + 1}';
                        final pinAddress =
                            hasImported
                                ? (pin['address'] as String? ?? '')
                                : 'Sample Address, City, Country';
                        final thumbUrl =
                            hasImported
                                ? (pin['thumbnailUrl'] as String? ?? '').trim()
                                : '';
                        final hasThumb =
                            thumbUrl.isNotEmpty &&
                            (thumbUrl.startsWith('http://') ||
                                thumbUrl.startsWith('https://'));
                        final lat =
                            hasImported && pin['lat'] is num
                                ? (pin['lat'] as num).toDouble()
                                : 21.00;
                        final lng =
                            hasImported && pin['lng'] is num
                                ? (pin['lng'] as num).toDouble()
                                : -86.00;
                        final heights = [240.0, 280.0, 260.0, 300.0, 250.0];
                        final height = heights[index % heights.length];
                        return Container(
                          height: height,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: height * 0.45,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (hasThumb)
                                          Image.network(
                                            thumbUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return Container(
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(0xFFDDEAF1),
                                                      Color(0xFFBFD4E2),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        else
                                          Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFFDDEAF1),
                                                  Color(0xFFBFD4E2),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Container(
                                          color: Colors.black.withAlpha(35),
                                        ),
                                        const Center(
                                          child: Icon(
                                            Icons.play_circle_filled,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pinName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  pinAddress,
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.map, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ],
          ),
          Positioned(
            top: 55,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search locations or pins…',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.folder),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyImportsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
