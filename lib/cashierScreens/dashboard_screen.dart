import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:kozo/utils/constants.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

class CashierStats {
  final int totalTransactions;
  final double totalRevenue;
  final int completedOrders;
  final int pendingPaymentOrders;
  final List<RevenueByMethod> revenueByMethod;
  final String formattedTotalRevenue;

  CashierStats({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.completedOrders,
    required this.pendingPaymentOrders,
    required this.revenueByMethod,
    required this.formattedTotalRevenue,
  });

  factory CashierStats.fromJson(Map<String, dynamic> json) {
    return CashierStats(
      totalTransactions: json['total_transactions'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      completedOrders: json['completed_orders'] ?? 0,
      pendingPaymentOrders: json['pending_payment_orders'] ?? 0,
      revenueByMethod: (json['revenue_by_method'] as List<dynamic>?)
              ?.map((method) => RevenueByMethod.fromJson(method))
              .toList() ??
          [],
      formattedTotalRevenue: json['formatted_total_revenue'] ?? 'RWF 0',
    );
  }
}

class RevenueByMethod {
  final String method;
  final String methodType;
  final int transactionCount;
  final double totalAmount;
  final String formattedAmount;

  RevenueByMethod({
    required this.method,
    required this.methodType,
    required this.transactionCount,
    required this.totalAmount,
    required this.formattedAmount,
  });

  factory RevenueByMethod.fromJson(Map<String, dynamic> json) {
    return RevenueByMethod(
      method: json['method'] ?? '',
      methodType: json['method_type'] ?? '',
      transactionCount: json['transaction_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      formattedAmount: json['formatted_amount'] ?? 'RWF 0',
    );
  }
}

class DashboardStats {
  final int pendingOrders;
  final int servedOrders;
  final double pendingPaymentAmount;
  final int todayCompleted;
  final double todayRevenue;
  final int todayTotalOrders;
  final CashierStats? cashierStats;

  DashboardStats({
    required this.pendingOrders,
    required this.servedOrders,
    required this.pendingPaymentAmount,
    required this.todayCompleted,
    required this.todayRevenue,
    required this.todayTotalOrders,
    this.cashierStats,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      pendingOrders: json['pending_orders'] ?? 0,
      servedOrders: json['served_orders'] ?? 0,
      pendingPaymentAmount: (json['pending_payment_amount'] ?? 0).toDouble(),
      todayCompleted: json['today_completed'] ?? 0,
      todayRevenue: (json['today_revenue'] ?? 0).toDouble(),
      todayTotalOrders: json['today_total_orders'] ?? 0,
      cashierStats: json['cashier_stats'] != null
          ? CashierStats.fromJson(json['cashier_stats'])
          : null,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Dio _dio = Dio();
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  String _name = '';
  String _role = '';
  @override
  void initState() {
    super.initState();
    _fetchAuthName();
    _fetchDashboardStats();

    print("_name*******************: $_name");
  }

  void _fetchAuthName() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _name = user.fullName; // Assuming your User model has 'fullName'
        _role = user.role; // Assuming your User model has 'role'
      });
    }
    print("_name*******************: $_name");
  }

