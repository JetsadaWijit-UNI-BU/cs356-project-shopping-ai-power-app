import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/product.dart';
import 'store_edit_screen.dart';

class StoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestProducts();
  }

  Future<void> _fetchLatestProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/stores/${widget.storeId}/products?page=1'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productList = data['products'] ?? [];
        
        setState(() {
          _products = productList.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreEditScreen(storeId: widget.storeId, currentName: widget.storeName),
                ),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      child: ListTile(
                        title: Text(product.displayName),
                        subtitle: Text('Price: \$${product.price}'),
                      ),
                    );
                  },
                ),
    );
  }
}
