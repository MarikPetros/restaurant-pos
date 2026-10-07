import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer(
      {super.key,
      required this.name,
      required this.role,
      required this.time,
      required this.onSelectScreen});

  final String name;
  final String role;
  final String time;
  final void Function(String identifier) onSelectScreen;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 16),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    role,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.sync,
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Синхронизация',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '($time)',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            onTap: () {
              // _synchrinize; // TODO should change
              onSelectScreen('home');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.money, // TODO change
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Кассир',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              onSelectScreen('cashier_screen');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.man, // TODO change
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Официант',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              onSelectScreen('waiter_screen');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.add_shopping_cart, // TODO change
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Режим продаж',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              onSelectScreen('sell_regime');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.list_alt, // TODO change
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Склад',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              onSelectScreen('store_screen');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.arrow_right_alt, // TODO change
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Сменить сотрудника',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              // _chengeEmployee;
            },
          ),
        ],
      ),
    );
  }
}
