import 'package:flutter/material.dart';
import 'package:kozo/waiterScreen/waiter_order/waiter_order_tab_completed.dart';
import 'package:kozo/waiterScreen/waiter_order/waiter_order_tab_delivery.dart';
import 'package:kozo/waiterScreen/waiter_order/waiter_order_tab_partialPayment.dart';
import '../constants/app_constants.dart';

class WaiterorderScreen extends StatelessWidget {
  const WaiterorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: const Text('Order', style: AppTextStyles.heading),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              // Tab(text: 'Ready'),
              Tab(text: 'Delivery'),
              Tab(text: 'Completed'),
              Tab(text: 'Partial  Payment'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // WaiterOrderTabReady(),
            WaiterOrderTabDelivery(),
            WaiterOrderTabCompleted(),
            waiterOrderTabPartialPayment(),
          ],
        ),
      ),
    );
  }
}
