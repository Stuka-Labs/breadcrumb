import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseLocationsScreen extends StatefulWidget {
  const WarehouseLocationsScreen({super.key});

  @override
  State<WarehouseLocationsScreen> createState() => _WarehouseLocationsScreenState();
}

class _WarehouseLocationsScreenState extends State<WarehouseLocationsScreen> {
  int zoneCount = 2;
  int aisleCount = 2;
  int shelfCount = 2;
  int binCount = 2;
  bool isLoading = false;
  bool hasUnsavedChanges = false;

  // Structure: [zone][aisle][shelf][bin]
  late List<List<List<List<LocationCell>>>> blueprint;

  @override
  void initState() {
    super.initState();
    _initBlueprint();
  }

  void _initBlueprint() {
    blueprint = List.generate(zoneCount, (z) =>
      List.generate(aisleCount, (a) =>
        List.generate(shelfCount, (s) =>
          List.generate(binCount, (b) => LocationCell(zone: z, aisle: a, shelf: s, bin: b)),
        ),
      ),
    );
  }

  void _resize({int? zones, int? aisles, int? shelves, int? bins}) {
    setState(() {
      zoneCount = zones ?? zoneCount;
      aisleCount = aisles ?? aisleCount;
      shelfCount = shelves ?? shelfCount;
      binCount = bins ?? binCount;
      _initBlueprint();
      hasUnsavedChanges = true;
    });
  }

