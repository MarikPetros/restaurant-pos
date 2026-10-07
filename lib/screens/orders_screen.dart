import 'package:flutter/material.dart';
import 'package:waiter_app/widgets/order_card.dart';

import '../model/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.ordersList});

  final List<Order> ordersList;

  @override
  State<OrdersScreen> createState() {
    return _OrderScreenState();
  }
}

class _OrderScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollCacheExtent: ScrollCacheExtent.pixels(1.5), itemExtent: 80,
      itemCount: widget.ordersList.length,
      itemBuilder: (ctx, index) {
        final order = widget.ordersList[index];
        return OrderCard(
          key: ValueKey(order.number),
          order: order,
          onTableTap: (tableId) {},
        );
      },
    );
  }
}
