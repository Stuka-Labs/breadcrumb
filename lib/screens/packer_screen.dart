import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/packer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class PackerScreen extends StatefulWidget {
  const PackerScreen({super.key});

  @override
  State<PackerScreen> createState() => _PackerScreenState();
}

class _PackerScreenState extends State<PackerScreen> {
  String? selectedOrderId;
  Map<String, dynamic>? selectedOrderData;
  final TextEditingController _scannerController = TextEditingController();
  String? scannedBinLocation;
  Map<String, dynamic>? currentBinInfo;
  Map<String, dynamic>? currentItem;
  bool isLoadingOrder = false;
  bool isPacking = false;
  final FocusNode _scannerFocusNode = FocusNode();
  String _scannerBuffer = '';
  Timer? _scannerTimer;

  @override
  void initState() {
    super.initState();
    // Keep scanner field always focused
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scannerFocusNode.dispose();
    _scannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetails(String orderId) async {
    setState(() {
      isLoadingOrder = true;
      selectedOrderId = orderId;
      scannedBinLocation = null;
      currentBinInfo = null;
      currentItem = null;
      _scannerController.clear();
    });

    try {
      final orderData = await PackerService.getOrderDetails(orderId);
      if (orderData != null) {
        setState(() {
          selectedOrderData = orderData;
          isLoadingOrder = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e')),
        );
      }
    }
  }

  Future<void> _handleBinScan(String scannedValue) async {
    try {
      final binInfo = await PackerService.validateBinScan(scannedValue.trim());
      if (binInfo != null) {
        setState(() {
          scannedBinLocation = scannedValue.trim();
          currentBinInfo = binInfo;
          _scannerController.clear();
        });
        
        // Focus next item to scan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Bin ${binInfo['binName']} validated'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Bin not found. Please scan a valid bin location.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error validating bin: $e')),
        );
      }
    }
  }

  Future<void> _handleProductScan(String scannedSku) async {
    if (scannedBinLocation == null || currentBinInfo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please scan bin location first!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _scannerController.clear();
      return;
    }

    try {
      final productInfo = await PackerService.validateProductScan(scannedSku.trim());
      if (productInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Product not found. Please scan a valid SKU.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _scannerController.clear();
        return;
      }

      // Find matching item in order
      final items = selectedOrderData?['items'] as List<dynamic>? ?? [];
      Map<String, dynamic>? matchingItem;
      
      for (var item in items) {
        if (item['productId'] == productInfo['productId'] && 
            (item['status'] != 'packed' && item['status'] != 'fulfilled')) {
          // Verify bin matches
          if (productInfo['binId'] == currentBinInfo!['binId']) {
            matchingItem = Map<String, dynamic>.from(item);
            break;
          }
        }
      }

      if (matchingItem == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Product does not match this order or bin location.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _scannerController.clear();
        return;
      }

      // Show packing confirmation
      setState(() => currentItem = matchingItem);
      _showPackingConfirmation(productInfo, matchingItem);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error validating product: $e')),
        );
      }
    }
  }

  void _showPackingConfirmation(Map<String, dynamic> productInfo, Map<String, dynamic> item) {
    final quantityToPack = item['quantity'] as int? ?? 1;
    int quantityInput = quantityToPack;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirm Packing'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: ${productInfo['productName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('SKU: ${productInfo['sku']}'),
              Text('Bin: ${scannedBinLocation}'),
              Text('Order Quantity: $quantityToPack'),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Pack',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: quantityToPack.toString())
                  ..selection = TextSelection.collapsed(offset: quantityToPack.toString().length),
                onChanged: (value) {
                  setDialogState(() {
                    quantityInput = int.tryParse(value) ?? quantityToPack;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scannerController.clear();
                setState(() {
                  currentItem = null;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _packItem(item, quantityInput.clamp(1, quantityToPack));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Pack Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _packItem(Map<String, dynamic> item, int quantity) async {
    if (selectedOrderId == null || currentBinInfo == null) return;

    setState(() => isPacking = true);

    try {
      final packerId = PackerService.getCurrentPackerId();
      if (packerId == null) {
        throw Exception('Packer not authenticated');
      }

      await PackerService.packItem(
        orderId: selectedOrderId!,
        productId: item['productId'],
        itemId: item['id']?.toString() ?? item['productId'] ?? '',
        binId: currentBinInfo!['binId'] ?? '',
        quantityPacked: quantity,
        packerId: packerId,
      );

      // Refresh order data
      await _loadOrderDetails(selectedOrderId!);
      
      // Reset scanning state
      setState(() {
        scannedBinLocation = null;
        currentBinInfo = null;
        currentItem = null;
        isPacking = false;
      });

      _scannerController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Packed $quantity of ${item['productName'] ?? 'item'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => isPacking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error packing item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleScannerInput(String value) async {
    if (value.trim().isEmpty) return;

    // Reset scanner buffer
    _scannerBuffer = '';
    
    // If no bin scanned yet, treat as bin scan
    if (scannedBinLocation == null) {
      await _handleBinScan(value);
    } else {
      // Bin already scanned, treat as product scan
      await _handleProductScan(value);
    }
    
    // Re-focus scanner field after processing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scannerFocusNode.requestFocus();
      }
    });
  }

  // Handle keyboard input globally for barcode scanners
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      
      // Barcode scanners typically send Enter after the code
      if (key == LogicalKeyboardKey.enter) {
        _scannerTimer?.cancel();
        if (_scannerBuffer.isNotEmpty) {
          _handleScannerInput(_scannerBuffer);
        }
        _scannerBuffer = '';
        return;
      }
      
      // Ignore modifier keys
      if (key == LogicalKeyboardKey.shift || 
          key == LogicalKeyboardKey.control ||
          key == LogicalKeyboardKey.alt ||
          key == LogicalKeyboardKey.meta) {
        return;
      }
      
      // Build buffer from individual keystrokes
      if (event.character != null && event.character!.isNotEmpty) {
        _scannerBuffer += event.character!;
        
        // Reset buffer if no input for 200ms (normal typing delay)
        // Barcode scanners input very fast, so we'll process on Enter
        _scannerTimer?.cancel();
        _scannerTimer = Timer(const Duration(milliseconds: 500), () {
          // If buffer hasn't been processed (no Enter), it might be manual typing
          // Let the TextField handle it normally
          _scannerBuffer = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packer Workstation'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (selectedOrderId != null) {
                _loadOrderDetails(selectedOrderId!);
              }
              setState(() {
                scannedBinLocation = null;
                currentBinInfo = null;
                currentItem = null;
                _scannerController.clear();
              });
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            // Scanner Input Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            // Automatically re-request focus if lost
                            if (!hasFocus && mounted) {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  _scannerFocusNode.requestFocus();
                                }
                              });
                            }
                          },
                          child: TextField(
                            controller: _scannerController,
                            focusNode: _scannerFocusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: scannedBinLocation == null 
                                  ? 'Scan Bin Location (e.g., A-1-1-01)' 
                                  : 'Scan Product SKU',
                              hintText: 'Scan or type barcode',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.qr_code_scanner),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSubmitted: (value) {
                              _scannerController.text = '';
                              _handleScannerInput(value);
                            },
                            onChanged: (value) {
                              // Update buffer from TextField input
                              _scannerBuffer = value;
                            },
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (scannedBinLocation != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            scannedBinLocation = null;
                            currentBinInfo = null;
                            currentItem = null;
                            _scannerController.clear();
                          });
                        },
                        tooltip: 'Reset Bin Scan',
                      ),
                  ],
                ),
                if (scannedBinLocation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bin: $scannedBinLocation',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (currentBinInfo?['productName'] != null)
                          Text(
                            'Product: ${currentBinInfo!['productName']}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Order Selection and Items
          Expanded(
            child: Row(
              children: [
                // Order List Panel
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade100,
                        child: const Text(
                          'Orders Ready to Pack',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: PackerService.getOrdersReadyForPacking(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final orders = snapshot.data!.docs;
                            if (orders.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No orders ready for packing'),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index].data() as Map<String, dynamic>;
                                final orderId = orders[index].id;
                                final isSelected = selectedOrderId == orderId;
                                final customerName = order['customerName'] ?? 'Unknown';
                                final status = order['status'] ?? '';

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: Colors.blue.shade50,
                                  title: Text('Order #${orderId.substring(0, 8)}...'),
                                  subtitle: Text(customerName),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'ready_to_ship' ? Colors.orange : Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                  onTap: () => _loadOrderDetails(orderId),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Order Items Panel
                Expanded(
                  child: selectedOrderData == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Select an order to start packing',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : isLoadingOrder
                          ? const Center(child: CircularProgressIndicator())
                          : _buildOrderItemsView(),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsView() {
    final items = selectedOrderData?['items'] as List<dynamic>? ?? [];
    final packedCount = items.where((item) => 
        item['status'] == 'packed' || item['status'] == 'fulfilled').length;
    final totalCount = items.length;

    return Column(
      children: [
        // Order Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${selectedOrderId!.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$packedCount / $totalCount Packed',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: totalCount > 0 ? packedCount / totalCount : 0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isPacked = item['status'] == 'packed' || item['status'] == 'fulfilled';
              final productName = item['productName'] ?? 'Unknown Product';
              final sku = item['sku'] ?? '';
              final binLocation = item['binLocation'] ?? 'Not Located';
              final quantity = item['quantity'] ?? 0;
              final packedQty = item['packedQuantity'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isPacked ? 0 : 2,
                color: isPacked ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPacked ? Colors.green : Colors.blue,
                    child: Icon(
                      isPacked ? Icons.check : Icons.inventory_2,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isPacked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('SKU: $sku'),
                      Text(
                        'Bin Location: $binLocation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text('Quantity: $quantity ${isPacked ? '(Packed: $packedQty)' : ''}'),
                    ],
                  ),
                  trailing: isPacked
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
