import 'package:flutter/material.dart';
import 'package:away/data/preview_content.dart';
import 'package:away/services/import_service.dart';
import 'package:away/services/trip_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';
import 'trip_detail_screen.dart';

class PlanChatScreen extends StatefulWidget {
  const PlanChatScreen({super.key});

  @override
  State<PlanChatScreen> createState() => _PlanChatScreenState();
}

class _ChatLine {
  const _ChatLine({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

class _PlanChatScreenState extends State<PlanChatScreen> {
  final _messageController = TextEditingController();
  final _destinationController = TextEditingController(text: 'Lisbon');
  String _pace = 'Slow';
  String _budget = 'Mid';
  String _who = 'Couple';
  String _focus = 'Food';
  bool _briefOpen = true;
  final Set<String> _selectedFolders = {'Lisbon'};

  final List<_ChatLine> _lines = [
    const _ChatLine(
      fromUser: false,
      text:
          'Fill in the brief, pick any saved-pin folders, or just tell me what you want. I’ll start from what you already saved and build around it.',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _pinsFromSelection() {
    final imports = ImportService.instance;
    if (_selectedFolders.isEmpty) return const [];
    final seen = <String>{};
    final pins = <Map<String, dynamic>>[];
    for (final folder in _selectedFolders) {
      for (final pin in imports.pinsInFolder(folder)) {
        final key = '${pin['name']}_${pin['lat']}_${pin['lng']}';
        if (seen.add(key)) pins.add(pin);
      }
    }
    return pins;
  }

  List<String> _pinNames() {
    return _pinsFromSelection()
        .map((pin) => (pin['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _whoPhrase() {
    return switch (_who) {
      'Solo' => 'a solo trip',
      'Couple' => 'a couple',
      'Friends' => 'friends',
      'Family' => 'family',
      _ => _who.toLowerCase(),
    };
  }

  String _sketchReply() {
    final dest =
        _destinationController.text.trim().isEmpty
            ? 'this trip'
            : _destinationController.text.trim();
    final names = _pinNames();
    final folders = _selectedFolders.toList()..sort();
    final folderLabel =
        folders.isEmpty
            ? 'your saved pins'
            : folders.length == 1
            ? 'your ${folders.first} folder'
            : 'your ${folders.join(' + ')} folders';

    final pinBit =
        names.isEmpty
            ? 'I’ll treat $folderLabel as the spine and fill gaps with nearby finds.'
            : 'I’ll start from ${names.take(3).join(', ')}'
                '${names.length > 3 ? ' and ${names.length - 3} more saves' : ''}'
                ' in $folderLabel, then add quieter stops around them so the week isn’t only the pins you already have.';

    return 'Sketching $dest as a $_pace, $_budget plan for ${_whoPhrase()}, $_focus-led. $pinBit';
  }

  void _send({String? preset}) {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _lines.add(_ChatLine(fromUser: true, text: text));
      _messageController.clear();
      _lines.add(_ChatLine(fromUser: false, text: _sketchReply()));
    });
  }

  String _folderLabel(String name) {
    final count = ImportService.instance.pinsInFolder(name).length;
    final label = name == ImportService.allFolderName ? 'All saved pins' : name;
    return count == 0 ? label : '$label · $count';
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final briefMaxHeight =
        MediaQuery.sizeOf(context).height * (keyboardOpen ? 0.22 : 0.42);

    return CloudBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Plan with AI')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SoftTile(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _briefOpen = !_briefOpen),
                      child: Row(
                        children: [
                          const Text(
                            'Trip brief',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _briefOpen
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                    if (_briefOpen)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: briefMaxHeight),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _destinationController,
                                decoration: const InputDecoration(
                                  labelText: 'Destination',
                                  hintText: 'Lisbon, Tokyo…',
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Jun 12 – 20, 2026',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BriefQuestion(
                                label: 'Pace',
                                children: [
                                  for (final pace in [
                                    'Slow',
                                    'Balanced',
                                    'Packed',
                                  ])
                                    ChoiceChip(
                                      label: Text(pace),
                                      selected: _pace == pace,
                                      showCheckmark: false,
                                      onSelected:
                                          (_) => setState(() => _pace = pace),
                                    ),
                                ],
                              ),
                              _BriefQuestion(
                                label: 'Budget',
                                children: [
                                  for (final budget in [
                                    'Budget',
                                    'Mid',
                                    'Treat',
                                  ])
                                    ChoiceChip(
                                      label: Text(budget),
                                      selected: _budget == budget,
                                      showCheckmark: false,
                                      onSelected:
                                          (_) =>
                                              setState(() => _budget = budget),
                                    ),
                                ],
                              ),
                              _BriefQuestion(
                                label: 'Who’s going',
                                children: [
                                  for (final who in [
                                    'Solo',
                                    'Couple',
                                    'Friends',
                                    'Family',
                                  ])
                                    ChoiceChip(
                                      label: Text(who),
                                      selected: _who == who,
                                      showCheckmark: false,
                                      onSelected:
                                          (_) => setState(() => _who = who),
                                    ),
                                ],
                              ),
                              _BriefQuestion(
                                label: 'What to lean into',
                                children: [
                                  for (final focus in [
                                    'Food',
                                    'Neighborhoods',
                                    'Nature',
                                    'Culture',
                                    'Rest',
                                  ])
                                    ChoiceChip(
                                      label: Text(focus),
                                      selected: _focus == focus,
                                      showCheckmark: false,
                                      onSelected:
                                          (_) => setState(() => _focus = focus),
                                    ),
                                ],
                              ),
                              ListenableBuilder(
                                listenable: ImportService.instance,
                                builder: (context, _) {
                                  final folders =
                                      ImportService.instance.folderNames;
                                  final names = _pinNames();
                                  return _BriefQuestion(
                                    label: 'Build from saved pins',
                                    helper:
                                        'I’ll start from these folders and add around them.',
                                    footer:
                                        names.isNotEmpty
                                            ? Text(
                                              'Using ${names.take(4).join(', ')}'
                                              '${names.length > 4 ? ' +${names.length - 4}' : ''}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.muted,
                                                height: 1.35,
                                              ),
                                            )
                                            : _selectedFolders.isNotEmpty
                                            ? const Text(
                                              'No pins in the selected folders yet — I’ll still use them as the trip spine.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.muted,
                                                height: 1.35,
                                              ),
                                            )
                                            : null,
                                    children: [
                                      for (final folder in folders)
                                        FilterChip(
                                          label: Text(_folderLabel(folder)),
                                          selected: _selectedFolders.contains(
                                            folder,
                                          ),
                                          showCheckmark: false,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedFolders.add(folder);
                                              } else {
                                                _selectedFolders.remove(folder);
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _lines.length,
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  return Align(
                    alignment:
                        line.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            line.fromUser
                                ? AppColors.inkDeep
                                : AppColors.cloud.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Text(
                        line.text,
                        style: TextStyle(
                          color: line.fromUser ? Colors.white : AppColors.ink,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: ListenableBuilder(
                listenable: ImportService.instance,
                builder: (context, _) {
                  final custom = ImportService.instance.customFolderNames;
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final folder in custom) ...[
                        ActionChip(
                          label: Text('Use my $folder folder'),
                          onPressed: () {
                            setState(() => _selectedFolders.add(folder));
                            _send(preset: 'Plan from my $folder folder');
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      ActionChip(
                        label: const Text('Find a quiet week in October'),
                        onPressed:
                            () => _send(preset: 'Find a quiet week in October'),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ElevatedButton(
                onPressed: () {
                  final trips = TripService.instance.trips;
                  final trip =
                      trips.isNotEmpty
                          ? trips.first
                          : PreviewContent.trips.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(trip: trip),
                    ),
                  );
                },
                child: const Text('Add this plan to my year'),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Add onto the brief…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _send,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.inkDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefQuestion extends StatelessWidget {
  const _BriefQuestion({
    required this.label,
    required this.children,
    this.helper,
    this.footer,
  });

  final String label;
  final String? helper;
  final Widget? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 2),
            Text(
              helper!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: children),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}
