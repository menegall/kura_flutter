import 'package:flutter/material.dart';
import '../../../core/app_navigation.dart';
import '../../../core/theme.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';

/// Struttura principale dopo il login: tre schede (Pupilli, Statistiche,
/// Impostazioni) con il menu in basso sul telefono e a sinistra su schermi
/// larghi. Ogni scheda ha il proprio navigatore, così le pagine di dettaglio
/// si aprono dentro la scheda con il menu sempre visibile. Le schede restano
/// in vita (IndexedStack) e conservano filtri e pagine aperte; a ogni cambio
/// ricaricano i dati tramite [appDataRefresh].
class MainShell extends StatefulWidget {
  /// Pagine principali delle schede; di default Pupilli, Statistiche e
  /// Impostazioni (sostituibili nei test).
  final List<Widget>? tabRoots;
  const MainShell({super.key, this.tabRoots});
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
    if (index == currentAppTab.value) {
      // Toccare la scheda già attiva riporta alla sua pagina principale.
      resetTabToRoot(index);
    } else {
      currentAppTab.value = index;
    }
  }

  static const _tabRoots = [HomePage(), StatsPage(), SettingsPage()];

  // Il tasto/gesto "indietro" chiude prima le pagine aperte nella scheda
  // visibile; solo quando la scheda è alla pagina principale agisce l'app.
  Widget _tabNavigator(int tab, bool visible) {
    final key = tabNavigatorKeys[tab];
    return NavigatorPopHandler<Object?>(
      enabled: visible,
      onPopWithResult: (_) => key.currentState?.maybePop(),
      child: Navigator(
        key: key,
        onGenerateInitialRoutes: (navigator, initialRoute) => [
          MaterialPageRoute(builder: (context) => (widget.tabRoots ?? _tabRoots)[tab]),
        ],
      ),
    );
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
      children: [
        for (var tab = 0; tab < tabNavigatorKeys.length; tab++) _tabNavigator(tab, tab == index),
      ],
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
