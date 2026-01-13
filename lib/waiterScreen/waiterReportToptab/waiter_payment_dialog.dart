import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WaiterPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(double amountReceived,
      List<Map<String, dynamic>> paymentMethods, String notes) onPayment;

  const WaiterPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPayment,
  });

  @override
  State<WaiterPaymentDialog> createState() => _WaiterPaymentDialogState();
}

class _WaiterPaymentDialogState extends State<WaiterPaymentDialog> {
  final List<PaymentMethod> _paymentMethods = [];
  final TextEditingController _notesController = TextEditingController();

  double get _totalPaid {
    return _paymentMethods.fold(0.0, (sum, method) => sum + method.amount);
  }

  double get _remainingAmount {
    return widget.totalAmount - _totalPaid;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:',
                          style: TextStyle(fontSize: 16)),
                      Text(
                        'RWF ${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  if (_paymentMethods.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid:',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          'RWF ${_totalPaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _remainingAmount > 0 ? 'Remaining:' : 'Change:',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'RWF ${_remainingAmount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _remainingAmount > 0
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addPaymentMethod,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Methods List
            Flexible(
              child: _paymentMethods.isEmpty
                  ? Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No payment methods added yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return _buildPaymentMethodCard(method, index);
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Payment Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Payment Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any notes about this payment...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_paymentMethods.isNotEmpty && _remainingAmount == 0)
                            ? _processPayment
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Record Payment',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getPaymentIcon(method.type), color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'RWF ${method.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'mobile money':
        return Icons.phone_android;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentMethodDialog(
        remainingAmount: _remainingAmount,
        onAdd: (method) {
          setState(() {
            _paymentMethods.add(method);
          });
        },
      ),
    );
  }

  void _processPayment() {
    if (_paymentMethods.isEmpty || _remainingAmount != 0) return;

    // Convert PaymentMethod objects to the required format
    final paymentMethodsData = _paymentMethods
        .map((method) => {
              'method': method.type.toLowerCase().replaceAll(' ', ''),
              'amount': method.amount.toString(),
              'reference': method.reference,
            })
        .toList();

    widget.onPayment(
      _totalPaid,
      paymentMethodsData,
      _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }
}

class _AddPaymentMethodDialog extends StatefulWidget {
  final double remainingAmount;
  final Function(PaymentMethod) onAdd;

  const _AddPaymentMethodDialog({
    required this.remainingAmount,
    required this.onAdd,
  });

  @override
  State<_AddPaymentMethodDialog> createState() =>
      _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  String _selectedType = 'cash';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  final List<String> _paymentTypes = [
    'cash',
    'card',
    'mobile_money',
    'bank_transfer'
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Payment Type',
              border: OutlineInputBorder(),
            ),
            items: _paymentTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixText: 'RWF ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference (Optional)',
              border: OutlineInputBorder(),
              hintText: 'Transaction reference, receipt number, etc.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addPayment,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentMethod = PaymentMethod(
      type: _selectedType,
      amount: amount,
      reference: _referenceController.text.trim(),
    );

    widget.onAdd(paymentMethod);
    Navigator.of(context).pop();
  }
}

class PaymentMethod {
  final String type;
  final double amount;
  final String reference;

  PaymentMethod({
    required this.type,
    required this.amount,
    this.reference = '',
  });

  @override
  String toString() {
    final ref = reference.isNotEmpty ? ' (Ref: $reference)' : '';
    return '$type: RWF ${amount.toStringAsFixed(2)}$ref';
  }
}
