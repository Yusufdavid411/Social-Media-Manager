import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_manager/main.dart';

void main() {
  testWidgets('shows auth screen when Firebase is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const SocialMediaManagerApp(
        firebaseStatus: FirebaseBootstrap(isReady: false),
      ),
    );

    expect(find.text('Social Media Manager'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
