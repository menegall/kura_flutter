import 'package:flutter/material.dart';
import '../../../core/app_navigation.dart';
import '../../../core/theme.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';

/// Struttura principale dopo il login: tre schede (Pupilli, Statistiche,
/// Impostazioni) con il menu in basso sul telefono e a sinistra su schermi
/// larghi. Le schede restano in vita (IndexedStack) così conservano i filtri
/// scelti; a ogni cambio ricaricano i dati tramite [appDataRefresh].
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    currentAppTab.value = AppTab.pupils;
    currentAppTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    currentAppTab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    appDataRefresh.value++;
    setState(() {});
  }

  void _select(int index) {
    if (index != currentAppTab.value) currentAppTab.value = index;
  }

  static const _destinations = [
    (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Pupilli'),
    (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Statistiche'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Impostazioni'),
  ];

  // Le schede Statistiche e Impostazioni hanno una chiave per poterle
  // evidenziare nel tutorial (che parte sempre dalla scheda Pupilli, quindi
  // basta la versione non selezionata).
  GlobalKey? _tourKey(int index) => switch (index) {
    AppTab.stats => TourKeys.statsTab,
    AppTab.settings => TourKeys.settingsTab,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final index = currentAppTab.value;
    final isWide = MediaQuery.of(context).size.width > 800;
    final pages = IndexedStack(
      index: index,
      children: const [HomePage(), StatsPage(), SettingsPage()],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              indicatorColor: AppColors.beige,
              selectedIconTheme: const IconThemeData(color: AppColors.darkGreen),
              unselectedIconTheme: const IconThemeData(color: AppColors.blueGrey),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.blueGrey),
              destinations: [
                for (var i = 0; i < _destinations.length; i++)
                  NavigationRailDestination(
                    icon: KeyedSubtree(key: _tourKey(i), child: Icon(_destinations[i].icon)),
                    selectedIcon: Icon(_destinations[i].selectedIcon),
                    label: Text(_destinations[i].label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, color: AppColors.beige),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _select,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.beige,
        destinations: [
          for (var i = 0; i < _destinations.length; i++)
            NavigationDestination(
              key: _tourKey(i),
              icon: Icon(_destinations[i].icon),
              selectedIcon: Icon(_destinations[i].selectedIcon),
              label: _destinations[i].label,
            ),
        ],
      ),
    );
  }
}
