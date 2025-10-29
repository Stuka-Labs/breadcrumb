import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/material_service.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({super.key});

  @override
  State<MaterialManagementScreen> createState() => _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen> {
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedMaterialId;

  @override
  void initState() {
    super.initState();
    // Initialize default materials if none exist
    MaterialService.initializeDefaultMaterials();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMaterialDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Material Stock Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update material quantities and set minimum stock levels. The system will automatically calculate required materials based on product dimensions.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Material list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('materials')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No materials found. Tap + to add materials.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final quantity = data['quantity'] as int;
                    final minQuantity = data['minQuantity'] as int;
                    final isLowStock = quantity <= minQuantity;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLowStock ? Colors.red.shade50 : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMaterialIcon(data['type']),
                            color: isLowStock ? Colors.red : Colors.teal,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          data['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLowStock ? Colors.red.shade800 : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${data['type']}'),
                            Text('Cost: \$${data['cost']?.toStringAsFixed(2) ?? '0.00'}'),
                            if (isLowStock)
                              Text(
                                '⚠️ Low Stock Alert!',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Qty: $quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? Colors.red : Colors.teal,
                              ),
                            ),
                            Text(
                              'Min: $minQuantity',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showEditQuantityDialog(doc.id, data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Quick actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLowStockAlerts,
                    icon: const Icon(Icons.warning),
                    label: const Text('Low Stock Alerts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showMaterialCalculator,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Material Calculator'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMaterialIcon(String type) {
    switch (type) {
      case 'small_box':
      case 'medium_box':
      case 'large_box':
        return Icons.inventory_2;
      case 'packing_tape':
        return Icons.straighten;
      case 'bubble_wrap':
        return Icons.layers;
      case 'shipping_labels':
        return Icons.label;
      default:
        return Icons.storage;
    }
  }

  void _showEditQuantityDialog(String materialId, Map<String, dynamic> data) {
    _quantityController.text = data['quantity'].toString();
    _selectedMaterialId = materialId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${data['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: data['minQuantity'].toString()),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Quantity',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Update min quantity logic here
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _updateMaterialQuantity,
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateMaterialQuantity() async {
    if (_selectedMaterialId == null || _quantityController.text.isEmpty) return;
    
    try {
      final newQuantity = int.parse(_quantityController.text);
      await MaterialService.updateMaterialQuantity(_selectedMaterialId!, newQuantity);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material quantity updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMaterialDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final minQuantityController = TextEditingController();
    final costController = TextEditingController();
    String selectedType = 'small_box';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Material Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Material Type',
                    border: OutlineInputBorder(),
                  ),
                  items: MaterialService.materialTypes.keys.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(MaterialService.materialTypes[type]!['name']),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Initial Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cost per Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await MaterialService.addMaterial(
                    name: nameController.text,
                    type: selectedType,
                    quantity: int.parse(quantityController.text),
                    minQuantity: int.parse(minQuantityController.text),
                    cost: double.parse(costController.text),
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Material added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding material: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLowStockAlerts() async {
    try {
      final alerts = await MaterialService.getLowStockAlerts();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Low Stock Alerts'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: alerts.isEmpty
                  ? const Center(child: Text('No low stock alerts'))
                  : ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return ListTile(
                          leading: Icon(
                            Icons.warning,
                            color: alert['status'] == 'out_of_stock' 
                                ? Colors.red 
                                : Colors.orange,
                          ),
                          title: Text(alert['name']),
                          subtitle: Text('Current: ${alert['quantity']}, Min: ${alert['minQuantity']}'),
                          trailing: Text(
                            alert['status'] == 'out_of_stock' ? 'OUT OF STOCK' : 'LOW STOCK',
                            style: TextStyle(
                              color: alert['status'] == 'out_of_stock' 
                                  ? Colors.red 
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading alerts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMaterialCalculator() {
    final lengthController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    final quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Material Calculator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter product dimensions to calculate required materials:'),
            const SizedBox(height: 16),
            TextField(
              controller: lengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Length (inches)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Width (inches)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (inches)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final length = double.parse(lengthController.text);
                final width = double.parse(widthController.text);
                final height = double.parse(heightController.text);
                final quantity = int.parse(quantityController.text);
                
                final materials = MaterialService.calculateMaterialsRequired(
                  productLength: length,
                  productWidth: width,
                  productHeight: height,
                  quantity: quantity,
                );
                
                final cost = MaterialService.calculateOrderMaterialCost(materials);
                
                Navigator.pop(context);
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Required Materials'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Materials needed for $quantity items:'),
                        const SizedBox(height: 8),
                        ...materials.entries.map((entry) => Text(
                          '• ${MaterialService.materialTypes[entry.key]?['name'] ?? entry.key}: ${entry.value}',
                        )),
                        const SizedBox(height: 8),
                        Text(
                          'Total Material Cost: \$${cost.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error calculating materials: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }
}
