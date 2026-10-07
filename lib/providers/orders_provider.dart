import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/meal.dart';
import '../model/order.dart';

class OrdersDatabaseHelper {
  static const _databaseName = 'orders.db';
  static const _databaseVersion = 1;
  static const _tableName = 'orders';

  OrdersDatabaseHelper._privateConstructor();

  static final OrdersDatabaseHelper instance =
      OrdersDatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
           CREATE TABLE $_tableName (
             number INTEGER PRIMARY KEY AUTOINCREMENT,
             tableId INTEGER NOT NULL,
             date TEXT NOT NULL,
             orderedMeals TEXT NOT NULL
             )
           ''');
  }

// Methods for inserting, updating, deleting, and querying orders
  Future<int> insertOrder(Order order) async {
    Database db = await instance.database;
    final orderMap = order.toMap();
    orderMap.remove('number');
    return await db.insert(_tableName, order.toMap());
  }

  Future<List<Order>> getOrders() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<void> deleteOrder(int orderNumber) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'number = ?',
      whereArgs: [orderNumber],
    );
  }

  Future<void> updateMealPrice(
      int orderNumber, String mealName, double newPrice) async {
    final db = await database;

    // 1. Get the specific order
    final orderMap = await db.query(
      _tableName,
      where: 'number = ?',
      whereArgs: [orderNumber],
    );

    // 2. Update the price and save the order
    if (orderMap.isNotEmpty) {
      final order = Order.fromMap(orderMap.first);

      // Update the price in the order's orderedMeals
      order.orderedMeals[MealData(name: mealName, price: newPrice)] =
          order.orderedMeals[order.orderedMeals.keys
              .firstWhere((mealData) => mealData.name == mealName)]!;
      order.orderedMeals.remove(order.orderedMeals.keys.firstWhere((mealData) =>
          mealData.name == mealName && mealData.price != newPrice));

      // Save the updated order
      await db.update(
        _tableName,
        order.toMap(),
        where: 'number = ?',
        whereArgs: [orderNumber],
      );
    }
  }

  Future<Order?> getOrder(int orderNumber) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'number = ?',
      whereArgs: [orderNumber],
    );
    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null; // Return null if no order is found
  }

  // Add a new method to update the order in the database
  Future<void> updateOrder(int orderNumber, Order order) async {
    Database db = await instance.database;
    await db.update(
      _tableName,
      order.toMap(),
      where: 'number = ?',
      whereArgs: [orderNumber],
    );
  }
}

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(const []);

  // Method to load orders from the database
  Future<void> loadOrders() async {
    final databaseHelper = OrdersDatabaseHelper.instance;
    final orders = await databaseHelper.getOrders();
    state = orders;
  }

  // Method to add an order
  Future<int> addOrder(Order order) async {
    final databaseHelper = OrdersDatabaseHelper.instance;
    final orderNumber = await databaseHelper.insertOrder(order);
    order.number = orderNumber;
    state = [...state, order]; // Update the state with the new order
    log('The new order number $orderNumber in OrderNotifier');

    return orderNumber;
  }

  // Method to delete an order
  Future<void> deleteOrder(int orderNumber) async {
    final databaseHelper = OrdersDatabaseHelper.instance;
    await databaseHelper.deleteOrder(orderNumber);
    state = state
        .where((order) => order.number != orderNumber)
        .toList(); // Update the state
  }

  // Method to update meal price
  Future<void> updateMealPrice(
      int orderNumber, String mealName, double newPrice) async {
    final databaseHelper = OrdersDatabaseHelper.instance;
    await databaseHelper.updateMealPrice(orderNumber, mealName, newPrice);

    state = state.map((order) {
      if (order.number == orderNumber) {
        // Create a new map with the updated MealData and quantity
        final updatedOrderedMeals = Map<MealData, int>.from(order.orderedMeals);
        updatedOrderedMeals[MealData(name: mealName, price: newPrice)] =
            updatedOrderedMeals[updatedOrderedMeals.keys
                .firstWhere((mealData) => mealData.name == mealName)]!;
        updatedOrderedMeals.remove(updatedOrderedMeals.keys.firstWhere(
            (mealData) =>
                mealData.name == mealName && mealData.price != newPrice));

        // Return a new Order object with the updated orderedMeals
        return Order(
          number: order.number,
          tableId: order.tableId,
          orderedMeals: updatedOrderedMeals,
        );
      } else {
        return order;
      }
    }).toList();
  }

  // Add this method to OrdersNotifier
  Future<Order?> getOrder(int orderNumber) async {
    final databaseHelper = OrdersDatabaseHelper.instance;
    return await databaseHelper.getOrder(orderNumber);
  }

  // Add a new method to update the order and save to the database
  Future<void> updateOrder(
      int orderNumber, Map<MealData, int> newOrderedMeals) async {
    final databaseHelper = OrdersDatabaseHelper.instance;
    final order = await databaseHelper.getOrder(orderNumber);

    if (order != null) {
      order.orderedMeals = newOrderedMeals;
      await databaseHelper.updateOrder(orderNumber, order);

      // Update the state
      state = state.map((o) {
        if (o.number == orderNumber) {
          return order;
        } else {
          return o;
        }
      }).toList();
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>(
  (ref) => OrdersNotifier(),
);
