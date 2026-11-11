import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/appointment_screen.dart';
import 'package:mobile/models/account_model.dart';
import 'package:mobile/models/appointment_model.dart';

void main() {
  group('Appointment & Date Formatting Tests', () {
    test('formatIndonesianDate formats DateTime correctly', () {
      final date = DateTime(2026, 3, 12);
      final formatted = formatIndonesianDate(date);
      expect(formatted, equals('Kamis, 12 Maret 2026'));

      final date2 = DateTime(2026, 1, 1);
      final formatted2 = formatIndonesianDate(date2);
      expect(formatted2, equals('Kamis, 01 Januari 2026'));
    });

    test('displayScheduledDate handles valid and invalid strings safely', () {
      expect(displayScheduledDate('2026-03-12'), equals('Kamis, 12 Maret 2026'));
      expect(displayScheduledDate('invalid-date'), equals('invalid-date'));
    });

    test('rupiahValue parses various representations without error', () {
      expect(rupiahValue(1500000), equals(1500000));
      expect(rupiahValue(1500000.0), equals(1500000));
      expect(rupiahValue('1500000'), equals(1500000));
      expect(rupiahValue('1500000.00'), equals(1500000));
      expect(rupiahValue(null), equals(0));
    });

    test('AppointmentModel & AppointmentPage parse safely', () {
      final json = {
        'id': 1,
        'appointment_code': 'TRX-APPT-20260312-0001',
        'amount': '1500000',
        'scheduled_date': '2026-03-12',
        'notes': 'Keperluan sekolah',
        'status': 'pending',
        'creator_role': 'student',
        'created_at': '2026-03-11T10:00:00Z',
      };
      final appt = AppointmentModel.fromJson(json);
      expect(appt.id, equals(1));
      expect(appt.amount, equals(1500000));
      expect(appt.appointmentCode, equals('TRX-APPT-20260312-0001'));

      final pageJson = {
        'current_page': 1,
        'last_page': 1,
        'total': 1,
        'data': [json],
      };
      final page = AppointmentPage.fromJson(pageJson);
      expect(page.items.length, equals(1));
      expect(page.total, equals(1));
    });
  });
}

