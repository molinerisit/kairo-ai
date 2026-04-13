import 'package:flutter/material.dart';
import 'calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  List<CalendarEvent> _events  = [];
  bool                _loading = false;
  String?             _error;
  DateTime            _month   = DateTime.now();

  List<CalendarEvent> get events  => _events;
  bool                get loading => _loading;
  String?             get error   => _error;
  DateTime            get month   => _month;

  void setMonth(DateTime month) {
    _month = month;
    loadEvents();
  }

  Future<void> loadEvents() async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final from = DateTime(_month.year, _month.month, 1);
      final to   = DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);
      _events = await CalendarService.listEvents(from: from, to: to);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent({
    required String  title,
    String?          description,
    required DateTime startsAt,
    required DateTime endsAt,
    String?          contactName,
    String?          contactPhone,
  }) async {
    await CalendarService.createEvent(
      title:        title,
      description:  description,
      startsAt:     startsAt,
      endsAt:       endsAt,
      contactName:  contactName,
      contactPhone: contactPhone,
    );
    await loadEvents();
  }

  Future<void> updateStatus(String id, String status) async {
    await CalendarService.updateStatus(id, status);
    await loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await CalendarService.deleteEvent(id);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
