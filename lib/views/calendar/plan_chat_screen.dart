import 'package:flutter/material.dart';
import 'package:away/data/preview_content.dart';
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
  bool _briefOpen = true;

  final List<_ChatLine> _lines = [
    const _ChatLine(
      fromUser: false,
      text:
          'Fill in the brief, or just tell me what you want. I’ll use your saved pins and add the plan onto your year.',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _send({String? preset}) {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _lines.add(_ChatLine(fromUser: true, text: text));
      _messageController.clear();
      _lines.add(
        _ChatLine(
          fromUser: false,
          text:
              'Sketching ${_destinationController.text.trim().isEmpty ? 'this trip' : _destinationController.text.trim()} as a $_pace, $_budget plan. I’ll leave two afternoons open and pull from your folder.',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    if (_briefOpen) ...[
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final pace in ['Slow', 'Balanced', 'Packed'])
                            ChoiceChip(
                              label: Text(pace),
                              selected: _pace == pace,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _pace = pace),
                            ),
                          for (final budget in ['Budget', 'Mid', 'Treat'])
                            ChoiceChip(
                              label: Text(budget),
                              selected: _budget == budget,
                              showCheckmark: false,
                              onSelected:
                                  (_) => setState(() => _budget = budget),
                            ),
                        ],
                      ),
                    ],
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
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ActionChip(
                    label: const Text('Use my Lisbon folder'),
                    onPressed:
                        () => _send(preset: 'Plan Lisbon from my folder'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Find a quiet week in October'),
                    onPressed:
                        () => _send(preset: 'Find a quiet week in October'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => TripDetailScreen(
                            trip: PreviewContent.trips.first,
                          ),
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
