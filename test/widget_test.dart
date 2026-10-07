import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiter_app/model/meal.dart';
import 'package:waiter_app/model/order.dart';
import 'package:waiter_app/providers/meals_provider.dart';
import 'package:waiter_app/providers/orders_provider.dart';
import 'package:waiter_app/screens/home_screen.dart';

/// Orders notifier with fixed data and no database access.
class FakeOrdersNotifier extends OrdersNotifier {
  FakeOrdersNotifier(List<Order> orders) {
    state = orders;
  }

  @override
  Future<void> loadOrders() async {}
}

/// Meals notifier with fixed data and no database access.
class FakeMealsNotifier extends MealsNotifier {
  FakeMealsNotifier(List<Meal> meals) {
    state = meals;
  }

  @override
  Future<void> loadMeals() async {}
}

Meal _meal(String name, int quantity) => Meal(
      id: name,
      category: 'food',
      name: name,
      price: 100,
      imageUrl: '',
      quantity: quantity,
    );

Future<void> _pumpHome(
  WidgetTester tester, {
  List<Order> orders = const [],
  List<Meal> meals = const [],
}) async {
  // Tall surface so every section of the ListView is built.
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeDataLoaderProvider.overrideWithValue((ref, context) async {}),
        ordersProvider.overrideWith((ref) => FakeOrdersNotifier(orders)),
        mealsProvider.overrideWith((ref) => FakeMealsNotifier(meals)),
      ],
      child: const MaterialApp(home: HomeScreen(title: 'Home')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeScreen', () {
    testWidgets('shows empty states when there are no orders or shortages',
        (tester) async {
      await _pumpHome(tester, meals: [_meal('Борщ', 20)]);

      expect(find.text('Home'), findsOneWidget);
      // '0' open orders and '0' total.
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('6 / 6'), findsOneWidget); // all tables free
      expect(find.text('Заказов пока нет'), findsOneWidget);
      expect(find.text('Все позиции в наличии'), findsOneWidget);
    });

    testWidgets('shows quick actions', (tester) async {
      await _pumpHome(tester);

      for (final label in ['Новый заказ', 'Кассир', 'Режим продаж', 'Склад']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('summarises open orders and busy tables', (tester) async {
      final orders = [
        Order(
          number: 1,
          tableId: 1,
          orderedMeals: {MealData(name: 'Борщ', price: 500): 2}, // 1000
          creationDate: DateTime(2025, 1, 1, 12, 0),
        ),
        Order(
          number: 2,
          tableId: 3,
          orderedMeals: {MealData(name: 'Чай', price: 200): 1}, // 200
          creationDate: DateTime(2025, 1, 1, 13, 30),
        ),
      ];

      await _pumpHome(tester, orders: orders);

      expect(find.text('2'), findsOneWidget); // open orders
      expect(find.text('4 / 6'), findsOneWidget); // 2 of 6 tables busy
      expect(find.text('1200'), findsOneWidget); // total of open orders

      // Recent orders: newest first.
      expect(find.text('Заказ №1'), findsOneWidget);
      expect(find.text('Заказ №2'), findsOneWidget);
      expect(find.text('Стол 3 · 1 поз. · 13:30'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Заказ №2')).dy,
        lessThan(tester.getTopLeft(find.text('Заказ №1')).dy),
      );
    });

    testWidgets('lists only meals that are running low, lowest first',
        (tester) async {
      await _pumpHome(tester, meals: [
        _meal('Чай', 3),
        _meal('Борщ', 20),
        _meal('Хлеб', 0),
      ]);

      expect(find.text('Хлеб'), findsOneWidget);
      expect(find.text('Чай'), findsOneWidget);
      expect(find.text('Борщ'), findsNothing);
      expect(find.text('0 шт.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Хлеб')).dy,
        lessThan(tester.getTopLeft(find.text('Чай')).dy),
      );
    });
  });
}
