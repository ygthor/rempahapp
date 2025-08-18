// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart'; // Assuming GetX is used for showVDialog or other utilities
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rempahapp/models/global_state.dart'; // Assuming this is the correct path
import 'dart:convert';
import '../shared/shared.dart'; // Assuming this is the correct path for appDomain, aLog, showVDialog

// Placeholder for shared utility functions if not using GetX or similar
// Replace these with your actual implementations if they are not part of GetX
// String appDomain() { // Already defined in user's shared.dart presumably
//   return "10.0.2.2:8000";
// }

// void aLog(String message) { // Already defined in user's shared.dart presumably
//   print("LOG: $message");
// }

// void showVDialog({required String title, required String text}) { // Already defined in user's shared.dart presumably
//   print("Dialog: $title - $text");
//   if (Get.isSnackbarOpen ?? false) {
//     Get.closeCurrentSnackbar();
//   }
//   Get.defaultDialog(title: title, middleText: text, barrierDismissible: true);
// }

class ApiV1 {
  String? bearerToken;

  ApiV1({this.bearerToken});

  // Updated _parseUri to correctly handle query parameters
  Uri _parseUri(String path, {Map<String, dynamic>? queryParameters}) {
    String domain = appDomain();
    // Convert queryParameters to Map<String, String> if not null
    Map<String, String>? stringQueryParameters;
    if (queryParameters != null) {
      stringQueryParameters = queryParameters.map(
        (key, value) => MapEntry(key, value.toString()), // Ensure values are strings
      );
    }

    // User specified Uri.http for development
    if (domain.contains(':')) {
      // Likely includes port, good for http
      return Uri.http(domain, path, stringQueryParameters);
    }
    // Fallback for https if domain doesn't specify port
    return Uri.https(domain, path, stringQueryParameters);
  }

  // --- HTTP Helper Methods ---
  Future<http.Response> _httpGet(Uri actionUrl) async {
    aLog("GET Request to: $actionUrl");
    // aLog("Bearer Token: $bearerToken");
    return http.get(actionUrl, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $bearerToken'});
  }

  Future<http.Response> _httpPost(Uri actionUrl, {Map<String, dynamic>? body}) async {
    aLog("POST Request to: $actionUrl");
    aLog("Body: ${json.encode(body)}");
    // aLog("Bearer Token: $bearerToken");
    return http.post(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      },
      body: body != null ? json.encode(body) : null,
    );
  }

