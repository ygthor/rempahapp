import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- Data Models ---
class InventoryItem {
  final String skuCode;
  final String productName; // Optional: for more context
  final double quantity;
  final String groupId;
  final String subGroupId;
  final String inventoryType; // e.g., "GOOD", "DAMAGED", "EXPIRED"

  InventoryItem({
    required this.skuCode,
    required this.productName,
    required this.quantity,
    required this.groupId,
    required this.subGroupId,
    required this.inventoryType,
  });
}

// Mock data for groups, subgroups, and inventory types
// In a real app, these would come from your backend or a shared data source.
// Using similar group/subgroup structure from previous examples for consistency.
final Map<String, String> _inventoryGroups = {
  'g1': 'Herbs & Spices',
  'g2': 'Sauces & Pastes',
  'g3': 'Grains & Flours',
};

final Map<String, String> _inventorySubGroups = {
  'sg1_1': 'Whole Spices',
  'sg1_2': 'Ground Spices',
  'sg2_1': 'Chili Sauces',
  'sg2_2': 'Cooking Pastes',
  'sg3_1': 'Rice Varieties',
  'sg3_2': 'Specialty Flours',
};

// Group -> SubGroups mapping
final Map<String, List<String>> _groupSubGroupInventoryMap = {
  'g1': ['sg1_1', 'sg1_2'],
  'g2': ['sg2_1', 'sg2_2'],
  'g3': ['sg3_1', 'sg3_2'],
};

final List<String> _inventoryTypes = ['GOOD', 'DAMAGED', 'EXPIRED', 'RETURNED'];

