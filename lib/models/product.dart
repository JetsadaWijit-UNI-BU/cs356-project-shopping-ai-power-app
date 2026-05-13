class Product {
  final int id;
  final String displayName;
  final double price;
  final String description;
  final String pictures;

  Product({
    required this.id,
    required this.displayName,
    required this.price,
    required this.description,
    required this.pictures,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      displayName: json['displayName'] ?? 'Unknown Product',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      pictures: json['pictures'] ?? '',
    );
  }
}
