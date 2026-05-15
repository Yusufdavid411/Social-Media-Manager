import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_manager/main.dart';

void main() {
  testWidgets('shows API-ready auth screen', (tester) async {
    await tester.pumpWidget(const SocialMediaManagerApp());

    expect(find.text('Social Media Manager'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
