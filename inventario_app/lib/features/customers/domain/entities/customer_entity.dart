class CustomerEntity {
  const CustomerEntity({
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
  /// Centavos (ver `Money`).
  final int totalDebt;
  final DateTime createdAt;
  final int storeId;
  final String? phone;
  final String? email;
  final DateTime? lastTransaction;

  bool get hasDebt => totalDebt > 0;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  CustomerEntity copyWith({
    int? id, String? name, int? totalDebt, DateTime? createdAt,
    int? storeId, String? phone, String? email, DateTime? lastTransaction,
  }) {
    return CustomerEntity(
      id:              id              ?? this.id,
      name:            name            ?? this.name,
      totalDebt:       totalDebt       ?? this.totalDebt,
      createdAt:       createdAt       ?? this.createdAt,
      storeId:         storeId         ?? this.storeId,
      phone:           phone           ?? this.phone,
      email:           email           ?? this.email,
      lastTransaction: lastTransaction ?? this.lastTransaction,
    );
  }
}
