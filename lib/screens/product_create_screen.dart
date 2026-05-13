import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ProductCreateScreen extends StatefulWidget {
  const ProductCreateScreen({super.key});

  @override
  State<ProductCreateScreen> createState() => _ProductCreateScreenState();
}

class _ProductCreateScreenState extends State<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _pictureController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _selectedStoreId;
  List<dynamic> _userStores = [];
  bool _isLoadingStores = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserStores();
  }

  Future<void> _fetchUserStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/stores'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userStores = data['stores'] ?? [];
          if (_userStores.isNotEmpty) {
            _selectedStoreId = _userStores.first['id'].toString();
          }
          _isLoadingStores = false;
        });
      } else {
        setState(() => _isLoadingStores = false);
      }
    } catch (e) {
      setState(() => _isLoadingStores = false);
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a store')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'storeId': int.parse(_selectedStoreId!),
          'displayName': _nameController.text,
          'price': double.parse(_priceController.text),
          'pictures': _pictureController.text,
          'description': _descController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['is_success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product created successfully')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to create product')),
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
    if (_nameController.text.isNotEmpty || _priceController.text.isNotEmpty) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to leave?'),
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
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Product')),
        body: _isLoadingStores
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedStoreId,
                          decoration: const InputDecoration(labelText: 'Select Store'),
                          items: _userStores.map((store) {
                            return DropdownMenuItem<String>(
                              value: store['id'].toString(),
                              child: Text(store['displayName']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStoreId = val;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a store' : null,
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Product Name'),
                          validator: (value) => value!.isEmpty ? 'Name is required' : null,
                        ),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Price is required' : null,
                        ),
                        TextFormField(
                          controller: _pictureController,
                          decoration: const InputDecoration(labelText: 'Picture URL'),
                          validator: (value) => value!.isEmpty ? 'Picture is required' : null,
                        ),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        _isSaving
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _createProduct,
                                child: const Text('Save Product'),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