  Future<void> _loadExistingBlueprint() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('locations').get();
      if (snapshot.docs.isNotEmpty) {
        // Load existing blueprint structure
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Existing blueprint loaded!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No existing blueprint found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading blueprint: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _resetBlueprint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Blueprint'),
        content: const Text('Are you sure you want to reset the entire warehouse blueprint? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                zoneCount = 2;
                aisleCount = 2;
                shelfCount = 2;
                binCount = 2;
                _initBlueprint();
                hasUnsavedChanges = false;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _editCell(LocationCell cell) async {
    final result = await showDialog<LocationCell>(
      context: context,
      builder: (context) => EditLocationDialog(cell: cell),
    );
    if (result != null) {
      setState(() {
        blueprint[result.zone][result.aisle][result.shelf][result.bin] = result;
      });
    }
  }

  Future<void> _saveAll() async {
    setState(() => isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Clear existing locations first
      final existingLocations = await FirebaseFirestore.instance.collection('locations').get();
      for (var doc in existingLocations.docs) {
        batch.delete(doc.reference);
      }
      
      // Save new blueprint
      for (var zone in blueprint) {
        for (var aisle in zone) {
          for (var shelf in aisle) {
            for (var cell in shelf) {
              if (cell.isFilled) {
                final ref = FirebaseFirestore.instance.collection('locations').doc();
                batch.set(ref, {
                  ...cell.toMap(),
                  'binId': ref.id,
                  'productId': null, // Will be set when a product is assigned
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }
          }
        }
      }
      
      await batch.commit();
      setState(() => hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Warehouse blueprint saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving blueprint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Blueprint'),
        actions: [
          if (hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAll,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick Setup Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Setup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DimensionCard(
                        title: 'Zones',
                        value: zoneCount,
                        icon: Icons.location_city,
                        color: Colors.red,
                        onChanged: (v) => _resize(zones: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DimensionCard(
                        title: 'Aisles',
                        value: aisleCount,
                        icon: Icons.straighten,
                        color: Colors.orange,
                        onChanged: (v) => _resize(aisles: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DimensionCard(
                        title: 'Shelves',
                        value: shelfCount,
                        icon: Icons.view_module,
                        color: Colors.green,
                        onChanged: (v) => _resize(shelves: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DimensionCard(
                        title: 'Bins',
                        value: binCount,
                        icon: Icons.inventory_2,
                        color: Colors.purple,
                        onChanged: (v) => _resize(bins: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Blueprint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _loadExistingBlueprint,
                      icon: const Icon(Icons.upload),
                      label: const Text('Load Existing'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _resetBlueprint,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Warehouse Visualization
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWarehouseVisualization(),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseVisualization() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warehouse Layout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(zoneCount, (z) => _buildZoneCard(z)),
        ],
      ),
    );
  }

  Widget _buildZoneCard(int zoneIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Text('${zoneIndex + 1}', style: TextStyle(color: Colors.red.shade700)),
        ),
        title: Text(
          'Zone ${zoneIndex + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${aisleCount} aisles • ${shelfCount * aisleCount} shelves • ${binCount * shelfCount * aisleCount} bins'),
        children: [
          ...List.generate(aisleCount, (a) => _buildAisleCard(zoneIndex, a)),
        ],
      ),
    );
  }

  Widget _buildAisleCard(int zoneIndex, int aisleIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 1,
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            child: Text('${aisleIndex + 1}', style: TextStyle(color: Colors.orange.shade700)),
          ),
          title: Text(
            'Aisle ${aisleIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${shelfCount} shelves • ${binCount * shelfCount} bins'),
          children: [
            ...List.generate(shelfCount, (s) => _buildShelfRow(zoneIndex, aisleIndex, s)),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfRow(int zoneIndex, int aisleIndex, int shelfIndex) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shelf ${shelfIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(binCount, (b) {
              final cell = blueprint[zoneIndex][aisleIndex][shelfIndex][b];
              return _buildBinCard(cell);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBinCard(LocationCell cell) {
    final isActive = cell.isFilled && cell.status == 'active';
    
    return GestureDetector(
      onTap: () => _editCell(cell),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
          border: Border.all(
            color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'B${cell.bin + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(
                '${cell.currentStock}/${cell.capacity}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final ValueChanged<int> onChanged;
  
  const _DimensionCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: value > 1 ? () => onChanged(value - 1) : null,
                  color: value > 1 ? color : Colors.grey,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onChanged(value + 1),
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LocationCell {
  final int zone, aisle, shelf, bin;
  int capacity;
  int currentStock;
  String status;
  bool isFilled;
  LocationCell({
    required this.zone,
    required this.aisle,
    required this.shelf,
    required this.bin,
    this.capacity = 0,
    this.currentStock = 0,
    this.status = 'active',
    this.isFilled = false,
  });
  Map<String, dynamic> toMap() => {
    'zone': zone + 1,
    'aisle': aisle + 1,
    'shelf': shelf + 1,
    'bin': bin + 1,
    'capacity': capacity,
    'currentStock': currentStock,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  LocationCell copyWith({int? capacity, int? currentStock, String? status, bool? isFilled}) => LocationCell(
    zone: zone,
    aisle: aisle,
    shelf: shelf,
    bin: bin,
    capacity: capacity ?? this.capacity,
    currentStock: currentStock ?? this.currentStock,
    status: status ?? this.status,
    isFilled: isFilled ?? this.isFilled,
  );
}

class EditLocationDialog extends StatefulWidget {
  final LocationCell cell;
  const EditLocationDialog({required this.cell, super.key});
  @override
  State<EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends State<EditLocationDialog> {
  late int capacity;
  late int currentStock;
  late String status;
  late bool isFilled;
  late TextEditingController _capacityController;
  late TextEditingController _stockController;
  
  @override
  void initState() {
    super.initState();
    capacity = widget.cell.capacity;
    currentStock = widget.cell.currentStock;
    status = widget.cell.status;
    isFilled = widget.cell.isFilled;
    _capacityController = TextEditingController(text: capacity.toString());
    _stockController = TextEditingController(text: currentStock.toString());
  }
  
  @override
  void dispose() {
    _capacityController.dispose();
    _stockController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Bin (Z${widget.cell.zone + 1}-A${widget.cell.aisle + 1}-S${widget.cell.shelf + 1}-B${widget.cell.bin + 1})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Enable Bin'),
            value: isFilled,
            onChanged: (v) => setState(() {
              isFilled = v;
              // Set default capacity when enabling bin
              if (v && capacity == 0) {
                capacity = 100;
                _capacityController.text = capacity.toString();
              }
            }),
          ),
          if (isFilled) ...[
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                hintText: 'Maximum items this bin can hold',
                helperText: 'Default: 100 items',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => capacity = int.tryParse(v) ?? 0,
            ),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Current Stock',
                hintText: 'Number of items currently in this bin',
                helperText: 'Start with 0 for empty bins',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => currentStock = int.tryParse(v) ?? 0,
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => status = v ?? 'active'),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, widget.cell.copyWith(
              capacity: capacity,
              currentStock: currentStock,
              status: status,
              isFilled: isFilled,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 