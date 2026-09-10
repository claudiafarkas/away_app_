import 'package:flutter/material.dart';
import 'package:away/data/preview_content.dart';
import 'package:away/services/trip_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.trip});

  final PreviewTrip trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _DayEditors {
  _DayEditors(TripDay day)
    : date = day.date,
      who = TextEditingController(text: day.who),
      what = TextEditingController(text: day.what),
      where = TextEditingController(text: day.where),
      when = TextEditingController(text: day.when),
      why = TextEditingController(text: day.why);

  DateTime date;
  final TextEditingController who;
  final TextEditingController what;
  final TextEditingController where;
  final TextEditingController when;
  final TextEditingController why;

  TripDay toDay() {
    return TripDay(
      date: date,
      who: who.text.trim(),
      what: what.text.trim(),
      where: where.text.trim(),
      when: when.text.trim(),
      why: why.text.trim(),
    );
  }

  void dispose() {
    who.dispose();
    what.dispose();
    where.dispose();
    when.dispose();
    why.dispose();
  }
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late DateTime _start;
  late DateTime _end;
  late List<_DayEditors> _days;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _titleController = TextEditingController(text: trip.title);
    _placeController = TextEditingController(text: trip.place);
    _start = DateTime(trip.start.year, trip.start.month, trip.start.day);
    _end = DateTime(trip.end.year, trip.end.month, trip.end.day);
    _days = trip.days.map(_DayEditors.new).toList();
    _syncDaysToRange();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _syncDaysToRange() {
    final byDate = <DateTime, _DayEditors>{
      for (final day in _days) _dateOnly(day.date): day,
    };
    final next = <_DayEditors>[];
    for (
      var cursor = _start;
      !cursor.isAfter(_end);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      final key = _dateOnly(cursor);
      next.add(byDate.remove(key) ?? _DayEditors(TripDay(date: key)));
    }
    for (final leftover in byDate.values) {
      leftover.dispose();
    }
    _days = next;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2032),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = _dateOnly(picked);
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = _dateOnly(picked);
        if (_end.isBefore(_start)) _start = _end;
      }
      _syncDaysToRange();
    });
  }

  void _addDay() {
    setState(() {
      final nextDate =
          _days.isEmpty
              ? _start
              : _dateOnly(_days.last.date).add(const Duration(days: 1));
      _days.add(_DayEditors(TripDay(date: nextDate)));
      if (nextDate.isAfter(_end)) _end = nextDate;
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index).dispose();
      if (_days.isNotEmpty) {
        _start = _dateOnly(_days.first.date);
        _end = _dateOnly(_days.last.date);
      }
    });
  }

  PreviewTrip _draft() {
    return widget.trip.copyWith(
      title:
          _titleController.text.trim().isEmpty
              ? widget.trip.title
              : _titleController.text.trim(),
      place:
          _placeController.text.trim().isEmpty
              ? widget.trip.place
              : _placeController.text.trim(),
      start: _start,
      end: _end,
      days: _days.map((day) => day.toDay()).toList(),
    );
  }

  void _save() {
    TripService.instance.save(_draft());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip saved to your year.')));
    setState(() {});
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete this trip?'),
            content: Text(
              'This removes ${_titleController.text.trim().isEmpty ? widget.trip.title : _titleController.text.trim()} from your year.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (shouldDelete != true || !mounted) return;
    TripService.instance.delete(widget.trip.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip deleted.')));
  }

  InputDecoration _fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.86),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    return CloudBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Edit trip')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  SoftTile(
                    gradient: AppColors.featuredGradients[0],
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _fieldDecoration(
                            'Trip name',
                            'Lisbon walk',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _placeController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _fieldDecoration(
                            'Where',
                            'Lisbon, Tokyo…',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DateChip(
                                label: 'Starts',
                                value: _fmt(_start),
                                onTap: () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DateChip(
                                label: 'Ends',
                                value: _fmt(_end),
                                onTap: () => _pickDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: 'Day by day',
                    subtitle:
                        'Who, what, where, when, why — tap a day to fill it in',
                  ),
                  for (var i = 0; i < _days.length; i++)
                    _DayFormCard(
                      key: ValueKey(_days[i].date.toIso8601String()),
                      color: widget.trip.color,
                      editors: _days[i],
                      initiallyExpanded: i == 0,
                      decoration: _fieldDecoration,
                      onRemove: () => _removeDay(i),
                    ),
                  TextButton.icon(
                    onPressed: _addDay,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add a day'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Would export these days to your phone calendar.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Export to calendar'),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _confirmDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                          side: const BorderSide(color: Color(0x55B42318)),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
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

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayFormCard extends StatelessWidget {
  const _DayFormCard({
    super.key,
    required this.color,
    required this.editors,
    required this.initiallyExpanded,
    required this.decoration,
    required this.onRemove,
  });

  final Color color;
  final _DayEditors editors;
  final bool initiallyExpanded;
  final InputDecoration Function(String label, String hint) decoration;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final day = editors.toDay();
    return SoftTile(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          title: Text(
            day.cardTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            day.summary.isEmpty ? 'Tap to fill this day' : day.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          children: [
            TextField(
              controller: editors.who,
              textCapitalization: TextCapitalization.sentences,
              decoration: decoration('Who', 'Just us, friends, a table of 6…'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editors.what,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: decoration(
                'What',
                'Market morning, tram ride, rest day…',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editors.where,
              textCapitalization: TextCapitalization.sentences,
              decoration: decoration('Where', 'Alfama, the coast, one café…'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editors.when,
              textCapitalization: TextCapitalization.sentences,
              decoration: decoration('When', 'Morning, 7pm, sunset, all day…'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editors.why,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: decoration(
                'Why',
                'Why this day matters, or the feeling you want',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                ),
                child: const Text('Remove day'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
