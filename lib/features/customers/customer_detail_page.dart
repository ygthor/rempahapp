import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Adjust these import paths if they differ in your project structure
import 'package:kanesanapp/api/api_v1.dart';
import 'package:kanesanappp/features/customers/customer_form_page.dart';
import 'package:kanesanappp/features/customers/widgets/transaction_list.dart';
import 'package:kanesanappp/features/invoices/invoice_form_page.dart';
import 'package:kanesanappp/features/orders/order_form_page.dart';
import 'package:kanesanappp/models/customer.dart';
import 'package:kanesanappp/models/global_state.dart';
import 'package:kanesanappp/models/invoice.dart';
import 'package:kanesanappp/models/order.dart';
import 'package:kanesanappp/shared/functions.dart';
// Import your new placeholder models

// A generic status for transactions
enum TransactionStatus { Pending, Completed, Cancelled, Overdue }

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

// Add the TickerProviderStateMixin for the TabController
class _CustomerDetailPageState extends State<CustomerDetailPage> with TickerProviderStateMixin {
  // Keep all your form controllers and logic
  final _formKey = GlobalKey<FormState>();
  late ApiV1 _api;
  bool _isSaving = false;
  // ... [ALL YOUR TEXTEDITINGCONTROLLERS AND DROPDOWN VARIABLES] ...
  // For brevity, assuming they are here

