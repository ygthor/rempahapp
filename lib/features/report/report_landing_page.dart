import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kanesanapp/features/report/business_summary_report_page.dart';
import 'package:kanesanappp/features/report/sales_order_report_page.dart';

// Import your specific report pages here
// Make sure the path is correct based on your project structure.

// --- Model for a Report Menu Item ---
class ReportMenuItem {
  final String title;
  final String description;
  final IconData icon;
  final Widget targetPage; // The page to navigate to

  ReportMenuItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetPage,
  });
}

// --- Report Landing Page ---
class ReportLandingPage extends StatefulWidget {
  const ReportLandingPage({super.key});

  @override
  State<ReportLandingPage> createState() => _ReportLandingPageState();
}

class _ReportLandingPageState extends State<ReportLandingPage> {
  late final List<ReportMenuItem> _reportMenuItems;

  @override
  void initState() {
    super.initState();
    _reportMenuItems = _initializeReportMenuItems();
  }

  List<ReportMenuItem> _initializeReportMenuItems() {
    // Define all your available reports here
    return [
      ReportMenuItem(
        title: 'Business Summary',
        description:
            'View overall sales, collections, and nett sales for a period.',
        icon: FontAwesomeIcons.chartPie,
        targetPage:
            BusinessSummaryReportPage(), // Navigate to the Business Summary page
      ),
      ReportMenuItem(
        title: 'Sales Analysis',
        description:
            'Detailed breakdown of sales by product, customer, or region.',
        icon: FontAwesomeIcons.chartLine,
        targetPage: SalesOrderReportPage(),
      ),
      ReportMenuItem(
        title: 'Inventory Valuation',
        description: 'Current stock value, aging, and movement summary.',
        icon: FontAwesomeIcons.boxesStacked,
        targetPage: const PlaceholderReportPage(
          reportName: 'Inventory Valuation Report',
        ), // Placeholder
      ),
      ReportMenuItem(
        title: 'Customer Debt Aging',
        description: 'Analysis of outstanding customer debts by aging period.',
        icon: FontAwesomeIcons.fileInvoiceDollar,
        targetPage: const PlaceholderReportPage(
          reportName: 'Customer Debt Aging Report',
        ), // Placeholder
      ),
      ReportMenuItem(
        title: 'Profit & Loss Statement',
        description: 'Generate a P&L report for a selected period.',
        icon: FontAwesomeIcons.sackDollar,
        targetPage: const PlaceholderReportPage(
          reportName: 'Profit & Loss Statement',
        ), // Placeholder
      ),
      // Add more ReportMenuItem objects for other reports
    ];
  }

  void _navigateToReport(BuildContext context, Widget targetPage) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Reports'),
        // backgroundColor: Theme.of(context).primaryColor, // Example
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: _reportMenuItems.length,
        itemBuilder: (context, index) {
          final menuItem = _reportMenuItems[index];
          return Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColorLight.withOpacity(0.5),
                foregroundColor: Theme.of(context).primaryColorDark,
                child: FaIcon(menuItem.icon, size: 22),
              ),
              title: Text(
                menuItem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  menuItem.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey,
              ),
              onTap: () => _navigateToReport(context, menuItem.targetPage),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
      ),
    );
  }
}

// --- Placeholder Page for other reports (until they are implemented) ---
class PlaceholderReportPage extends StatelessWidget {
  final String reportName;
  const PlaceholderReportPage({super.key, required this.reportName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(reportName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.tools, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              '$reportName is under construction.',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This page will be available soon!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
