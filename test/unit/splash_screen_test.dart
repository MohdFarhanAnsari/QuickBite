import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/theme/app_theme.dart';
import 'package:quickbite/features/splash/presentation/screens/splash_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('QuickBite Branded Splash Screen Tests', () {
    testWidgets(
      'Displays logo, QuickBite title, both taglines, and warm background',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(duration: Duration(milliseconds: 1000)),
          ),
        );

        // Verify warm off-white background color
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.primarySurface);

        // Advance animation
        await tester.pump(const Duration(milliseconds: 400));

        // Verify QuickBite logo image exists
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Image>(imageFinder);
        expect(
          (imageWidget.image as AssetImage).assetName,
          'assets/logo/app_logo_foreground.png',
        );

        // Verify title & taglines rendered
        expect(find.text('QuickBite'), findsOneWidget);
        expect(find.text('Good food. Quick delivery.'), findsOneWidget);
        expect(find.text('Fresh taste, delivered fast.'), findsOneWidget);

        // Finish remaining animation & timer
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Navigates automatically to Home route (/) after duration', (
      WidgetTester tester,
    ) async {
      final testRouter = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) =>
                const SplashScreen(duration: Duration(milliseconds: 600)),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Home Destination Screen')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            theme: AppTheme.lightTheme,
          ),
        ),
      );

      // Initially on splash screen
      expect(find.text('QuickBite'), findsOneWidget);
      expect(find.text('Home Destination Screen'), findsNothing);

      // Advance beyond splash duration
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Should automatically have navigated to Home Screen
      expect(find.text('Home Destination Screen'), findsOneWidget);
    });
  });
}
