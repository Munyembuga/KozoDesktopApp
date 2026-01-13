import 'package:flutter/material.dart';
import 'package:kozo/waiterScreen/waiterReportToptab/waiter_Completed_order_report.dart';
import 'package:kozo/waiterScreen/waiterReportToptab/waiter_summary_stats_report.dart';
// import 'package:kozo/waiterScreen/waiterReportToptab/waiter_deliveryed_order_report.dart';
import '../constants/app_constants.dart';

class WaiterReportingScreen extends StatelessWidget {
  const WaiterReportingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: const Text('Reports', style: AppTextStyles.heading),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Summary Stats'),
              Tab(text: 'Completed Orders'),
              // Tab(text: 'Delivered Orders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WaiterSummaryStatsReport(),
            WaiterCompletedOrderReport(),
            // WaiterDeliveredOrderReport(),
          ],
        ),
      ),
    );
  }
}
