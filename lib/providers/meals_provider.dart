import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:waiter_app/model/meal.dart';

class MealsDatabaseHelper {
  static const _databaseName = 'meals.db';
  static const _databaseVersion = 4;
  static const table = 'meals';
  static const columnId = '_id';
  static const columnCategory = 'category';
  static const columnName = 'name';
  static const columnImageUrl = 'imageUrl';
  static const columnPrice = 'price';
  static const columnQuantity = 'quantity';
  static const columnImagePath = 'imagePath';
  static const columnDiscountedPrice = 'discountedPrice';

  MealsDatabaseHelper._privateConstructor();

  static final MealsDatabaseHelper instance =
      MealsDatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<sqflite.Database> _initDatabase() async {
    log('Initializing database...');
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    log('Creating database table...');
    await db.execute('''
          CREATE TABLE $table (
            $columnId TEXT PRIMARY KEY,
            $columnCategory TEXT NOT NULL,
            $columnName TEXT NOT NULL,
            $columnImageUrl TEXT NOT NULL,
            $columnPrice REAL NOT NULL,
            $columnQuantity INTEGER, 
            $columnImagePath TEXT,
            $columnDiscountedPrice REAL
          )
          ''');
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    log('onUpgrade called: oldVersion=$oldVersion, newVersion=$newVersion');
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN discountedPrice REAL');
        log('$columnDiscountedPrice column added successfully');
      } catch (e) {
        log('Error adding $columnDiscountedPrice column: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN imagePath TEXT');
        log('imagePath column added successfully');
      } catch (e) {
        log('Error adding imagePath column: $e');
      }
    }
  }

  // Insert a new meal
  Future<int> _insertMeal(Meal meal) async {
    log('Inserting meal: ${meal.toMap()}');
    Database db = await instance.database;
    return await db.insert(table, meal.toMap());
  }

  Future<void> _updateMealWithImageData(Meal meal, String imagePath) async {
    final db = await MealsDatabaseHelper.instance.database;
    await db.update(
      'meals',
      {'imagePath': imagePath},
      where: '_id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<bool> databaseExists() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, _databaseName));
    return dbFile.exists();
  }

  Future<void> deleteDatabase() async {
    log('Deleting database...');
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, _databaseName));
    if (dbFile.existsSync()) {
      await sqflite.deleteDatabase(join(dbPath, _databaseName));
    }
  }

  Future<int> insertMealPublicly(Meal meal) async {
    return _insertMeal(meal);
  }
}

Future<Uint8List?> _downloadAndConvertImage(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    final image = img.decodeImage(response.bodyBytes);
    if (image != null) {
      return Uint8List.fromList(img.encodePng(image));
    }
  }
  return null;
}

class MealsNotifier extends StateNotifier<List<Meal>> {
  MealsNotifier() : super(const []);

  factory MealsNotifier.withDatabase(MealsDatabaseHelper mealsDatabaseHelper) {
    final notifier = MealsNotifier();
    notifier._mealsDatabaseHelper =
        mealsDatabaseHelper; // Set the database helper
    return notifier;
  }

  set _mealsDatabaseHelper(MealsDatabaseHelper mealsDatabaseHelper) {}

  Future<void> populateMealsDatabase(BuildContext context) async {
    final meals = [
      Meal(
        category: 'food',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Spaghetti_Bolognese_mit_Parmesan_oder_Grana_Padano.jpg/800px-Spaghetti_Bolognese_mit_Parmesan_oder_Grana_Padano.jpg',
        name: 'Spaghetti',
        price: 1500,
        quantity: 7,
      ),
      Meal(
        category: 'beverage',
        imageUrl:
            'https://www.coca-cola.com/content/dam/onexp/us/en/brands/coca-cola-original/en_coca-cola-original-taste-20-oz_750x750_v1.jpg/width2674.jpg',
        name: 'Coca-Cola Classic 2л Пластик',
        price: 400,
        quantity: 25,
      ),
      Meal(
        category: 'food',
        imageUrl:
            'https://cdn.pixabay.com/photo/2018/03/31/19/29/schnitzel-3279045_1280.jpg',
        name: 'Winter Schnitzel',
        price: 2800,
        quantity: 12,
      ),
      Meal(
        category: 'beverage',
        imageUrl:
            'https://images.unsplash.com/photo-1600271886742-f049cd451bba?q=80&w=2487&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        name: 'Orange juice',
        price: 2000,
        quantity: 8,
      ),
      Meal(
        category: 'food',
        imageUrl:
            'https://cdn.pixabay.com/photo/2016/10/25/13/29/smoked-salmon-salad-1768890_1280.jpg',
        name: 'Salad with Smoked Salmon',
        price: 1200,
        quantity: 16,
      ),
      Meal(
        category: 'beverage',
        imageUrl:
            'https://bazaar.qniti.com/wp-content/uploads/2024/04/plain-water.png',
        name: 'Plain water',
        price: 100,
        quantity: 45,
      )
    ];

    for (var meal in meals) {
      await MealsDatabaseHelper.instance._insertMeal(meal);

      await _updateMealWithImageData(meal);
    }
  }

  Future<void> _updateMealWithImageData(Meal meal) async {
    final imageData = await _downloadAndConvertImage(meal.imageUrl);
    if (imageData != null) {
      final imagePath = await _saveImageToStorage(imageData, meal.id);
      await MealsDatabaseHelper.instance
          ._updateMealWithImageData(meal, imagePath);
      updateMealImageData(meal.id, imagePath);
    }
  }

  Future<String> _saveImageToStorage(Uint8List imageData, String mealId) async {
    final directory = await syspaths.getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$mealId.png';

    // Compress the image data
    final compressedImageData = await FlutterImageCompress.compressWithList(
      imageData,
      minHeight: 250,
      minWidth: 250,
      quality: 80,
    );

    final file = File(imagePath);
    await file.writeAsBytes(compressedImageData);
    return imagePath;
  }

  void updateMealImageData(String mealId, String imagePath) {
    state = [
      for (final meal in state)
        if (meal.id == mealId) meal.copyWith(imagePath: imagePath) else meal,
    ];
  }

  Future<void> _updateMealQuantity(String mealId, int newQuantity) async {
    final db = await MealsDatabaseHelper.instance.database;
    await db.update(
      'meals',
      {'quantity': newQuantity},
      where: '_id = ?',
      whereArgs: [mealId],
    );
  }

  Future<List<Meal>> _getMealsFromDatabase() async {
    log('Getting meals from database...');
    Database db = await MealsDatabaseHelper.instance.database;
    List<Map<String, dynamic>> maps = await db.query('meals');
    return List.generate(maps.length, (i) {
      return Meal(
        id: maps[i]['_id'],
        category: maps[i]['category'],
        name: maps[i]['name'],
        imageUrl: maps[i]['imageUrl'],
        price: maps[i]['price'],
        quantity: maps[i]['quantity'],
        imagePath: maps[i]['imagePath'],
        discountedPrice: maps[i]['discountedPrice'],
      );
    });
  }

  Future<void> loadMeals() async {
    state = await _getMealsFromDatabase();
  }

  Future<void> updateQuantity(String mealId, int newQuantity) async {
    await _updateMealQuantity(mealId, newQuantity);

    state = state.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(quantity: newQuantity);
      } else {
        return meal;
      }
    }).toList();
  }
}

final mealsProvider = StateNotifierProvider<MealsNotifier, List<Meal>>(
  (ref) => MealsNotifier(),
);
