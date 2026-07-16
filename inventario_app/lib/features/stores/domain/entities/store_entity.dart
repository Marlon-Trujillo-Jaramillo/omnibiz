class StoreEntity {
  const StoreEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.createdAt,
    this.address,
  });

  final int id;
  final String name;
  final String icon;
  final DateTime createdAt;
  final String? address;

  StoreEntity copyWith({
    int? id,
    String? name,
    String? icon,
    DateTime? createdAt,
    String? address,
  }) {
    return StoreEntity(
      id:        id        ?? this.id,
      name:      name      ?? this.name,
      icon:      icon      ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      address:   address   ?? this.address,
    );
  }
}
