import 'package:flutter/material.dart';
import 'package:kozo/waiterScreen/waiterMakeNewOrder.dart';
import 'package:kozo/waiterScreen/waiterOrder_screen.dart';
import 'package:kozo/waiterScreen/waiter_dashboard.dart';
import 'package:kozo/waiterScreen/waiter_reporting_sccreen.dart';
import '../cashierScreens/login_screen.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

class NavRailMainWaiter extends StatefulWidget {
  final int initialIndex;

  const NavRailMainWaiter({super.key, this.initialIndex = 0});

  @override
  State<NavRailMainWaiter> createState() => _NavRailMainWaiterState();
}

class _NavRailMainWaiterState extends State<NavRailMainWaiter> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set initial index
  }

  // List of screens to display based on selected index
  final List<Widget> _screens = [
    const WaiterDashboardScreen(),
    const Waitermakeneworder(),
    // DesktopReceiptPrinter(),
    const WaiterorderScreen(),
    // const WaiterReportingScreen(), // Add the Report Screen
    // const ProfileScreen(), // Profile screen for the bottom destination
  ];

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 66.0, horizontal: 8.0),
              child: NavigationRail(
                backgroundColor: AppColors.white,
                selectedIndex: _selectedIndex <= 4 ? _selectedIndex : null,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: AppIconThemes.selectedIcon,
                selectedLabelTextStyle: AppTextStyles.navSelected,
                unselectedIconTheme: AppIconThemes.unselectedIcon,
                unselectedLabelTextStyle: AppTextStyles.navUnselected,

                //Add trailing widget for bottom destination (Profile)
                trailing: Container(
                  margin: const EdgeInsets.only(top: 50.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // InkWell(
                      //   onTap: () {
                      //     setState(() {
                      //       _selectedIndex = 4; // Profile index
                      //     });
                      //   },
                      //   borderRadius: BorderRadius.circular(12),
                      //   child: Container(
                      //     padding: const EdgeInsets.all(12.0),
                      //     decoration: BoxDecoration(
                      //       color: _selectedIndex == 4
                      //           ? AppColors.primary.withOpacity(0.1)
                      //           : Colors.transparent,
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     child: Column(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(
                      //           _selectedIndex == 4
                      //               ? Icons.person
                      //               : Icons.person_outline,
                      //           color: _selectedIndex == 4
                      //               ? AppColors.primary
                      //               : AppColors.grey,
                      //           size: 24,
                      //         ),
                      //         const SizedBox(height: 4),
                      //         Text(
                      //           'Profile',
                      //           style: _selectedIndex == 4
                      //               ? AppTextStyles.navSelected
                      //               : AppTextStyles.navUnselected,
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 20),
                      // Logout Button
                      InkWell(
                        onTap: () => _showLogoutDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.add_box),
                    selectedIcon: Icon(Icons.add_box),
                    label: Text('New Order'),
                  ),
                  // NavigationRailDestination(
                  //   icon: Icon(Icons.shopping_cart_outlined),
                  //   selectedIcon: Icon(Icons.shopping_cart),
                  //   label: Text('Current Cart'),
                  // ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: Text('Order History'),
                  ),
                  // NavigationRailDestination(
                  //   icon: Icon(Icons.bar_chart_outlined),
                  //   selectedIcon: Icon(Icons.bar_chart),
                  //   label: Text('Reports'),
                  // ),
                ],
              ),
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppColors.lightGrey,
            ),
            // This is the main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _selectedIndex < _screens.length
                    ? _screens[_selectedIndex]
                    : _screens[0], // Fallback to first screen
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
          content:
              const Text('Are you sure you want to logout from your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
