import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:suruchi/domain/entities/reminder_category.dart';
import 'package:suruchi/shared/widgets/category_card.dart';

void main() {
  testWidgets('CategoryCard shows label and today count', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: ReminderCategory.seva,
            todayCount: 2,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Seva'), findsOneWidget);
    expect(find.text('2 today'), findsOneWidget);

    await tester.tap(find.byType(CategoryCard));
    expect(tapped, isTrue);
  });
}
