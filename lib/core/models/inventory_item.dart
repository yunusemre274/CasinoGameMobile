// Inventory Item Model - For market and inventory system
class InventoryItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final int hungerRestore;
  final int quantity;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.hungerRestore,
    this.quantity = 1,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    String? icon,
    int? price,
    int? hungerRestore,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      hungerRestore: hungerRestore ?? this.hungerRestore,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'price': price,
    'hungerRestore': hungerRestore,
    'quantity': quantity,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: json['icon'] ?? '📦',
    price: json['price'] ?? 0,
    hungerRestore: json['hungerRestore'] ?? 0,
    quantity: json['quantity'] ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Predefined market items
class MarketItems {
  static const List<InventoryItem> all = [
    InventoryItem(
      id: 'banana',
      name: 'Banana',
      icon: '🍌',
      price: 15,
      hungerRestore: 10,
    ),
    InventoryItem(
      id: 'energy_drink',
      name: 'Energy Drink',
      icon: '⚡',
      price: 35,
      hungerRestore: 25,
    ),
    InventoryItem(
      id: 'bread',
      name: 'Bread',
      icon: '🍞',
      price: 20,
      hungerRestore: 15,
    ),
    InventoryItem(
      id: 'pizza_slice',
      name: 'Slice Pizza',
      icon: '🍕',
      price: 50,
      hungerRestore: 30,
    ),
    InventoryItem(
      id: 'burger_menu',
      name: 'Burger Menu',
      icon: '🍔',
      price: 80,
      hungerRestore: 50,
    ),
  ];

  static InventoryItem? getById(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
