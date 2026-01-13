import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'orders/order_tab_partialPayment.dart';
import 'orders/order_tab_delivery.dart';
import 'orders/order_tab_completed.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: const Text('Orders', style: AppTextStyles.heading),
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
            // OrderTabReady(),
            OrderTabDelivery(),
            OrderTabCompleted(),
            OrderTabPartialPayment(),
          ],
        ),
      ),
    );
  }
}
