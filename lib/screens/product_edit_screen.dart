import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ProductEditScreen extends StatefulWidget {
  final String productId;
  final String initialName;
  final String initialPrice;
  final String initialDesc;
  final String initialPicture;

  const ProductEditScreen({
    super.key,
    required this.productId,
    required this.initialName,
    required this.initialPrice,
    required this.initialDesc,
    required this.initialPicture,
  });

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _pictureController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _priceController = TextEditingController(text: widget.initialPrice);
    _descController = TextEditingController(text: widget.initialDesc);
    _pictureController = TextEditingController(text: widget.initialPicture);
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.put(
        Uri.parse('$baseUrl/products/${widget.productId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'displayName': _nameController.text,
          'price': double.parse(_priceController.text),
          'pictures': _pictureController.text,
          'description': _descController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['is_success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to exit without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Helper method to build labels closer to text fields
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0, left: 4.0), // Reduced bottom padding
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Product Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Enter product name'),
                        validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Price'),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(hintText: 'Enter price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Price cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Picture URL'),
                      TextFormField(
                        controller: _pictureController,
                        decoration: const InputDecoration(hintText: 'Enter picture URL'),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Description'),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(hintText: 'Enter description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: _isSaving
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _updateProduct,
                                child: const Text('Update Product'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
