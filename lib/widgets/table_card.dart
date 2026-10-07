import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waiter_app/data/tables.dart';

class TableCard extends ConsumerWidget {
  const TableCard({
    super.key,
    required this.cardSize,
    required this.table,
    required this.onTableTap,
  });

  final double cardSize;
  final RestaurantTable table;
  final Function(int tableId) onTableTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => onTableTap(table.id),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: SizedBox(
          width: cardSize,
          height: cardSize - cardSize / 4,
          child: Stack(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: Colors.white,
                child: Center(
                  child: Text(
                    table.luxury,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                bottom: 8,
                width: cardSize / 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: table.luxury == 'Vip1'
                        ? Colors.amber.shade100
                        : Colors.lightBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Icon(
                      table.luxury == 'Vip1'
                          ? Icons.table_restaurant
                          : Icons.chair_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
