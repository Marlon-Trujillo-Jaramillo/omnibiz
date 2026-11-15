class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.totalDebt,
    required this.createdAt,
    required this.storeId,
    this.phone,
    this.email,
    this.lastTransaction,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;

  /// Centavos.
  final int totalDebt;
  final DateTime createdAt;
  final DateTime? lastTransaction;
  final int storeId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'totalDebt': totalDebt,
    'createdAt': createdAt.toIso8601String(),
    'lastTransaction': lastTransaction?.toIso8601String(),
    'storeId': storeId,
  };

  static Customer fromMap(int id, Map<String, dynamic> map) => Customer(
    id: id,
    name: map['name'] as String,
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    totalDebt: map['totalDebt'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
    lastTransaction: map['lastTransaction'] != null
        ? DateTime.parse(map['lastTransaction'] as String)
        : null,
    storeId: map['storeId'] as int? ?? 0,
  );
}
