import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class OrderTabReady extends StatelessWidget {
  const OrderTabReady({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _readyOrders.length,
      itemBuilder: (context, index) {
        final order = _readyOrders[index];
        return _buildOrderCard(order, context);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order['table'],
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Ready ${order['readyTime']}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Order Details
          Text(
            'Order #${order['orderNumber']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          ...order['items']
              .map<Widget>((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item['quantity']}x ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (item['temperature'] != null) ...[
                          Icon(
                            item['temperature'] == 'hot'
                                ? Icons.whatshot
                                : Icons.ac_unit,
                            size: 16,
                            color: item['temperature'] == 'hot'
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '\$${item['price']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),

          if (order['customerName'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Customer: ${order['customerName']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Total and Actions
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: \$${order['total']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Prepared at ${order['preparedTime']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _serveOrder(order['orderNumber']),
                icon: const Icon(Icons.room_service, size: 16),
                label: const Text('Serve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _serveOrder(String orderNumber) {
    // TODO: Implement serve order logic
    print('Serving order $orderNumber');
  }

  // Sample ready orders data
  static const List<Map<String, dynamic>> _readyOrders = [
    {
      'orderNumber': '004',
      'table': 'Table 3',
      'readyTime': '2 min ago',
      'preparedTime': '14:25',
      'total': '32.50',
      'customerName': 'John Smith',
      'items': [
        {
          'name': 'Grilled Salmon',
          'quantity': 1,
          'price': '24.50',
          'temperature': 'hot'
        },
        {
          'name': 'Iced Tea',
          'quantity': 2,
          'price': '8.00',
          'temperature': 'cold'
        },
      ],
    },
    {
      'orderNumber': '005',
      'table': 'Table 7',
      'readyTime': '5 min ago',
      'preparedTime': '14:22',
      'total': '18.90',
      'customerName': 'Sarah Johnson',
      'items': [
        {
          'name': 'Chicken Burger',
          'quantity': 1,
          'price': '15.90',
          'temperature': 'hot'
        },
        {
          'name': 'Coffee',
          'quantity': 1,
          'price': '3.00',
          'temperature': 'hot'
        },
      ],
    },
    {
      'orderNumber': '006',
      'table': 'Bar Counter',
      'readyTime': '1 min ago',
      'preparedTime': '14:26',
      'total': '45.00',
      'customerName': 'Mike Wilson',
      'items': [
        {
          'name': 'Fish & Chips',
          'quantity': 1,
          'price': '19.50',
          'temperature': 'hot'
        },
        {
          'name': 'Beer',
          'quantity': 3,
          'price': '25.50',
          'temperature': 'cold'
        },
      ],
    },
  ];
}
