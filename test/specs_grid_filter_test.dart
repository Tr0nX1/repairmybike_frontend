import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairmybike/ui/spare_part_detail_page.dart' show SpecsGridPreview;

void main() {
  testWidgets('SpecsGrid hides empty and dash values', (tester) async {
    final items = {
      'Brand': 'Amaron',
      'SKU': 'AP-BTZ4',
      'Empty': '',
      'Dash': '—',
    };
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SpecsGridPreview(items: items))));
    await tester.pumpAndSettle();
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('SKU'), findsOneWidget);
    expect(find.text('Empty'), findsNothing);
    expect(find.text('Dash'), findsNothing);
  });
}