  // NEW: State for managing view vs. edit mode
  bool _isEditing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);

    // Initialize the TabController
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initialize all your form controllers and populate them
    // _initializeAndPopulateAllFields(); // Encapsulate this logic
  }

  void _handleTabSelection() {
    // Hide the edit/save button if we move away from the details tab
    if (_tabController.index != 0 && _isEditing) {
      setState(() {
        _isEditing = false;
      });
    }
    // This setState will rebuild the scaffold, showing/hiding the FAB
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all your controllers
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveForm() async {
    // Your existing _saveForm logic remains here
    // ...
  }

  @override
  Widget build(BuildContext context) {
    String customerCode = widget.customer.customerCode!;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.customer.name ?? 'Customer Details'),
          actions: _buildAppBarActions(),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(FontAwesomeIcons.circleInfo), text: 'Details'),
              Tab(icon: Icon(FontAwesomeIcons.box), text: 'Orders'),
              Tab(icon: Icon(FontAwesomeIcons.fileInvoice), text: 'Invoices'),
              Tab(icon: Icon(FontAwesomeIcons.moneyBillWave), text: 'Cash Bills'),
              Tab(icon: Icon(FontAwesomeIcons.fileContract), text: 'Credit Notes'),
              Tab(icon: Icon(FontAwesomeIcons.book), text: 'Statement'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Details (with View/Edit mode)
            _buildDetailsTab(),

            // Other Tabs: Each is a dedicated list widget
            TransactionList<Order>(
              fetchData: () => _api.getOrdersForCustomer(customerCode: customerCode),
              itemBuilder: (order) => _OrderListItem(order: order),
              // Add the required fromJson function here
              fromJson: (json) => Order.fromJson(json),
            ),
            // invoice
            TransactionList<Invoice>(
              fetchData: () => _api.getInvoicesForCustomer(customerCode: customerCode, type: 'INV'),
              itemBuilder: (invoice) => _InvoiceListItem(invoice: invoice),
              // Add the required fromJson function here
              fromJson: (json) => Invoice.fromJson(json),
            ),
            // cash bill
            TransactionList<Invoice>(
              fetchData: () => _api.getInvoicesForCustomer(customerCode: customerCode, type: 'CS'),
              itemBuilder: (invoice) => _InvoiceListItem(invoice: invoice),
              // Add the required fromJson function here
              fromJson: (json) => Invoice.fromJson(json),
            ),
            // credit note
            TransactionList<Invoice>(
              fetchData: () => _api.getInvoicesForCustomer(customerCode: customerCode, type: 'CN'),
              itemBuilder: (invoice) => _InvoiceListItem(invoice: invoice),
              // Add the required fromJson function here
              fromJson: (json) => Invoice.fromJson(json),
            ),
            const Center(child: Text("Statement View - Coming Soon")),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_tabController.index == 0) {
      if (_isEditing) {
        return [
          IconButton(icon: const Icon(Icons.cancel_outlined), tooltip: 'Cancel', onPressed: _toggleEditMode),
          IconButton(icon: const Icon(Icons.save_alt_outlined), tooltip: 'Save', onPressed: _saveForm),
        ];
      } else {
        return [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Details',
            onPressed: () {
              Get.to(CustomerFormPage(customer: widget.customer));
            },
          ),
        ];
      }
    }
    return []; // No actions on other tabs for now
  }

  Widget? _buildFloatingActionButton() {
    if (_isSaving)
      return const FloatingActionButton(onPressed: null, child: CircularProgressIndicator(color: Colors.white));

    // Show FAB only on certain tabs and not while editing details
    if (_isEditing) return null;

    switch (_tabController.index) {
      case 1: // Orders
        return FloatingActionButton.extended(
          onPressed: () {
            /* Navigate to New Order Page */
          },
          label: const Text('New Order'),
          icon: const Icon(Icons.add),
        );
      case 2: // Invoices
        return FloatingActionButton.extended(
          onPressed: () {
            /* Navigate to New Invoice Page */
          },
          label: const Text('New Invoice'),
          icon: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  // --- TAB 1: DETAILS WIDGETS ---

  Widget _buildDetailsTab() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          _isEditing
              ? _buildEditForm() // Your existing form
              : _buildReadOnlyView(), // The new read-only view
    );
  }

  Widget _buildReadOnlyView() {
    return SingleChildScrollView(
      key: const ValueKey('readOnlyView'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Contact Information',
            icon: FontAwesomeIcons.addressBook,
            children: [
              _InfoTile(icon: FontAwesomeIcons.userTie, title: 'Code', subtitle: widget.customer.customerCode ?? 'N/A'),
              _InfoTile(icon: FontAwesomeIcons.userTie, title: 'Name', subtitle: widget.customer.name ?? 'N/A'),
              _InfoTile(
                icon: FontAwesomeIcons.userTie,
                title: 'Contact Person',
                subtitle: widget.customer.contactPerson ?? 'N/A',
              ),
              _InfoTile(icon: FontAwesomeIcons.envelope, title: 'Email', subtitle: widget.customer.email ?? 'N/A'),
              _InfoTile(
                icon: FontAwesomeIcons.phone,
                title: 'Primary Phone',
                subtitle: widget.customer.telephone1 ?? 'N/A',
              ),
              _InfoTile(icon: FontAwesomeIcons.fax, title: 'Fax', subtitle: widget.customer.faxNo ?? 'N/A'),
            ],
          ),
          _buildInfoCard(
            title: 'Address Information',
            icon: FontAwesomeIcons.mapLocationDot,
            children: [
              _InfoTile(
                icon: FontAwesomeIcons.building,
                title: 'Address',
                subtitle: widget.customer.address ?? '${widget.customer.address1}\n${widget.customer.address2}',
              ),
              _InfoTile(
                icon: FontAwesomeIcons.signsPost,
                title: 'Postcode & State',
                subtitle: '${widget.customer.postcode ?? ""} ${widget.customer.state ?? ""}',
              ),
            ],
          ),
          _buildInfoCard(
            title: 'Financial & Classification',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            children: [
              _InfoTile(
                icon: FontAwesomeIcons.handshake,
                title: 'Payment Term',
                subtitle: widget.customer.paymentTerm ?? 'N/A',
              ),
              _InfoTile(
                icon: FontAwesomeIcons.tags,
                title: 'Max Discount',
                subtitle: '${widget.customer.maxDiscount ?? "0"}%',
              ),
              _InfoTile(
                icon: FontAwesomeIcons.userGear,
                title: 'Customer Type',
                subtitle: widget.customer.customerType ?? 'N/A',
              ),
              _InfoTile(icon: FontAwesomeIcons.chartPie, title: 'Segment', subtitle: widget.customer.segment ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    // Your entire existing Form widget goes here
    return SingleChildScrollView(
      key: const ValueKey('editForm'),
      // padding and Form...
      child: Form(
        key: _formKey,
        // ... The rest of your form's Column and TextFormFields ...
        child: const Center(child: Text("Your Existing Form UI goes here")), // Replace with your form
      ),
    );
  }
}

// In CustomerDetailPage.dart

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: FaIcon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final Order order;
  const _OrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: FaIcon(FontAwesomeIcons.box, color: Theme.of(context).colorScheme.primary),
        title: Text('Order #${order.id}'),
        subtitle: Text('Date: ${DateFormat.yMMMd().format(order.orderDate!)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('RM ${order.netAmount}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(order.status ?? '', style: TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
        onTap: () {
          /* Navigate to Order Detail Page */
          Get.to(OrderFormPage(order: order));
          aLog('x');
        },
      ),
    );
  }
}

// Replace the old _InvoiceListItem with this new one

class _InvoiceListItem extends StatelessWidget {
  final Invoice invoice; // CHANGED: Now accepts the correct Invoice model
  const _InvoiceListItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: FaIcon(FontAwesomeIcons.fileInvoice, color: Theme.of(context).colorScheme.secondary),
        // CHANGED: Display refNo instead of id
        title: Text('Invoice #${invoice.refNo ?? 'N/A'}'),
        // CHANGED: Use the correct date field and format it
        subtitle: Text('Date: ${invoice.date != null ? DateFormat.yMMMd().format(invoice.date!) : 'N/A'}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // CHANGED: Use the netBil field for the amount
            Text(
              'RM ${invoice.netBil.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            // CHANGED: Display the string status in a Chip for better UI
            _StatusChip(status: invoice.status),
          ],
        ),
        onTap: () {
          /* Navigate to the actual Invoice Detail Page */
          Get.to(InvoiceFormPage(invoice: invoice));
        },
      ),
    );
  }
}

// NEW HELPER WIDGET for displaying status consistently
class _StatusChip extends StatelessWidget {
  final String? status;
  const _StatusChip({this.status});

  @override
  Widget build(BuildContext context) {
    final s = status?.toLowerCase() ?? 'unknown';
    Color color = Colors.grey;
    if (s == 'paid' || s == 'completed') {
      color = Colors.green;
    } else if (s == 'pending' || s == 'unpaid') {
      color = Colors.orange;
    } else if (s == 'overdue') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(
        s.capitalizeFirst ?? 'Unknown',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// You can now DELETE the old _getStatusColor helper function, as it is no longer used.
/*
Color _getStatusColor(TransactionStatus status) { // <-- DELETE THIS
  // ...
}
*/

// Helper to get color for status
Color _getStatusColor(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.Pending:
      return Colors.orange;
    case TransactionStatus.Completed:
      return Colors.green;
    case TransactionStatus.Cancelled:
      return Colors.grey;
    case TransactionStatus.Overdue:
      return Colors.red;
    default:
      return Colors.black;
  }
}
