class Store {
  const Store({
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

  Map<String, dynamic> toMap() => {
        'name':      name,
        'icon':      icon,
        'address':   address,
        'createdAt': createdAt.toIso8601String(),
      };

  static Store fromMap(int id, Map<String, dynamic> map) => Store(
        id:        id,
        name:      map['name'] as String,
        icon:      map['icon'] as String? ?? 'store',
        address:   map['address'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
