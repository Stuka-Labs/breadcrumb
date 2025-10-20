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
    });
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
    final batch = FirebaseFirestore.instance.batch();
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
              });
            }
          }
        }
      }
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locations saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouse Blueprint')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DimensionControl(label: 'Zones', value: zoneCount, onChanged: (v) => _resize(zones: v)),
                const SizedBox(width: 8),
                _DimensionControl(label: 'Aisles', value: aisleCount, onChanged: (v) => _resize(aisles: v)),
                const SizedBox(width: 8),
                _DimensionControl(label: 'Shelves', value: shelfCount, onChanged: (v) => _resize(shelves: v)),
                const SizedBox(width: 8),
                _DimensionControl(label: 'Bins', value: binCount, onChanged: (v) => _resize(bins: v)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: zoneCount,
              itemBuilder: (context, z) => ExpansionTile(
                title: Text('Zone ${z + 1}'),
                children: [
                  ...List.generate(aisleCount, (a) => ExpansionTile(
                    title: Text('Aisle ${a + 1}'),
                    children: [
                      ...List.generate(shelfCount, (s) => Row(
                        children: [
                          Text('Shelf ${s + 1}:'),
                          ...List.generate(binCount, (b) {
                            final cell = blueprint[z][a][s][b];
                            return GestureDetector(
                              onTap: () => _editCell(cell),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cell.isFilled ? Colors.orange[200] : Colors.grey[200],
                                  border: Border.all(color: Colors.black12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  children: [
                                    Text('Bin ${b + 1}'),
                                    if (cell.isFilled) ...[
                                      Text('Cap: ${cell.capacity}'),
                                      Text('Stock: ${cell.currentStock}'),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      )),
                    ],
                  )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _saveAll,
                  child: const Text('Save All'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionControl extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _DimensionControl({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(value + 1),
        ),
      ],
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
  @override
  void initState() {
    super.initState();
    capacity = widget.cell.capacity;
    currentStock = widget.cell.currentStock;
    status = widget.cell.status;
    isFilled = widget.cell.isFilled;
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
            onChanged: (v) => setState(() => isFilled = v),
          ),
          if (isFilled) ...[
            TextFormField(
              initialValue: capacity.toString(),
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
              onChanged: (v) => capacity = int.tryParse(v) ?? 0,
            ),
            TextFormField(
              initialValue: currentStock.toString(),
              decoration: const InputDecoration(labelText: 'Current Stock'),
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