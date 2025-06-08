import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Assuming models and services are in these paths
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/shared/functions.dart';
import 'package:get/get.dart';

// --- Data Model ---
class InventoryItem {
  final String skuCode;
  final String productName;
  final double quantity;
  final String groupId;
  final String subGroupId;
  final String inventoryType;

  InventoryItem({
    required this.skuCode,
    required this.productName,
    required this.quantity,
    required this.groupId,
    required this.subGroupId,
    required this.inventoryType,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      skuCode: json['skuCode'] as String? ?? 'N/A',
      productName: json['productName'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      groupId: json['groupId'] as String? ?? '',
      subGroupId: json['subGroupId'] as String? ?? '',
      inventoryType: json['inventoryType'] as String? ?? 'GOOD',
    );
  }
}

// Data for dropdowns - these should also be fetched from an API in a real app
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
final Map<String, List<String>> _groupSubGroupInventoryMap = {
  'g1': ['sg1_1', 'sg1_2'],
  'g2': ['sg2_1', 'sg2_2'],
  'g3': ['sg3_1', 'sg3_2'],
};
final List<String> _inventoryTypes = ['GOOD', 'DAMAGED', 'EXPIRED', 'RETURNED'];

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  late ApiV1 _api;
  bool _isLoading = true;
  String _errorMessage = '';

  // --- Filter State Variables ---
  String? _selectedGroupId;
  String? _selectedSubGroupId;
  String? _selectedInventoryType = 'GOOD';

  List<InventoryItem> _filteredInventoryItems = [];
  List<String> _availableSubGroupIds = [];

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _api.getInventory(
        groupId: _selectedGroupId,
        subGroupId: _selectedSubGroupId,
        inventoryType: _selectedInventoryType,
      );

      if (response != null &&
          response['error'] != true &&
          response['data'] is List) {
        final List<dynamic> itemsData = response['data'];
        setState(() {
          _filteredInventoryItems =
              itemsData
                  .map(
                    (data) =>
                        InventoryItem.fromJson(data as Map<String, dynamic>),
                  )
                  .toList();
          _filteredInventoryItems.sort(
            (a, b) => a.skuCode.compareTo(b.skuCode),
          );
        });
      } else {
        setState(
          () =>
              _errorMessage =
                  response?['message']?.toString() ??
                  'Failed to load inventory.',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'An application error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onGroupChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedSubGroupId = null;
      _availableSubGroupIds =
          (groupId != null && _groupSubGroupInventoryMap.containsKey(groupId))
              ? _groupSubGroupInventoryMap[groupId]!
              : [];
    });
    _fetchInventory();
  }

  void _onSubGroupChanged(String? subGroupId) {
    setState(() => _selectedSubGroupId = subGroupId);
    _fetchInventory();
  }

  void _onInventoryTypeChanged(String? inventoryType) {
    setState(() => _selectedInventoryType = inventoryType);
    _fetchInventory();
  }

  void _clearFilters() {
    setState(() {
      _selectedGroupId = null;
      _selectedSubGroupId = null;
      _selectedInventoryType = 'GOOD';
      _availableSubGroupIds = [];
    });
    _fetchInventory();
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
            onPressed: _isLoading ? null : _fetchInventory,
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
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : _filteredInventoryItems.isEmpty
                    ? Center(
                      child: Text(
                        'No inventory items found for the selected filters.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchInventory,
                      child: ListView.separated(
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
                                flex: 10,
                                child: Text(
                                  item.skuCode + " " + item.productName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.quantity.toStringAsFixed(1),
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
          DropdownButtonFormField<String>(
            value: _selectedGroupId,
            decoration: InputDecoration(
              labelText: 'Group',
              hintText: 'All Groups',
              prefixIcon: const Icon(FontAwesomeIcons.layerGroup, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Groups'),
              ),
              ..._inventoryGroups.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
            ],
            onChanged: _onGroupChanged,
          ),
          const SizedBox(height: 10),
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
              ..._availableSubGroupIds
                  .map(
                    (id) => DropdownMenuItem<String>(
                      value: id,
                      child: Text(_inventorySubGroups[id] ?? 'Unknown'),
                    ),
                  )
                  .toList(),
            ],
            onChanged: _selectedGroupId != null ? _onSubGroupChanged : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedInventoryType,
            decoration: InputDecoration(
              labelText: 'Inventory Type',
              hintText: 'All Types',
              prefixIcon: const Icon(FontAwesomeIcons.tags, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Types'),
              ),
              ..._inventoryTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
            ],
            onChanged: _onInventoryTypeChanged,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
            label: const Text('Clear Filters'),
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
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
