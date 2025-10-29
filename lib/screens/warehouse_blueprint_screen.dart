import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class WarehouseBlueprintScreen extends StatefulWidget {
  const WarehouseBlueprintScreen({super.key});

  @override
  State<WarehouseBlueprintScreen> createState() => _WarehouseBlueprintScreenState();
}

class _WarehouseBlueprintScreenState extends State<WarehouseBlueprintScreen> {
  List<WarehouseRow> rows = [];
  bool isEditMode = false;
  String? selectedBinId;
  String? selectedBayId; // Track selected bay for adding bins
  bool addToAllBays = false; // Bulk add mode: true = all bays, false = selected bay
  int bulkBinCount = 1; // Number of bins to add in bulk
  final TextEditingController _binCountController = TextEditingController(text: '1');
  Offset? dragStartPosition;
  String? draggedBinId;
  double gridSpacing = 20.0; // Spacing between grid lines

  @override
  void initState() {
    super.initState();
    _loadWarehouseBlueprint();
  }

  Future<void> _loadWarehouseBlueprint() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('warehouse_blueprint')
          .orderBy('rowLetter')
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          rows = snapshot.docs.map((doc) => WarehouseRow.fromMap(doc.data())).toList();
          // Initialize selected bay to first available bay
          if (rows.isNotEmpty) {
            final allBays = _getAllBays();
            if (allBays.isNotEmpty && selectedBayId == null) {
              selectedBayId = allBays.first.id;
            }
          }
        });
      } else {
        _createDefaultWarehouse();
        // Initialize selected bay after creating default
        if (rows.isNotEmpty) {
          final allBays = _getAllBays();
          if (allBays.isNotEmpty) {
            selectedBayId = allBays.first.id;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading warehouse blueprint: $e');
      _createDefaultWarehouse();
    }
  }

  void _createDefaultWarehouse() {
    setState(() {
      rows = [
        WarehouseRow(
          id: 'row_a',
          rowLetter: 'A',
          position: const Offset(0, 0),
          levels: [
            WarehouseLevel(
              id: 'a_level_1',
              levelNumber: 1,
              position: const Offset(0, 0),
              bays: [
                WarehouseBay(
                  id: 'a_1_1', 
                  bayNumber: 1, 
                  position: const Offset(0, 0),
                  bins: _createDefaultBins('A', 1, 1),
                ),
              ],
            ),
          ],
        ),
      ];
    });
  }

  List<WarehouseBin> _createDefaultBins(String rowLetter, int level, int bay) {
    return List.generate(1, (index) {
      final binNumber = (index + 1).toString().padLeft(2, '0');
      return WarehouseBin(
        id: '${rowLetter.toLowerCase()}_${level}_${bay}_${binNumber}',
        binNumber: binNumber,
        binName: '$rowLetter-$level-$bay-$binNumber',
        isOccupied: false,
        productId: null,
        productName: null,
        widthInches: 18.0,  // Default width
        heightInches: 11.0, // Default height  
        depthInches: 7.0,   // Default depth
        position: Offset(index * 200, 0), // Fixed spacing
      );
    });
  }

  Future<void> _saveWarehouseBlueprint() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Clear existing blueprint
      final existingSnapshot = await FirebaseFirestore.instance
          .collection('warehouse_blueprint')
          .get();
      
      for (final doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Save new blueprint
      for (final row in rows) {
        final docRef = FirebaseFirestore.instance
            .collection('warehouse_blueprint')
            .doc(row.id);
        batch.set(docRef, row.toMap());
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warehouse blueprint saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving blueprint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addRow() {
    final newRowLetter = String.fromCharCode(65 + rows.length);
    final newRow = WarehouseRow(
      id: 'row_${newRowLetter.toLowerCase()}',
      rowLetter: newRowLetter,
      position: const Offset(0, 0),
      levels: [
        WarehouseLevel(
          id: '${newRowLetter.toLowerCase()}_level_1',
          levelNumber: 1,
          position: const Offset(0, 0),
          bays: [
            WarehouseBay(
              id: '${newRowLetter.toLowerCase()}_1_1', 
              bayNumber: 1, 
              position: const Offset(0, 0),
              bins: _createDefaultBins(newRowLetter, 1, 1),
            ),
          ],
        ),
      ],
    );
    
    setState(() {
      rows.add(newRow);
    });
  }

  void _addLevel(WarehouseRow row) {
    final newLevelNumber = row.levels.length + 1;
    final newLevel = WarehouseLevel(
      id: '${row.rowLetter.toLowerCase()}_level_$newLevelNumber',
      levelNumber: newLevelNumber,
      position: const Offset(0, 0),
      bays: [
        WarehouseBay(
          id: '${row.rowLetter.toLowerCase()}_${newLevelNumber}_1', 
          bayNumber: 1, 
          position: const Offset(0, 0),
          bins: _createDefaultBins(row.rowLetter, newLevelNumber, 1),
        ),
      ],
    );
    
    setState(() {
      row.levels.add(newLevel);
      // Auto-select the newly added level's first bay
      if (newLevel.bays.isNotEmpty) {
        selectedBayId = newLevel.bays.first.id;
      }
    });
  }

  void _addBay(WarehouseLevel level, WarehouseRow row) {
    final newBayNumber = level.bays.length + 1;
    final newBay = WarehouseBay(
      id: '${row.rowLetter.toLowerCase()}_${level.levelNumber}_$newBayNumber',
      bayNumber: newBayNumber,
      position: const Offset(0, 0),
      bins: _createDefaultBins(row.rowLetter, level.levelNumber, newBayNumber),
    );
    
    setState(() {
      level.bays.add(newBay);
      // Auto-select the newly added bay
      selectedBayId = newBay.id;
    });
  }

  void _addBin(WarehouseBay bay, WarehouseLevel level, WarehouseRow row) {
    final newBinNumber = (bay.bins.length + 1).toString().padLeft(2, '0');
    final newBin = WarehouseBin(
      id: '${row.rowLetter.toLowerCase()}_${level.levelNumber}_${bay.bayNumber}_$newBinNumber',
      binNumber: newBinNumber,
      binName: '${row.rowLetter}-${level.levelNumber}-${bay.bayNumber}-$newBinNumber',
      isOccupied: false,
      productId: null,
      productName: null,
      widthInches: 18.0,  // Default width
      heightInches: 11.0, // Default height  
      depthInches: 7.0,   // Default depth
      position: Offset(bay.bins.length * 200, 0), // Fixed spacing
    );
    
    setState(() {
      bay.bins.add(newBin);
    });
  }

  void _bulkAddBins() {
    try {
      final count = int.parse(_binCountController.text).clamp(1, 100); // Max 100 bins at once
      
      if (addToAllBays) {
        // Add to all bays
        for (final row in rows) {
          for (final level in row.levels) {
            for (final bay in level.bays) {
              for (int i = 0; i < count; i++) {
                _addBin(bay, level, row);
              }
            }
          }
        }
      } else {
        // Add to selected bay
        final selectedBay = _getBayById(selectedBayId ?? _getAllBays().first.id);
        if (selectedBay != null) {
          final level = _findLevelContainingBay(selectedBay);
          final row = _findRowContainingLevel(level);
          if (row != null && level != null) {
            for (int i = 0; i < count; i++) {
              _addBin(selectedBay, level, row);
            }
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $count bin${count > 1 ? 's' : ''} to ${addToAllBays ? 'all bays' : 'selected bay'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: Please enter a valid number (1-100)'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  double _calculateGridWidth() {
    double maxWidth = 0;
    for (final row in rows) {
      for (final level in row.levels) {
        double levelWidth = 0;
        for (final bay in level.bays) {
          levelWidth += bay.bins.length * 200.0; // Fixed bay width
        }
        maxWidth = math.max(maxWidth, levelWidth);
      }
    }
    return math.max(maxWidth + 100, 800); // Add padding
  }

  double _calculateGridHeight() {
    double totalHeight = 0;
    for (final row in rows) {
      totalHeight += row.levels.length * 275; // Fixed level height (200 + 50 header + 25 bay label)
      totalHeight += 60; // Row header height
    }
    return math.max(totalHeight + 100, 600); // Add padding
  }

  void _handleGridTap(TapDownDetails details) {
    if (isEditMode) {
      // Find which bay was tapped and add a bin
      final position = details.localPosition;
      final bay = _findBayAtPosition(position);
      
      if (bay != null) {
        // Add bin to this bay
        final level = _findLevelContainingBay(bay);
        final row = _findRowContainingLevel(level);
        if (row != null && level != null) {
          _addBin(bay, level, row);
        }
      } else {
        // Show add menu for other options
        _showAddMenu(position);
      }
    }
  }

  WarehouseBay? _findBayAtPosition(Offset position) {
    double currentY = 50;
    
    for (final row in rows) {
      currentY += 60; // Row header height
      
      for (final level in row.levels) {
        currentY += 50; // Level header height + bay label space
        
        double currentX = 50;
        for (final bay in level.bays) {
          final bayWidth = bay.bins.length * 200.0; // Fixed bay width
          
          // Check if tap is within bay area (accounting for bay label space)
          if (position.dx >= currentX && 
              position.dx <= currentX + bayWidth &&
              position.dy >= currentY + 25 &&  // Skip bay label area
              position.dy <= currentY + 25 + 200) { // Bay height
            return bay;
          }
          
          currentX += bayWidth + gridSpacing;
        }
        
        currentY += 225 + gridSpacing; // Bay height + bay label space
      }
      
      currentY += 20; // Space between rows
    }
    
    return null;
  }

  WarehouseLevel? _findLevelContainingBay(WarehouseBay targetBay) {
    for (final row in rows) {
      for (final level in row.levels) {
        if (level.bays.contains(targetBay)) {
          return level;
        }
      }
    }
    return null;
  }

  WarehouseRow? _findRowContainingLevel(WarehouseLevel? targetLevel) {
    if (targetLevel == null) return null;
    
    for (final row in rows) {
      if (row.levels.contains(targetLevel)) {
        return row;
      }
    }
    return null;
  }

  List<WarehouseBay> _getAllBays() {
    final List<WarehouseBay> allBays = [];
    for (final row in rows) {
      for (final level in row.levels) {
        allBays.addAll(level.bays);
      }
    }
    return allBays;
  }

  WarehouseBay? _getBayById(String bayId) {
    for (final row in rows) {
      for (final level in row.levels) {
        for (final bay in level.bays) {
          if (bay.id == bayId) {
            return bay;
          }
        }
      }
    }
    return null;
  }

  void _showAddMenu(Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'add_row',
          child: Row(
            children: [
              Icon(Icons.add_box),
              SizedBox(width: 8),
              Text('Add Row'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_level',
          child: Row(
            children: [
              Icon(Icons.add_circle),
              SizedBox(width: 8),
              Text('Add Level'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_bay',
          child: Row(
            children: [
              Icon(Icons.add_location),
              SizedBox(width: 8),
              Text('Add Bay'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_bin',
          child: Row(
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text('Add Bin'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'add_row':
            _addRow();
            break;
          case 'add_level':
            if (rows.isNotEmpty) {
              _addLevel(rows.first);
            }
            break;
          case 'add_bay':
            if (rows.isNotEmpty && rows.first.levels.isNotEmpty) {
              _addBay(rows.first.levels.first, rows.first);
            }
            break;
          case 'add_bin':
            if (rows.isNotEmpty && 
                rows.first.levels.isNotEmpty && 
                rows.first.levels.first.bays.isNotEmpty) {
              _addBin(rows.first.levels.first.bays.first, 
                     rows.first.levels.first, 
                     rows.first);
            }
            break;
        }
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (isEditMode) {
      dragStartPosition = details.localPosition;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (isEditMode && dragStartPosition != null) {
      // Handle dragging bins or bays
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Blueprint'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWarehouseBlueprint,
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 800;
                
                if (isSmallScreen) {
                  // Stack buttons vertically on small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add_box),
                            label: const Text('Add Row'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (rows.isNotEmpty) {
                                _addLevel(rows.first);
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Add Level'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (rows.isNotEmpty && rows.first.levels.isNotEmpty) {
                                _addBay(rows.first.levels.first, rows.first);
                              }
                            },
                            icon: const Icon(Icons.add_location),
                            label: const Text('Add Bay'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (rows.isNotEmpty && _getAllBays().isNotEmpty) ...[
                            // Bay Selection Mode Toggle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      addToAllBays ? Icons.check_box : Icons.check_box_outline_blank,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        addToAllBays = !addToAllBays;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const Text('All Bays', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            if (!addToAllBays)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedBayId ?? _getAllBays().first.id,
                                  hint: const Text('Select Bay'),
                                  items: _getAllBays().map((bay) {
                                    final level = _findLevelContainingBay(bay);
                                    final row = _findRowContainingLevel(level);
                                    return DropdownMenuItem<String>(
                                      value: bay.id,
                                      child: Text(
                                        'Row ${row?.rowLetter ?? '?'} - Level ${level?.levelNumber ?? '?'} - Bay ${bay.bayNumber}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBayId = value;
                                    });
                                  },
                                  underline: const SizedBox(),
                                  isDense: true,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            // Number of bins input
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _binCountController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  labelStyle: const TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _bulkAddBins,
                              icon: const Icon(Icons.add),
                              label: Text(addToAllBays ? 'Add to All' : 'Add Bin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Default Bin Size: 18" × 11" × 7"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                
                // Original horizontal layout for larger screens
                return Row(
                  children: [
                ElevatedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_box),
                  label: const Text('Add Row'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (rows.isNotEmpty) {
                      _addLevel(rows.first);
                    }
                  },
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Level'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (rows.isNotEmpty && rows.first.levels.isNotEmpty) {
                      _addBay(rows.first.levels.first, rows.first);
                    }
                  },
                  icon: const Icon(Icons.add_location),
                  label: const Text('Add Bay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Bay Selector Dropdown and Bulk Add Controls
                if (rows.isNotEmpty && _getAllBays().isNotEmpty) ...[
                  const SizedBox(width: 16),
                  // Bay Selection Mode Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            addToAllBays ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              addToAllBays = !addToAllBays;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Text('All Bays', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!addToAllBays) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: selectedBayId ?? _getAllBays().first.id,
                        hint: const Text('Select Bay'),
                        items: _getAllBays().map((bay) {
                          final level = _findLevelContainingBay(bay);
                          final row = _findRowContainingLevel(level);
                          return DropdownMenuItem<String>(
                            value: bay.id,
                            child: Text(
                              'Row ${row?.rowLetter ?? '?'} - Level ${level?.levelNumber ?? '?'} - Bay ${bay.bayNumber}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBayId = value;
                          });
                        },
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Number of bins input
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _binCountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        labelStyle: const TextStyle(fontSize: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _bulkAddBins,
                    icon: const Icon(Icons.add),
                    label: Text(addToAllBays ? 'Add to All' : 'Add Bin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Default Bin Size: 18" × 11" × 7"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                  ],
                );
              },
            ),
          ),
          
          // Warehouse Grid Visualization
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10), // 10px padding on all sides
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gridWidth = _calculateGridWidth();
                  final gridHeight = _calculateGridHeight();
                  
                  // Calculate scale factor to fit within available space (accounting for 10px padding on each side = 20px total)
                  final availableWidth = constraints.maxWidth - 20; // 10px padding on each side
                  final availableHeight = constraints.maxHeight - 20; // 10px padding on each side
                  
                  final scaleX = availableWidth / gridWidth;
                  final scaleY = availableHeight / gridHeight;
                  final scale = math.min(scaleX, scaleY).clamp(0.1, 1.0); // Don't scale up, only down
                  
                  return InteractiveViewer(
                    minScale: 0.3,
                    maxScale: 3.0,
                    panEnabled: true,
                    scaleEnabled: false, // Disable zooming on scroll
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topLeft,
                      child: CustomPaint(
                        painter: WarehouseGridPainter(
                          rows: rows,
                          gridSpacing: gridSpacing,
                          isEditMode: isEditMode,
                          selectedBinId: selectedBinId,
                        ),
                        child: GestureDetector(
                          onTapDown: (details) {
                            // Adjust tap position for scale and padding
                            final adjustedDetails = TapDownDetails(
                              globalPosition: details.globalPosition,
                              localPosition: Offset(
                                (details.localPosition.dx - 10) / scale, // Account for left padding
                                (details.localPosition.dy - 10) / scale, // Account for top padding
                              ),
                            );
                            _handleGridTap(adjustedDetails);
                          },
                          onPanStart: (details) => _handlePanStart(details),
                          onPanUpdate: (details) => _handlePanUpdate(details),
                          child: SizedBox(
                            width: gridWidth,
                            height: gridHeight,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _binCountController.dispose();
    super.dispose();
  }
}

// Custom Painter for Warehouse Grid
class WarehouseGridPainter extends CustomPainter {
  final List<WarehouseRow> rows;
  final double gridSpacing;
  final bool isEditMode;
  final String? selectedBinId;

  WarehouseGridPainter({
    required this.rows,
    required this.gridSpacing,
    required this.isEditMode,
    this.selectedBinId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double currentY = 50; // Start below header

    for (final row in rows) {
      // Draw row header
      _drawRowHeader(canvas, row, currentY);
      currentY += 60;

      for (final level in row.levels) {
        // Draw level header
        _drawLevelHeader(canvas, level, currentY);
        currentY += 50; // More space after level header for bay labels

        // Draw bays for this level
        double currentX = 50;
        for (final bay in level.bays) {
          final bayWidth = bay.bins.length * 200.0; // Fixed bay width
          
          // Draw bay label above the bay outline
          _drawBayLabel(canvas, bay, currentX, currentY, bayWidth);
          
          // Draw bay outline
          _drawBayOutline(canvas, bay, currentX, currentY + 25, bayWidth);
          
          // Draw bins within bay
          _drawBinsInBay(canvas, bay, currentX, currentY + 25);
          
          currentX += bayWidth + gridSpacing;
        }
        
        currentY += 225 + gridSpacing; // Fixed bin height + bay label space
      }
      
      currentY += 20; // Space between rows
    }
  }

  void _drawRowHeader(Canvas canvas, WarehouseRow row, double y) {
    final paint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(20, y, 400, 50);
    canvas.drawRect(rect, paint);

    // Draw row letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Row ${row.rowLetter}',
        style: TextStyle(
          color: Colors.blue.shade800,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(30, y + 15));
  }

  void _drawLevelHeader(Canvas canvas, WarehouseLevel level, double y) {
    final paint = Paint()
      ..color = Colors.green.shade100
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(20, y, 300, 30);
    canvas.drawRect(rect, paint);

    // Draw level number
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Level ${level.levelNumber}',
        style: TextStyle(
          color: Colors.green.shade800,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(30, y + 7));
  }

  void _drawBayLabel(Canvas canvas, WarehouseBay bay, double x, double y, double width) {
    final bayTextPainter = TextPainter(
      text: TextSpan(
        text: 'Bay ${bay.bayNumber}',
        style: TextStyle(
          color: Colors.orange.shade800,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    bayTextPainter.layout();
    bayTextPainter.paint(canvas, Offset(x + 5, y + 5));
  }

  void _drawBayOutline(Canvas canvas, WarehouseBay bay, double x, double y, double width) {
    final paint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTWH(x, y, width, 200); // Fixed bin height
    canvas.drawRect(rect, paint);
  }

  void _drawBinsInBay(Canvas canvas, WarehouseBay bay, double startX, double startY) {
    const binWidth = 180.0; // Smaller width to fit inside bay
    const binHeight = 80.0;  // Smaller height to fit inside bay
    const binSpacing = 10.0; // Space between bins
    
    for (int i = 0; i < bay.bins.length; i++) {
      final bin = bay.bins[i];
      final binX = startX + 10 + (i * (binWidth + binSpacing)); // Offset from bay edge
      final binY = startY + 10; // Offset from bay top
      
      final isSelected = selectedBinId == bin.id;
      
      // Draw bin background
      final paint = Paint()
        ..color = bin.isOccupied 
            ? Colors.red.shade200 
            : isSelected 
                ? Colors.blue.shade200 
                : Colors.grey.shade100
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(binX, binY, binWidth, binHeight);
      canvas.drawRect(rect, paint);

      // Draw bin border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.blue : Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.0;
      
      canvas.drawRect(rect, borderPaint);

      // Draw bin label
      final binLabelPainter = TextPainter(
        text: TextSpan(
          text: 'Bin ${bin.binNumber}',
          style: TextStyle(
            color: bin.isOccupied ? Colors.red.shade800 : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      binLabelPainter.layout();
      binLabelPainter.paint(
        canvas, 
        Offset(
          binX + (binWidth - binLabelPainter.width) / 2,
          binY + 10,
        ),
      );

      // Draw bin dimensions
      final dimensionsPainter = TextPainter(
        text: TextSpan(
          text: '18"×11"×7"',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dimensionsPainter.layout();
      dimensionsPainter.paint(
        canvas, 
        Offset(
          binX + (binWidth - dimensionsPainter.width) / 2,
          binY + binHeight - 20,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Models
class WarehouseRow {
  final String id;
  final String rowLetter;
  final Offset position;
  final List<WarehouseLevel> levels;

  WarehouseRow({
    required this.id,
    required this.rowLetter,
    required this.position,
    required this.levels,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rowLetter': rowLetter,
      'position': {'dx': position.dx, 'dy': position.dy},
      'levels': levels.map((level) => level.toMap()).toList(),
    };
  }

  static WarehouseRow fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>?;
    return WarehouseRow(
      id: map['id'],
      rowLetter: map['rowLetter'],
      position: positionMap != null 
          ? Offset(positionMap['dx']?.toDouble() ?? 0, positionMap['dy']?.toDouble() ?? 0)
          : const Offset(0, 0),
      levels: (map['levels'] as List)
          .map((level) => WarehouseLevel.fromMap(level))
          .toList(),
    );
  }
}

class WarehouseLevel {
  final String id;
  final int levelNumber;
  final Offset position;
  final List<WarehouseBay> bays;

  WarehouseLevel({
    required this.id,
    required this.levelNumber,
    required this.position,
    required this.bays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'levelNumber': levelNumber,
      'position': {'dx': position.dx, 'dy': position.dy},
      'bays': bays.map((bay) => bay.toMap()).toList(),
    };
  }

  static WarehouseLevel fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>?;
    return WarehouseLevel(
      id: map['id'],
      levelNumber: map['levelNumber'],
      position: positionMap != null 
          ? Offset(positionMap['dx']?.toDouble() ?? 0, positionMap['dy']?.toDouble() ?? 0)
          : const Offset(0, 0),
      bays: (map['bays'] as List)
          .map((bay) => WarehouseBay.fromMap(bay))
          .toList(),
    );
  }
}

class WarehouseBay {
  final String id;
  final int bayNumber;
  final Offset position;
  final List<WarehouseBin> bins;

  WarehouseBay({
    required this.id,
    required this.bayNumber,
    required this.position,
    required this.bins,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bayNumber': bayNumber,
      'position': {'dx': position.dx, 'dy': position.dy},
      'bins': bins.map((bin) => bin.toMap()).toList(),
    };
  }

  static WarehouseBay fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>?;
    return WarehouseBay(
      id: map['id'],
      bayNumber: map['bayNumber'],
      position: positionMap != null 
          ? Offset(positionMap['dx']?.toDouble() ?? 0, positionMap['dy']?.toDouble() ?? 0)
          : const Offset(0, 0),
      bins: (map['bins'] as List)
          .map((bin) => WarehouseBin.fromMap(bin))
          .toList(),
    );
  }
}

class WarehouseBin {
  final String id;
  final String binNumber;
  final String binName;
  final bool isOccupied;
  final String? productId;
  final String? productName;
  final double widthInches;
  final double heightInches;
  final double depthInches;
  Offset position;

  WarehouseBin({
    required this.id,
    required this.binNumber,
    required this.binName,
    required this.isOccupied,
    this.productId,
    this.productName,
    required this.widthInches,
    required this.heightInches,
    required this.depthInches,
    required this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'binNumber': binNumber,
      'binName': binName,
      'isOccupied': isOccupied,
      'productId': productId,
      'productName': productName,
      'widthInches': widthInches,
      'heightInches': heightInches,
      'depthInches': depthInches,
      'position': {'dx': position.dx, 'dy': position.dy},
    };
  }

  static WarehouseBin fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>?;
    return WarehouseBin(
      id: map['id'],
      binNumber: map['binNumber'],
      binName: map['binName'],
      isOccupied: map['isOccupied'] ?? false,
      productId: map['productId'],
      productName: map['productName'],
      widthInches: map['widthInches']?.toDouble() ?? 18.0,
      heightInches: map['heightInches']?.toDouble() ?? 11.0,
      depthInches: map['depthInches']?.toDouble() ?? 7.0,
      position: positionMap != null 
          ? Offset(positionMap['dx']?.toDouble() ?? 0, positionMap['dy']?.toDouble() ?? 0)
          : const Offset(0, 0),
    );
  }
}
