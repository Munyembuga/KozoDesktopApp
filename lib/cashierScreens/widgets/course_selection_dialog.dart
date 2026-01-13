import 'package:flutter/material.dart';
import 'package:kozo/models/order_detail_model.dart';

class CourseSelectionDialog extends StatefulWidget {
  final OrderDetail orderDetail;
  final Function(String courseNumber, List<OrderItem> courseItems)
      onCourseSelected;

  const CourseSelectionDialog({
    Key? key,
    required this.orderDetail,
    required this.onCourseSelected,
  }) : super(key: key);

  @override
  State<CourseSelectionDialog> createState() => _CourseSelectionDialogState();
}

class _CourseSelectionDialogState extends State<CourseSelectionDialog> {
  Map<String, List<OrderItem>> _courseGroups = {};
  ScrollController _filtersScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _groupItemsByCourse();
    _filtersScrollController = ScrollController();
  }

  @override
  void dispose() {
    _filtersScrollController.dispose();
    super.dispose();
  }

  void _groupItemsByCourse() {
    _courseGroups.clear();

    for (var item in widget.orderDetail.items) {
      String courseNumber = item.courseNumber ?? 'cource 1';

      _courseGroups.putIfAbsent(courseNumber, () => []);
      _courseGroups[courseNumber]!.add(item);
    }
  }

  String _getCourseName(String courseNumber) {
    return courseNumber.replaceFirst('cource', 'Course');
  }

  @override
  Widget build(BuildContext context) {
    final sortedCourses = _courseGroups.keys.toList()..sort();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select Course to Print',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Course List
            Expanded(
              child: Scrollbar(
                controller: _filtersScrollController,
                thumbVisibility: true,
                thickness: 20.0,
                radius: const Radius.circular(10),
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _filtersScrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Courses:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (sortedCourses.isEmpty)
                        const Center(
                          child: Text(
                            'No courses available for printing.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedCourses.length,
                          itemBuilder: (context, index) {
                            final courseNumber = sortedCourses[index];
                            final courseItems = _courseGroups[courseNumber]!;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 20),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    widget.onCourseSelected(
                                        courseNumber, courseItems);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              courseNumber.replaceAll(
                                                  'cource ', ''),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getCourseName(courseNumber),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${courseItems.length} item${courseItems.length > 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                children: courseItems
                                                    .take(3)
                                                    .map((item) {
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8,
                                                            bottom: 4),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      '${item.quantity}x ${item.specificationName}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Colors.orange[800],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              if (courseItems.length > 3)
                                                Text(
                                                  '... and ${courseItems.length - 3} more',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.print,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
