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
    // Safely parse price which might come as int or double from the backend
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = json['price'] is int 
          ? (json['price'] as int).toDouble() 
          : json['price'] as double;
    }

    return Product(
      id: json['id'] ?? 0,
      // Handle both camelCase and snake_case to match backend response
      displayName: json['display_name'] ?? json['displayName'] ?? 'Unknown Product',
      price: parsedPrice,
      description: json['description'] ?? '',
      pictures: json['pictures'] ?? '',
    );
  }
}
