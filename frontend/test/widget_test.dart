// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:rag/app.dart';
import 'package:rag/screens/voice_assistant_screen.dart';

void main() {
  testWidgets('Voice Assistant app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app title is displayed.
    expect(find.text('Personal Assistant RAG'), findsOneWidget);

    // Verify that the voice assistant screen is present.
    expect(find.byType(VoiceAssistantScreen), findsOneWidget);
  });
}