  Future<http.Response> _httpPut(Uri actionUrl, {Map<String, dynamic>? body}) async {
    aLog("PUT Request to: $actionUrl");
    aLog("Body: ${json.encode(body)}");
    aLog("Bearer Token: $bearerToken");
    return http.put(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      },
      body: body != null ? json.encode(body) : null,
    );
  }

  Future<http.Response> _httpDelete(Uri actionUrl) async {
    aLog("DELETE Request to: $actionUrl");
    aLog("Bearer Token: $bearerToken");
    return http.delete(actionUrl, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $bearerToken'});
  }

  // --- Authentication Methods (Existing) ---
  login(String username, String password) async {
    Uri actionUrl = _parseUri('/api/auth/token');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"identifier": username, "password": password},
    );
    var result = json.decode(response.body);
    return result;
  }

  // ... (other auth methods remain the same) ...
  register(String email, String username) async {
    Uri actionUrl = _parseUri('/api/v1/register');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"email": email, "username": username},
    );
    return json.decode(response.body);
  }

  logout({String? token, String? device_token}) async {
    Uri actionUrl = _parseUri('/api/v1/logout');
    final response = await _httpPost(actionUrl, body: {"token": token, "device_token": device_token});
    return json.decode(response.body);
  }

  getUser() async {
    Uri actionUrl = _parseUri('/api/me');
    final response = await _httpGet(actionUrl);
    if (response.statusCode != 200) {
      showVDialog(
        title: 'Server Error ${response.statusCode}',
        text: 'Could not fetch user data. ${response.reasonPhrase}',
      );
      return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
    }
    return json.decode(response.body);
  }

  getDashboard({String? date_from, String? date_to}) async {
    GlobalState gs = Get.find();
    String selectedBranch = gs.selectedBranch ?? '';
    Uri actionUrl = _parseUri(
      '/api/dashboard',
      queryParameters: {
        'branchId': selectedBranch,
        if (date_from != null) 'date_from': date_from,
        if (date_to != null) 'date_to': date_to,
      },
    );
    final response = await _httpGet(actionUrl);
    if (response.statusCode != 200) {
      showVDialog(
        title: 'Server Error ${response.statusCode}',
        text: 'Could not fetch dashboard data. ${response.reasonPhrase}',
      );
      return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
    }
    return json.decode(response.body);
  }

  // --- Customer API Methods (Existing) ---

  Future<dynamic> getAllCustomers() async {
    // Renaming to getCustomers to avoid conflict with the one from the user's latest prompt
    return getCustomers();
  }

  Future<dynamic> getCustomers() async {
    Uri actionUrl = _parseUri('/api/customers');
    try {
      final response = await _httpGet(actionUrl);
      aLog("getCustomers Response: ${response.statusCode} - ${response.body}");
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      if (response.statusCode >= 400) {
        return {
          'error': true,
          'message': 'Error: ${response.statusCode} ${response.reasonPhrase}',
          'statusCode': response.statusCode,
        };
      }
      return null;
    } catch (e) {
      aLog("getCustomers Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not connect to server: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> createCustomer(Map<String, dynamic> customerData) async {
    Uri actionUrl = _parseUri('/api/customers');
    try {
      final response = await _httpPost(actionUrl, body: customerData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    Uri actionUrl = _parseUri('/api/customers/$customerId');
    try {
      final response = await _httpGet(actionUrl);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> updateCustomer(String customerId, Map<String, dynamic> customerData) async {
    Uri actionUrl = _parseUri('/api/customers/$customerId');
    try {
      final response = await _httpPut(actionUrl, body: customerData);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> deleteCustomer(String customerId) async {
    Uri actionUrl = _parseUri('/api/customers/$customerId');
    try {
      final response = await _httpDelete(actionUrl);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? json.decode(response.body)
            : {'success': true, 'message': 'Customer deleted successfully.'};
      } else {
        return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // --- Product API Methods (Existing) ---
  Future<dynamic> getProducts() async {
    GlobalState gs = Get.find();
    String selectedBranch = gs.selectedBranch ?? '';
    Uri actionUrl = _parseUri('/api/products', queryParameters: {'branchId': selectedBranch});
    try {
      final response = await _httpGet(actionUrl);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // --- ICITEM API Methods (Existing) ---
  Future<dynamic> getIcitem() async {
    GlobalState gs = Get.find();
    String selectedBranch = gs.selectedBranch ?? '';
    Uri actionUrl = _parseUri('/api/icitem', queryParameters: {'branchId': selectedBranch});
    try {
      final response = await _httpGet(actionUrl);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> productData) async {
    Uri actionUrl = _parseUri('/api/products');
    try {
      final response = await _httpPost(actionUrl, body: productData);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // --- Receipt API Methods (NEW) ---

  /// Fetches all receipts, with optional filters.
  Future<Map<String, dynamic>?> getAllReceipts({
    int page = 1,
    int perPage = 15,
    String? customerId,
    String? dateFrom,
    String? dateTo,
  }) async {
    Map<String, dynamic> queryParameters = {'page': page.toString(), 'per_page': perPage.toString()};
    if (customerId != null) queryParameters['customer_id'] = customerId;
    if (dateFrom != null) queryParameters['date_from'] = dateFrom;
    if (dateTo != null) queryParameters['date_to'] = dateTo;

    Uri actionUrl = _parseUri('/api/receipts', queryParameters: queryParameters);
    try {
      final response = await _httpGet(actionUrl);
      aLog("GetAllReceipts Response: ${response.statusCode} - ${response.body}");
      if (response.body.isNotEmpty) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      aLog("GetAllReceipts Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not connect to server for receipts: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Creates a new receipt.
  Future<Map<String, dynamic>?> createReceipt(Map<String, dynamic> receiptData) async {
    Uri actionUrl = _parseUri('/api/receipts');
    try {
      final response = await _httpPost(actionUrl, body: receiptData);
      aLog("CreateReceipt Response: ${response.statusCode} - ${response.body}");
      return response.body.isNotEmpty ? json.decode(response.body) as Map<String, dynamic> : null;
    } catch (e) {
      aLog("CreateReceipt Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not create receipt: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Updates an existing receipt.
  Future<Map<String, dynamic>?> updateReceipt(int receiptId, Map<String, dynamic> receiptData) async {
    Uri actionUrl = _parseUri('/api/receipts/$receiptId');
    try {
      final response = await _httpPut(actionUrl, body: receiptData);
      aLog("UpdateReceipt Response: ${response.statusCode} - ${response.body}");
      return response.body.isNotEmpty ? json.decode(response.body) as Map<String, dynamic> : null;
    } catch (e) {
      aLog("UpdateReceipt Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not update receipt: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Deletes a receipt by its ID.
  Future<Map<String, dynamic>?> deleteReceipt(String receiptId) async {
    Uri actionUrl = _parseUri('/api/receipts/$receiptId');
    try {
      final response = await _httpDelete(actionUrl);
      aLog("DeleteReceipt Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? json.decode(response.body)
            : {'success': true, 'message': 'Receipt deleted successfully.'};
      } else {
        return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
      }
    } catch (e) {
      aLog("DeleteReceipt Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not delete receipt: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getDebts({String? searchTerm}) async {
    Map<String, dynamic> queryParameters = {};
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParameters['search'] = searchTerm;
    }

    Uri actionUrl = _parseUri('/api/debts', queryParameters: queryParameters);
    try {
      final response = await _httpGet(actionUrl);
      aLog("GetDebts Response: ${response.statusCode} - ${response.body}");
      if (response.body.isNotEmpty) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      aLog("GetDebts Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not fetch debt information: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getInventory({String? groupId, String? subGroupId, String? inventoryType}) async {
    Map<String, dynamic> queryParameters = {
      'groupId': groupId,
      'subGroupId': subGroupId,
      'inventoryType': inventoryType,
    };

    Uri actionUrl = _parseUri('/api/inventory', queryParameters: queryParameters);
    try {
      final response = await _httpGet(actionUrl);
      aLog("GetInventory Response: ${response.statusCode} - ${response.body}");
      if (response.body.isNotEmpty) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      aLog("GetInventory Exception: $e");
      showVDialog(title: 'Network Error', text: 'Could not fetch inventory: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  // --- Order API Methods (Existing) ---
  Future<Map<String, dynamic>?> getAllOrders({
    int page = 1,
    int perPage = 15,
    String? customerCode, // New parameter
    String? customerName, // New parameter
    DateTime? startDate, // New parameter
    DateTime? endDate, // New parameter
    List<String>? orderTypes, // New parameter
  }) async {
    // Build the query parameters map
    final Map<String, dynamic> queryParams = {'page': page.toString(), 'per_page': perPage.toString()};
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['customer_code'] = customerCode;
    }
    if (customerName != null && customerName.isNotEmpty) {
      queryParams['customer_name'] = customerName;
    }
    if (startDate != null) {
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    }
    if (orderTypes != null && orderTypes.isNotEmpty) {
      queryParams['order_type'] = orderTypes.join(','); // Or however your API expects a list
    }

    Uri actionUrl = _parseUri('/api/orders', queryParameters: queryParams);

    try {
      final response = await _httpGet(actionUrl);
      if (response.body.isNotEmpty) {
        // ... (existing parsing logic)
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> createOrder(Map<String, dynamic> orderData) async {
    Uri actionUrl = _parseUri('/api/orders');
    try {
      final response = await _httpPost(actionUrl, body: orderData);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> updateOrder(Map<String, dynamic> orderData) async {
    Uri actionUrl = _parseUri('/api/orders/' + orderData['id']);
    try {
      final response = await _httpPut(actionUrl, body: orderData);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // ... (other order methods remain the same) ...
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    Uri actionUrl = _parseUri('/api/orders/$orderId');
    try {
      final response = await _httpGet(actionUrl);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> createOrderItem(Map<String, dynamic> orderData) async {
    Uri actionUrl = _parseUri('/api/orders-items');
    try {
      final response = await _httpPost(actionUrl, body: orderData);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // ... (other order methods remain the same) ...
  Future<Map<String, dynamic>?> getOrderItemById(String orderId) async {
    Uri actionUrl = _parseUri('/api/orders/$orderId');
    try {
      final response = await _httpGet(actionUrl);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> deleteOrderItem(String orderItemId) async {
    Uri actionUrl = _parseUri('/api/orders-items/$orderItemId');
    try {
      final response = await _httpDelete(actionUrl);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // ... inside your ApiV1 class

  // --- Invoice (Artran) API Methods ---

  /// Fetches a paginated list of invoices.
  Future<Map<String, dynamic>?> getAllInvoices({
    int page = 1,
    int perPage = 15,
    String? customerCode,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? invoiceTypes,
    String? invoiceType,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page.toString(), 'per_page': perPage.toString()};

    if (customerName != null && customerName.isNotEmpty) {
      queryParams['customer_name'] = customerName;
    }
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['CUSTNO'] = customerCode;
    }
    if (startDate != null) {
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    }
    if (invoiceType != null && invoiceType.isNotEmpty) {
      queryParams['invoice_type'] = invoiceType;
    }
    if (invoiceTypes != null && invoiceTypes.isNotEmpty) {
      queryParams['invoice_type'] = invoiceTypes.join(',');
    }
    Uri actionUrl = _parseUri('/api/invoices', queryParameters: queryParams);
    try {
      final response = await _httpGet(actionUrl);
      return _handleResponse(response);
    } catch (e) {
      aLog("getAllInvoices Exception: $e");
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getInvoiceByRefNo(String refNo) async {
    Uri actionUrl = _parseUri('/api/invoices/$refNo');
    try {
      final response = await _httpGet(actionUrl);
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Creates a new invoice header.
  Future<Map<String, dynamic>?> createInvoice(Map<String, dynamic> invoiceData) async {
    Uri actionUrl = _parseUri('/api/invoices');
    try {
      final response = await _httpPost(actionUrl, body: invoiceData);
      return _handleResponse(response);
    } catch (e) {
      aLog("createInvoice Exception: $e");
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Updates an existing invoice header.
  Future<Map<String, dynamic>?> updateInvoice(String? refNo, Map<String, dynamic> invoiceData) async {
    Uri actionUrl = _parseUri('/api/invoices/$refNo');
    try {
      final response = await _httpPut(actionUrl, body: invoiceData);
      return _handleResponse(response);
    } catch (e) {
      aLog("updateInvoice Exception: $e");
      return {'error': true, 'message': e.toString()};
    }
  }

  // --- Invoice Item (ArTransItem) API Methods ---

  /// Creates a new item and adds it to an existing invoice.
  Future<Map<String, dynamic>?> createInvoiceItem(Map<String, dynamic> itemData) async {
    // The endpoint for managing individual items
    Uri actionUrl = _parseUri('/api/invoices-items');
    try {
      final response = await _httpPost(actionUrl, body: itemData);
      return _handleResponse(response);
    } catch (e) {
      aLog("createInvoiceItem Exception: $e");
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Deletes an item from an invoice.
  Future<Map<String, dynamic>?> deleteInvoiceItem(int itemId) async {
    Uri actionUrl = _parseUri('/api/invoices-items/$itemId');
    try {
      final response = await _httpDelete(actionUrl);
      // Handle successful empty response for deletes
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? json.decode(response.body)
            : {'success': true, 'message': 'Item deleted successfully.'};
      }
      return _handleResponse(response);
    } catch (e) {
      aLog("deleteInvoiceItem Exception: $e");
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> updateInvoiceItem(String? refNo, Map<String, dynamic> invoiceData) async {
    Uri actionUrl = _parseUri('/api/invoices-items/$refNo');
    try {
      final response = await _httpPut(actionUrl, body: invoiceData);
      return _handleResponse(response);
    } catch (e) {
      aLog("updateInvoice Exception: $e");
      return {'error': true, 'message': e.toString()};
    }
  }

  // --- Generic Response Handler ---
  Map<String, dynamic>? _handleResponse(http.Response response) {
    aLog("Response: ${response.statusCode} - ${response.body}");
    if (response.body.isNotEmpty) {
      final decodedBody = json.decode(response.body);
      if (decodedBody is Map<String, dynamic>) {
        // Check for backend-specific error flags if any
        if (decodedBody['error'] == true || decodedBody['error'] == 1) {
          showVDialog(title: "API Error", text: decodedBody['message'] ?? 'An unknown error occurred.');
          return decodedBody;
        }
        return decodedBody;
      }
    }
    if (response.statusCode >= 400) {
      showVDialog(
        title: 'Error ${response.statusCode}',
        text: response.reasonPhrase ?? 'An unknown server error occurred.',
      );
      return {'error': true, 'message': response.body, 'statusCode': response.statusCode};
    }
    return null;
  }

  Future<Map<String, dynamic>?> getOrdersForCustomer({customerCode, type}) {
    return getAllOrders(customerCode: customerCode, orderTypes: type);
  }

  Future<Map<String, dynamic>?> getInvoicesForCustomer({customerCode, type}) {
    return getAllInvoices(customerCode: customerCode, invoiceType: type);
  }
} //end of ApiV1 Class
