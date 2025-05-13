import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting - add to pubspec.yaml

// --- Data Model for the Report ---
class BusinessSummaryReport {
  final DateTime fromDate;
  final DateTime toDate;
  final double caSales; // Cash Sales
  final double crSales; // Credit Sales
  final double totalSales;
  final double returns;
  final double nettSales;
  final double totalCrCollect; // Total Credit Collection
  final double totalCashCollect;
  final double chequeCollect;
  final double pdChequeCollect; // Post-Dated Cheque Collection
  final double totalCollection;

  BusinessSummaryReport({
    required this.fromDate,
    required this.toDate,
    this.caSales = 0.0,
    this.crSales = 0.0,
    this.totalSales = 0.0,
    this.returns = 0.0,
    this.nettSales = 0.0,
    this.totalCrCollect = 0.0,
    this.totalCashCollect = 0.0,
    this.chequeCollect = 0.0,
    this.pdChequeCollect = 0.0,
    this.totalCollection = 0.0,
  });
}

class BusinessSummaryReportPage extends StatefulWidget {
  const BusinessSummaryReportPage({super.key});

  @override
  State<BusinessSummaryReportPage> createState() =>
      _BusinessSummaryReportPageState();
}

class _BusinessSummaryReportPageState extends State<BusinessSummaryReportPage> {
  DateTime _fromDate = DateTime.now().subtract(
    const Duration(days: 7),
  ); // Default to last 7 days
  DateTime _toDate = DateTime.now();
  BusinessSummaryReport? _currentReport;
  bool _isLoading = false;

  final DateFormat _dateFormatter = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    // Optionally, load a default report
    // _fetchReportData();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: isFromDate ? 'SELECT FROM DATE' : 'SELECT TO DATE',
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Ensure "To Date" is not before "From Date"
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          // Ensure "From Date" is not after "To Date"
          if (_fromDate.isAfter(_toDate)) {
            _fromDate = _toDate;
          }
        }
        _currentReport = null; // Clear previous report when date changes
      });
    }
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _currentReport = null; // Clear previous report
    });

    // --- TODO: Replace with actual API call or data fetching logic ---
    // Simulating a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data generation based on dates (very basic example)
    final days = _toDate.difference(_fromDate).inDays + 1;
    setState(() {
      _currentReport = BusinessSummaryReport(
        fromDate: _fromDate,
        toDate: _toDate,
        caSales: 1000.0 * days * 0.8,
        crSales: 1500.0 * days * 0.9,
        totalSales: (1000.0 * days * 0.8) + (1500.0 * days * 0.9),
        returns: 50.0 * days,
        nettSales:
            ((1000.0 * days * 0.8) + (1500.0 * days * 0.9)) - (50.0 * days),
        totalCrCollect: 1200.0 * days * 0.7,
        totalCashCollect: 900.0 * days * 0.85,
        chequeCollect: 300.0 * days,
        pdChequeCollect: 100.0 * days,
        totalCollection:
            (1200.0 * days * 0.7) +
            (900.0 * days * 0.85) +
            (300.0 * days) +
            (100.0 * days),
      );
      _isLoading = false;
    });
  }

  void _handlePrint() {
    if (_currentReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a report first (tap Preview).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // TODO: Implement actual print logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print action tapped (not implemented).'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reporting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Report',
            onPressed: _handlePrint,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Business Summary',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Date Range Pickers
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          FontAwesomeIcons.calendarDays,
                          size: 18,
                        ),
                      ),
                      child: Text(_dateFormatter.format(_fromDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          FontAwesomeIcons.calendarDays,
                          size: 18,
                        ),
                      ),
                      child: Text(_dateFormatter.format(_toDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Preview Button
            ElevatedButton.icon(
              icon:
                  _isLoading
                      ? Container(
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(FontAwesomeIcons.magnifyingGlassChart),
              label: const Text('Preview Summary'),
              onPressed: _isLoading ? null : _fetchReportData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Report Display Section
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_isLoading && _currentReport != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary for ${_dateFormatter.format(_currentReport!.fromDate)} to ${_dateFormatter.format(_currentReport!.toDate)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildReportRow('CA Sales:', _currentReport!.caSales),
                      _buildReportRow('CR Sales:', _currentReport!.crSales),
                      _buildReportRow(
                        'Total Sales:',
                        _currentReport!.totalSales,
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildReportRow('Return:', _currentReport!.returns),
                      _buildReportRow(
                        'Nett Sales:',
                        _currentReport!.nettSales,
                        isBold: true,
                      ),
                      const Divider(height: 20),
                      _buildReportRow(
                        'Total CR Collect:',
                        _currentReport!.totalCrCollect,
                      ),
                      _buildReportRow(
                        'Total Cash Collect:',
                        _currentReport!.totalCashCollect,
                      ),
                      _buildReportRow(
                        'Cheque Collect:',
                        _currentReport!.chequeCollect,
                      ),
                      _buildReportRow(
                        'PD-Cheque Collect:',
                        _currentReport!.pdChequeCollect,
                      ),
                      _buildReportRow(
                        'Total Collection:',
                        _currentReport!.totalCollection,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _currentReport == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    'Select a date range and tap "Preview Summary" to generate the report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color:
                  isBold
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.black54,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color:
                  isBold
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
