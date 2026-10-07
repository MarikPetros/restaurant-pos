import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:waiter_app/data/tables.dart';
import 'package:waiter_app/model/order.dart';
import 'package:waiter_app/providers/meals_provider.dart';
import 'package:waiter_app/screens/cashier_screen.dart';
import 'package:waiter_app/screens/sell_screen.dart';
import 'package:waiter_app/screens/store_screen.dart';
import 'package:waiter_app/screens/waiter_screen.dart';
import 'package:waiter_app/widgets/commmon_scaffold.dart';
import 'package:waiter_app/widgets/custom_app_bar.dart';

import '../providers/orders_provider.dart';

/// Meals at or below this stock level are shown as "running low".
const int kLowStockThreshold = 5;

typedef HomeDataLoader = Future<void> Function(
    WidgetRef ref, BuildContext context);

/// Loads everything the home screen needs: seeds the meals database on first
/// launch, then loads meals and orders into their providers.
Future<void> loadHomeData(WidgetRef ref, BuildContext context) async {
  final databaseExists = await MealsDatabaseHelper.instance.databaseExists();
  if (!databaseExists && context.mounted) {
    await ref.read(mealsProvider.notifier).populateMealsDatabase(context);
  }
  await Future.wait([
    ref.read(mealsProvider.notifier).loadMeals(),
    ref.read(ordersProvider.notifier).loadOrders(),
  ]);
}

/// Overridable in tests so the screen can be rendered without SQLite.
final homeDataLoaderProvider = Provider<HomeDataLoader>((_) => loadHomeData);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await ref.read(homeDataLoaderProvider)(ref, context);
    if (mounted) setState(() => _loading = false);
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final meals = ref.watch(mealsProvider);

    final busyTableIds = orders.map((o) => o.tableId).toSet();
    final freeTables = tables.length - busyTableIds.length;
    final openTotal = orders.fold<double>(0, (sum, o) => sum + o.orderPrice);
    final lowStock = meals
        .where((m) => m.quantity <= kLowStockThreshold)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    final recentOrders = [...orders]
      ..sort((a, b) => b.creationDate.compareTo(a.creationDate));

    return CommonScaffold(
      appBar: CustomAppBar(
        title: widget.title,
        onSearchPress: () {},
        showDrawerIcon: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _GreetingHeader(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.receipt_long,
                          label: 'Открытые заказы',
                          value: '${orders.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.table_restaurant,
                          label: 'Свободные столы',
                          value: '$freeTables / ${tables.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payments_outlined,
                          label: 'Сумма',
                          value: openTotal.toStringAsFixed(0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Быстрые действия'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: [
                      _ActionTile(
                        icon: Icons.room_service_outlined,
                        label: 'Новый заказ',
                        onTap: () => _open(const WaiterScreen()),
                      ),
                      _ActionTile(
                        icon: Icons.point_of_sale,
                        label: 'Кассир',
                        onTap: () => _open(const CashierScreen()),
                      ),
                      _ActionTile(
                        icon: Icons.add_shopping_cart,
                        label: 'Режим продаж',
                        onTap: () => _open(const SellScreen()),
                      ),
                      _ActionTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Склад',
                        onTap: () => _open(const StoreScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Последние заказы'),
                  if (recentOrders.isEmpty)
                    const _EmptyHint('Заказов пока нет')
                  else
                    ...recentOrders.take(5).map(
                          (order) => _OrderTile(
                            order: order,
                            onTap: order.number == null
                                ? null
                                : () => _open(
                                    SellScreen(orderNumber: order.number!)),
                          ),
                        ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Заканчивается на складе'),
                  if (lowStock.isEmpty)
                    const _EmptyHint('Все позиции в наличии')
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: lowStock
                            .take(5)
                            .map(
                              (meal) => ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.warning_amber_rounded,
                                  color: meal.quantity == 0
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.orange,
                                ),
                                title: Text(meal.name),
                                trailing: Text('${meal.quantity} шт.'),
                                onTap: () => _open(const StoreScreen()),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Доброе утро'
        : hour < 18
            ? 'Добрый день'
            : 'Добрый вечер';

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy  HH:mm').format(now),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, this.onTap});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final itemsCount =
        order.orderedMeals.values.fold<int>(0, (sum, q) => sum + q);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${order.tableId}')),
        title: Text('Заказ №${order.number ?? '-'}'),
        subtitle: Text(
          'Стол ${order.tableId} · $itemsCount поз. · '
          '${DateFormat('HH:mm').format(order.creationDate)}',
        ),
        trailing: Text(
          order.orderPrice.toStringAsFixed(0),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
