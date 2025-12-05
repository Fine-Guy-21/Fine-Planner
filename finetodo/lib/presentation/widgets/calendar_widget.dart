import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late TextEditingController _gotoController;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _gotoController = TextEditingController(
      text: _selectedDay.toString().split(' ')[0],
    );
  }

  @override
  void dispose() {
    _gotoController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    // Match yyyy-MM-dd
    final isoMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      try {
        return DateTime(y, m, d);
      } catch (_) {
        return null;
      }
    }

    // Match dd/MM/yyyy
    final dmyMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s);
    if (dmyMatch != null) {
      final d = int.parse(dmyMatch.group(1)!);
      final m = int.parse(dmyMatch.group(2)!);
      final y = int.parse(dmyMatch.group(3)!);
      try {
        return DateTime(y, m, d);
      } catch (_) {
        return null;
      }
    }

    // Fallback to tryParse for other ISO-like formats
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(0001),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _gotoController.text = _selectedDay.toString().split(' ')[0];
              });
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gotoController,
                    decoration: const InputDecoration(
                      labelText: 'Go to date (yyyy-MM-dd or dd/MM/yyyy)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Pick date',
                  icon: const Icon(Icons.date_range),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDay,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked != null) {
                      setState(() {
                        _gotoController.text = picked.toString().split(' ')[0];
                        _selectedDay = picked;
                        _focusedDay = picked;
                      });
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    final input = _gotoController.text.trim();
                    final parsed = _parseDate(input);
                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Invalid date format. Use yyyy-MM-dd or dd/MM/yyyy',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _selectedDay = parsed;
                      _focusedDay = parsed;
                    });
                  },
                  child: const Text('Go'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Selected: ${_selectedDay.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ],
      ),
    );
  }
}
