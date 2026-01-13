class TableModel {
  final int id;
  final String tableNumber;
  final String tableName;
  final int seatingCapacity;
  final String tableType;
  final String location;
  final String status;
  final String description;
  final String createdAt;
  final String updatedAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.tableName,
    required this.seatingCapacity,
    required this.tableType,
    required this.location,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tableNumber: json['table_number'],
      tableName: json['table_name'],
      seatingCapacity: json['seating_capacity'],
      tableType: json['table_type'],
      location: json['location'],
      status: json['status'],
      description: json['description'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_number': tableNumber,
      'table_name': tableName,
      'seating_capacity': seatingCapacity,
      'table_type': tableType,
      'location': location,
      'status': status,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
