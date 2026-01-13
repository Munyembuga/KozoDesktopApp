import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/cart_item_model.dart';
import '../../models/category_model.dart';

class PressureSelectionDialog extends StatefulWidget {
  final CartItem cartItem;
  final List<PressureCooking> pressureOptions;
  final Function(int?) onSavePressure;

  const PressureSelectionDialog({
    Key? key,
    required this.cartItem,
    required this.pressureOptions,
    required this.onSavePressure,
  }) : super(key: key);

  @override
  State<PressureSelectionDialog> createState() =>
      _PressureSelectionDialogState();
}

class _PressureSelectionDialogState extends State<PressureSelectionDialog> {
  int? _selectedPressureId;

  @override
  void initState() {
    super.initState();
    _selectedPressureId = widget.cartItem.selectedPressureId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: Colors.orange[700], size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Temperature Cooking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.cartItem.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Temperatureoptions
            Text(
              'Available Temperature Options',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // Options list
            Container(
              constraints: BoxConstraints(
                maxHeight: 300,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.pressureOptions.length,
                itemBuilder: (context, index) {
                  final pressure = widget.pressureOptions[index];
                  final isSelected = _selectedPressureId == pressure.pressureId;

                  return Card(
                    elevation: isSelected ? 4 : 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.orange[700]!
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPressureId = pressure.pressureId;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Radio indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orange[700]!
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? Colors.orange[700]
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Pressure details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPressureLevelColor(
                                                  pressure.pressureLevel)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          pressure.pressureLevel.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getPressureLevelColor(
                                                pressure.pressureLevel),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Temperature Level',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Clear selection button
                if (_selectedPressureId != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedPressureId = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onSavePressure(_selectedPressureId);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

Color _getPressureLevelColor(String level) {
  final value = level.toLowerCase();

  if (value.contains('low')) {
    return Colors.green[600]!;
  } else if (value.contains('medium')) {
    return Colors.orange[600]!;
  } else if (value.contains('high')) {
    return Colors.red[600]!;
  } else {
    return Colors.grey[600]!;
  }
}

}