  Future<void> _fetchDashboardStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user to get cashier ID
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.get(
        '${AppConfig.baseUrl}/Orders/dashboard_stats',
        data: {
          'cashierId': currentUser.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('Dashboard data: $data');
        if (data['success'] == true) {
          setState(() {
            _stats = DashboardStats.fromJson(data['data']);
            _isLoading = false;
          });
        } else {
          throw Exception(
              'Failed to fetch dashboard stats: API returned success: false');
        }
      } else {
        throw Exception(
            'Failed to fetch dashboard stats: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStats() async {
    await _fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Kozo Dashboard v.1.1 $_role',
            style: const TextStyle(color: Colors.white)),
        actions: [
          Text(_name, style: const TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStats,
          ),
          // IconButton(
          //   icon: const Icon(Icons.notifications, color: Colors.white),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: const Icon(Icons.settings, color: Colors.white),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Scrollbar(
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(10),
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load dashboard',
                            style:
                                TextStyle(fontSize: 18, color: Colors.red[700]),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(_errorMessage!,
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshStats,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true, // Always shows the draggable thumb
                  thickness: 20.0, // Very thick (20px) for excellent visibility
                  radius: const Radius.circular(
                      10), // Rounded corners for modern look
                  trackVisibility: true, // Shows the background track
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metrics Cards
                        Row(
                          children: [
                            Expanded(
                                child: _buildMetricCard(
                                    'Today\'s Revenue',
                                    'RWF ${_stats!.todayRevenue.toStringAsFixed(0)}',
                                    Icons.attach_money,
                                    Colors.purple)),
                            // Expanded(
                            //     child: _buildMetricCard(
                            //         'Pending Orders',
                            //         '${_stats!.pendingOrders}',
                            //         Icons.pending_actions,
                            //         Colors.orange)),
                            // const SizedBox(width: 16),
                            Expanded(
                                child: _buildMetricCard(
                                    'Served Orders',
                                    '${_stats!.servedOrders}',
                                    Icons.check_circle,
                                    Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildMetricCard(
                                    'Pending Payments',
                                    'RWF ${_stats!.pendingPaymentAmount.toStringAsFixed(0)}',
                                    Icons.payment,
                                    Colors.red)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildMetricCard(
                                    'Completed Today',
                                    '${_stats!.todayCompleted}',
                                    Icons.done_all,
                                    Colors.teal)),
                            // Expanded(
                            //     child: _buildMetricCard(
                            //         'Today\'s Orders',
                            //         '${_stats!.todayTotalOrders}',
                            //         Icons.today,
                            //         Colors.blue)),
                            // const SizedBox(width: 16),
                          ],
                        ),
                        // const SizedBox(height: 16),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //         child: _buildMetricCard(
                        //             'Today\'s Revenue',
                        //             'RWF ${_stats!.todayRevenue.toStringAsFixed(0)}',
                        //             Icons.attach_money,
                        //             Colors.purple)),
                        //   ],
                        // ),

                        const SizedBox(height: 24),

                        // Cashier Statistics
                        if (_stats!.cashierStats != null) ...[
                          const SizedBox(height: 24),
                          _buildCashierStats(_stats!.cashierStats!),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCashierStats(CashierStats cashierStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Cashier Statistics', style: AppTextStyles.heading),
            ],
          ),
          const SizedBox(height: 16),

          // Cashier metrics
          Row(
            children: [
              Expanded(
                child: _buildCashierMetricCard(
                  'Total Transactions',
                  '${cashierStats.totalTransactions}',
                  Icons.receipt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCashierMetricCard(
                  'Total Revenue',
                  cashierStats.formattedTotalRevenue,
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment methods breakdown
          if (cashierStats.revenueByMethod.isNotEmpty) ...[
            const Text(
              'Revenue by Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...cashierStats.revenueByMethod
                .map((method) => _buildPaymentMethodRow(method)),
          ],
        ],
      ),
    );
  }

  Widget _buildCashierMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(RevenueByMethod method) {
    IconData methodIcon;
    Color methodColor;

    switch (method.methodType.toLowerCase()) {
      case 'cash':
        methodIcon = Icons.money;
        methodColor = Colors.green;
        break;
      case 'mobile_money':
      case 'mobile':
        methodIcon = Icons.phone_android;
        methodColor = Colors.blue;
        break;
      case 'card':
        methodIcon = Icons.credit_card;
        methodColor = Colors.purple;
        break;
      default:
        methodIcon = Icons.payment;
        methodColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: methodColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: methodColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(methodIcon, color: methodColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.method,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${method.transactionCount} transactions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            method.formattedAmount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: methodColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
