import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairmybike/ui/widgets/rm_app_bar.dart';

void main() {
  testWidgets('Back button hidden on root, visible after push, pops on tap', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: const RMAppBar(title: 'Home')),
      routes: {
        '/second': (_) => Scaffold(appBar: const RMAppBar(title: 'Second')),
      },
    ));

    expect(find.byTooltip('Back'), findsNothing);

    Navigator.of(tester.element(find.byType(Scaffold))).pushNamed('/second');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}