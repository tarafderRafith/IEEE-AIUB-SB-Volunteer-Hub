import 'package:flutter_test/flutter_test.dart';
import 'package:ieee_volunteer_hub/main.dart';

void main() {
  testWidgets('Volunteer Hub loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VolunteerHubApp());

    expect(find.text('IEEE AIUB Student Branch Volunteer Hub'), findsOneWidget);
  });
}