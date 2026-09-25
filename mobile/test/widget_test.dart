import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beresapp/core/widgets/gps_requirement_dialog.dart';

void main() {
  testWidgets('GpsRequirementDialog renders properly and responds to button tap', (WidgetTester tester) async {
    bool accepted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GpsRequirementDialog(
            isTukang: true,
            onAccepted: () {
              accepted = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Aktivasi GPS & Izin Lokasi Wajib'), findsOneWidget);
    expect(find.text('Saya Mengerti & Sudah Aktifkan GPS'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);

    await tester.tap(find.text('Saya Mengerti & Sudah Aktifkan GPS'));
    await tester.pump();

    expect(accepted, isTrue);
  });
}
