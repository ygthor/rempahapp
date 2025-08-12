// ... (keep the TransactionList class as is) ...
import 'package:flutter/material.dart';

class TransactionList<T> extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function() fetchData;
  final Widget Function(T item) itemBuilder;
  final T Function(Map<String, dynamic> json) fromJson;

  const TransactionList({super.key, required this.fetchData, required this.itemBuilder, required this.fromJson});

  @override
  State<TransactionList<T>> createState() => TransactionListState<T>();
}

// REPLACE THIS ENTIRE STATE CLASS
class TransactionListState<T> extends State<TransactionList<T>> {
  late Future<Map<String, dynamic>?> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = widget.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        // --- THE FIX IS HERE ---
        // 1. Check if the top-level response or the first 'data' key is missing.
        if (!snapshot.hasData || snapshot.data?['data'] == null) {
          return const Center(child: Text('No records found or invalid format.'));
        }

        // 2. Safely access the outer data object, which contains pagination info.
        final paginatedData = snapshot.data!['data'];

        // 3. Check if the paginated data is a Map and contains the nested 'data' list.
        if (paginatedData is! Map || paginatedData['data'] == null || paginatedData['data'] is! List) {
          return const Center(child: Text('Paginated data is in an unexpected format.'));
        }

        // 4. Extract the actual list from the NESTED 'data' key.
        final List<dynamic> dataList = paginatedData['data'];

        if (dataList.isEmpty) {
          return const Center(child: Text('No records found.'));
        }

        // 5. The rest of the logic remains the same.
        // It maps the list and builds the UI.
        try {
          final List<T> items = dataList.map((itemJson) => widget.fromJson(itemJson as Map<String, dynamic>)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) => widget.itemBuilder(items[index]),
          );
        } catch (e) {
          // Add a catch block to see errors during parsing (e.g. if Invoice.fromJson fails)
          return Center(child: Text('Error parsing data: $e'));
        }
      },
    );
  }
}
