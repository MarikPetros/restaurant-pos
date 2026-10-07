import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/tables.dart';
import '../model/order.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTableTap,
    this.isPaid = false,
  });

  final Order order;
  final Function(int tableId) onTableTap;
  final bool isPaid;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _isPaid =
        widget.isPaid; // Initialize the local state from the widget's parameter
  }

  @override
  Widget build(BuildContext context) {
    final table = tables[widget.order.tableId];

    void handleTableTap(int tableId) {
      setState(() {
        _isPaid = !_isPaid; // Toggle the paid state
      });
      widget.onTableTap(tableId); // Call the callback
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => handleTableTap(table.id),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              width: 28,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: _isPaid
                      ? Colors.greenAccent
                      : table.luxury == 'Vip1'
                          ? Colors.amber.shade100
                          : Colors.lightBlue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Icon(
                    _isPaid
                        ? Icons.add_card_sharp
                        : table.luxury == 'Vip1'
                            ? Icons.table_restaurant
                            : Icons.chair_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Посетитель',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        Row(children: [
                          Text(
                            ('№${widget.order.number}'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Text(
                            DateFormat('HH.mm')
                                .format(widget.order.creationDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          table.furniture,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          widget.order.orderPrice.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
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
