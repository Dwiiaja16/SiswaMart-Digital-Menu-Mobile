import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siswamart_mobile/core/theme.dart';
import 'package:siswamart_mobile/screens/main_navigation.dart';
import 'package:siswamart_mobile/screens/catalog_screen.dart';
import 'package:siswamart_mobile/screens/how_to_order_screen.dart';
import 'package:siswamart_mobile/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: neoTheme,
        home: const SplashScreen(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('MainNavigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: neoTheme,
        home: const MainNavigation(),
      ),
    );

    // 1. Initial Beranda tab
    expect(find.text('SiswaMart'), findsOneWidget);
    expect(find.text('SMKN 11 Bandung'), findsWidgets);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Katalog'), findsOneWidget);
    expect(find.text('Cara Pesan'), findsOneWidget);

    // 2. Switch to Katalog tab
    await tester.tap(find.text('Katalog'));
    await tester.pump();
    expect(find.byType(CatalogScreen), findsOneWidget);

    // 3. Switch to Cara Pesan tab
    await tester.tap(find.text('Cara Pesan'));
    await tester.pump();
    expect(find.byType(HowToOrderScreen), findsOneWidget);
    expect(find.text('PANDUAN 4 LANGKAH PESAN'), findsOneWidget);
  });
}
