import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'reportToptab/summary_stats_report.dart';
import 'reportToptab/completed_order_report.dart';
import 'reportToptab/partial_paid_order_report.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

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
              Tab(text: 'Partial Paid Orders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SummaryStatsReport(),
            CompletedOrderReport(),
            PartialPaidOrderReport(),
          ],
        ),
      ),
    );
  }
}