// --- Mock Inventory Data ---
final List<InventoryItem> _allInventoryItems = [
  InventoryItem(
    skuCode: 'ABBM',
    productName: 'Star Anise',
    quantity: 3.5,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'BC2',
    productName: 'Cumin Powder',
    quantity: 0.0,
    groupId: 'g1',
    subGroupId: 'sg1_2',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'BK10K',
    productName: 'Turmeric Powder',
    quantity: 8.0,
    groupId: 'g1',
    subGroupId: 'sg1_2',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'BKBK1',
    productName: 'Cinnamon Sticks',
    quantity: 11.0,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'BL2',
    productName: 'Chili Flakes',
    quantity: 0.0,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'DAMAGED',
  ),
  InventoryItem(
    skuCode: 'L500',
    productName: 'Soy Sauce',
    quantity: 3.0,
    groupId: 'g2',
    subGroupId: 'sg2_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'BR2',
    productName: 'Tomato Paste',
    quantity: 0.0,
    groupId: 'g2',
    subGroupId: 'sg2_2',
    inventoryType: 'EXPIRED',
  ),
  InventoryItem(
    skuCode: 'BSEL2',
    productName: 'Basmati Rice',
    quantity: 0.0,
    groupId: 'g3',
    subGroupId: 'sg3_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'C1KK',
    productName: 'Gram Flour',
    quantity: 0.0,
    groupId: 'g3',
    subGroupId: 'sg3_2',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'C20K',
    productName: 'Cloves',
    quantity: 5.0,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'B3',
    productName: 'Mustard Seeds',
    quantity: 0.0,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'RETURNED',
  ),
  InventoryItem(
    skuCode: 'G30',
    productName: 'Fish Curry Paste',
    quantity: 7.0,
    groupId: 'g2',
    subGroupId: 'sg2_2',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'GCM',
    productName: 'Cardamom Pods',
    quantity: 19.0,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'GJ',
    productName: 'Jasmine Rice',
    quantity: 36.0,
    groupId: 'g3',
    subGroupId: 'sg3_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'GKV',
    productName: 'Oyster Sauce',
    quantity: 0.0,
    groupId: 'g2',
    subGroupId: 'sg2_1',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'GR',
    productName: 'Rice Flour',
    quantity: 12.0,
    groupId: 'g3',
    subGroupId: 'sg3_2',
    inventoryType: 'DAMAGED',
  ),
  InventoryItem(
    skuCode: 'HC2',
    productName: 'Coriander Powder',
    quantity: 6.5,
    groupId: 'g1',
    subGroupId: 'sg1_2',
    inventoryType: 'GOOD',
  ),
  InventoryItem(
    skuCode: 'IC',
    productName: 'Almond Flour',
    quantity: 0.0,
    groupId: 'g3',
    subGroupId: 'sg3_2',
    inventoryType: 'EXPIRED',
  ),
  InventoryItem(
    skuCode: 'JM1K',
    productName: 'Szechuan Peppercorns',
    quantity: 2.0,
    groupId: 'g1',
    subGroupId: 'sg1_1',
    inventoryType: 'GOOD',
  ),
];

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  // --- Filter State Variables ---
  String? _selectedGroupId;
  String? _selectedSubGroupId;
  String? _selectedInventoryType =
      'GOOD'; // Default to 'GOOD' as per screenshot

  List<InventoryItem> _filteredInventoryItems = [];
  List<String> _availableSubGroupIds = []; // For dependent dropdown

  @override
  void initState() {
    super.initState();
    _applyFilters(); // Apply default filters on initial load
  }

  void _applyFilters() {
    setState(() {
      _filteredInventoryItems =
          _allInventoryItems.where((item) {
            final bool groupMatch =
                _selectedGroupId == null || item.groupId == _selectedGroupId;
            final bool subGroupMatch =
                _selectedSubGroupId == null ||
                item.subGroupId == _selectedSubGroupId;
            final bool typeMatch =
                _selectedInventoryType == null ||
                item.inventoryType == _selectedInventoryType;
            return groupMatch && subGroupMatch && typeMatch;
          }).toList();
      // Sort by SKU code for consistent display
      _filteredInventoryItems.sort((a, b) => a.skuCode.compareTo(b.skuCode));
    });
  }

  void _onGroupChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedSubGroupId = null; // Reset sub-group when group changes
      _availableSubGroupIds =
          (groupId != null && _groupSubGroupInventoryMap.containsKey(groupId))
              ? _groupSubGroupInventoryMap[groupId]!
              : [];
    });
    _applyFilters();
  }

  void _onSubGroupChanged(String? subGroupId) {
    setState(() {
      _selectedSubGroupId = subGroupId;
    });
    _applyFilters();
  }

  void _onInventoryTypeChanged(String? inventoryType) {
    setState(() {
      _selectedInventoryType = inventoryType;
    });
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _selectedGroupId = null;
      _selectedSubGroupId = null;
      _selectedInventoryType = 'GOOD'; // Reset to default or null as preferred
      _availableSubGroupIds = [];
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh Stock',
            onPressed: () {
              // TODO: Implement actual refresh logic (e.g., re-fetch from API)
              _applyFilters(); // Re-apply filters with current mock data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inventory refreshed (mock data).'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(height: 1, thickness: 1),
          _buildInventoryListHeader(),
          Expanded(
            child:
                _filteredInventoryItems.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.boxesStacked,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No inventory items found.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          if (_selectedGroupId != null ||
                              _selectedSubGroupId != null ||
                              _selectedInventoryType != null)
                            const Text(
                              'Try adjusting your filters.',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: _filteredInventoryItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredInventoryItems[index];
                        return Row(
                          children: [
                            Expanded(
                              flex: 3, // SKU Code takes more space
                              child: Text(
                                item.skuCode,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 2, // Quantity
                              child: Text(
                                item.quantity.toStringAsFixed(
                                  1,
                                ), // Display quantity with 1 decimal place
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      item.quantity > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      item.quantity > 0
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      separatorBuilder:
                          (context, index) => const Divider(height: 12),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Group Filter
          DropdownButtonFormField<String>(
            value: _selectedGroupId,
            decoration: InputDecoration(
              labelText: 'Group',
              hintText: 'All Groups',
              prefixIcon: const Icon(FontAwesomeIcons.layerGroup, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Groups'),
              ),
              ..._inventoryGroups.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ],
            onChanged: _onGroupChanged,
          ),
          const SizedBox(height: 10),

          // Sub Group Filter
          DropdownButtonFormField<String>(
            value: _selectedSubGroupId,
            decoration: InputDecoration(
              labelText: 'Sub Group',
              hintText:
                  _selectedGroupId == null
                      ? 'Select Group First'
                      : 'All Sub Groups',
              prefixIcon: const Icon(FontAwesomeIcons.objectUngroup, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            isExpanded: true,
            disabledHint:
                _selectedGroupId == null
                    ? const Text("Select Group First")
                    : null,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Sub Groups'),
              ),
              ..._availableSubGroupIds.map((subGroupId) {
                return DropdownMenuItem<String>(
                  value: subGroupId,
                  child: Text(_inventorySubGroups[subGroupId] ?? 'Unknown'),
                );
              }).toList(),
            ],
            onChanged:
                _selectedGroupId != null
                    ? _onSubGroupChanged
                    : null, // Enable only if group is selected
          ),
          const SizedBox(height: 10),

          // Inventory Type Filter
          DropdownButtonFormField<String>(
            value: _selectedInventoryType,
            decoration: InputDecoration(
              labelText: 'Inventory Type',
              hintText: 'All Types',
              prefixIcon: const Icon(FontAwesomeIcons.tags, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Types'),
              ),
              ..._inventoryTypes.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
            ],
            onChanged: _onInventoryTypeChanged,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
            label: const Text('Clear Filters'),
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              // foregroundColor: Theme.of(context).colorScheme.secondary,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'SKU Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Quantity',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
