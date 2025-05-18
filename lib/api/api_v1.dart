// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:rempahapp/models/global_state.dart';
import 'dart:convert';
import '../shared/shared.dart';

class ApiV1 {
  String? bearerToken;

  ApiV1({this.bearerToken});

  Uri _parseUri(String path) {
    String domain = appDomain();
    // return Uri.https(domain, path); // AI please dont change this, for dev purpose
    return Uri.http(domain, path);
  }

  // --- HTTP Helper Methods ---
  Future<http.Response> _httpGet(Uri actionUrl) async {
    return http.get(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );
  }

  Future<http.Response> _httpPost(
    Uri actionUrl, {
    Map<String, dynamic>? body,
  }) async {
    return http.post(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8', // Added Content-Type
        'Authorization': 'Bearer $bearerToken',
      },
      body: body != null ? json.encode(body) : null, // Encode body to JSON
    );
  }

  Future<http.Response> _httpPut(
    Uri actionUrl, {
    Map<String, dynamic>? body,
  }) async {
    return http.put(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8', // Added Content-Type
        'Authorization': 'Bearer $bearerToken',
      },
      body: body != null ? json.encode(body) : null, // Encode body to JSON
    );
  }

  Future<http.Response> _httpDelete(Uri actionUrl) async {
    return http.delete(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );
  }

  // --- Authentication Methods (Existing) ---
  login(String username, String password) async {
    Uri actionUrl = _parseUri('/api/auth/token'); // Path for login

    final response = await http.post(
      // Using http.post directly as it doesn't need bearer token initially
      actionUrl,
      headers: {
        'Accept': 'application/json',
      }, // No bearer token for login itself
      body: {"identifier": username, "password": password},
    );
    var result = json.decode(response.body);
    return result;
  }

  register(String email, String username) async {
    Uri actionUrl = _parseUri('/api/v1/register'); // Adjust path if needed

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"email": email, "username": username},
    );
    var result = json.decode(response.body);
    return result;
  }

  logout({String? token, String? device_token}) async {
    Uri actionUrl = _parseUri('/api/v1/logout'); // Adjust path if needed

    final response = await _httpPost(
      // Assuming logout requires bearer token
      actionUrl,
      body: {"token": token, "device_token": device_token},
    );
    var result = json.decode(response.body);
    return result;
  }

  getUser() async {
    Uri actionUrl = _parseUri('/api/me'); // Path for getting user info
    aLog(actionUrl);

    final response = await _httpGet(actionUrl); // Changed to _httpGet
    aLog("GetUser Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Server Error ${response.statusCode}',
        text: 'Could not fetch user data. ${response.reasonPhrase}',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  // --- Customer API Methods ---

  /// Fetches all customers.
  Future<dynamic> getAllCustomers() async {
    Uri actionUrl = _parseUri('/api/customers');
    try {
      final response = await _httpGet(actionUrl);
      aLog(
        "GetAllCustomers Response: ${response.statusCode} - ${response.body}",
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showVDialog(
          title: 'API Error (${response.statusCode})',
          text: 'Failed to fetch customers: ${response.reasonPhrase}',
        );
        return {
          'error': true,
          'message': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      aLog("GetAllCustomers Exception: $e");
      showVDialog(
        title: 'Network Error',
        text: 'Could not connect to server: $e',
      );
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Creates a new customer.
  /// The `customerData` map should contain all necessary fields for creating a customer,
  /// matching either the "Original Form" or "Detailed Form" structure from your Postman collection.
  Future<Map<String, dynamic>?> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    Uri actionUrl = _parseUri('/api/customers');
    try {
      final response = await _httpPost(actionUrl, body: customerData);
      aLog(
        "CreateCustomer Response: ${response.statusCode} - ${response.body}",
      );
      // Successful creation is often 201
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showVDialog(
          title: 'API Error (${response.statusCode})',
          text: 'Failed to create customer: ${response.reasonPhrase}',
        );
        return {
          'error': true,
          'message': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      aLog("CreateCustomer Exception: $e");
      showVDialog(
        title: 'Network Error',
        text: 'Could not connect to server: $e',
      );
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Fetches a specific customer by their ID.
  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    Uri actionUrl = _parseUri('/api/customers/$customerId');
    try {
      final response = await _httpGet(actionUrl);
      aLog(
        "GetCustomerById Response: ${response.statusCode} - ${response.body}",
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showVDialog(
          title: 'API Error (${response.statusCode})',
          text:
              'Failed to fetch customer $customerId: ${response.reasonPhrase}',
        );
        return {
          'error': true,
          'message': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      aLog("GetCustomerById Exception: $e");
      showVDialog(
        title: 'Network Error',
        text: 'Could not connect to server: $e',
      );
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Updates an existing customer.
  /// The `customerData` map should contain the fields to be updated.
  Future<Map<String, dynamic>?> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
  ) async {
    Uri actionUrl = _parseUri('/api/customers/$customerId');
    try {
      final response = await _httpPut(actionUrl, body: customerData);
      aLog(
        "UpdateCustomer Response: ${response.statusCode} - ${response.body}",
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showVDialog(
          title: 'API Error (${response.statusCode})',
          text:
              'Failed to update customer $customerId: ${response.reasonPhrase}',
        );
        return {
          'error': true,
          'message': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      aLog("UpdateCustomer Exception: $e");
      showVDialog(
        title: 'Network Error',
        text: 'Could not connect to server: $e',
      );
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Deletes a customer by their ID.
  Future<Map<String, dynamic>?> deleteCustomer(String customerId) async {
    Uri actionUrl = _parseUri('/api/customers/$customerId');
    try {
      final response = await _httpDelete(actionUrl);
      aLog(
        "DeleteCustomer Response: ${response.statusCode} - ${response.body}",
      );
      // Successful deletion can be 200 with a message or 204 No Content
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          return json.decode(response.body);
        }
        return {'success': true, 'message': 'Customer deleted successfully.'};
      } else {
        showVDialog(
          title: 'API Error (${response.statusCode})',
          text:
              'Failed to delete customer $customerId: ${response.reasonPhrase}',
        );
        return {
          'error': true,
          'message': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      aLog("DeleteCustomer Exception: $e");
      showVDialog(
        title: 'Network Error',
        text: 'Could not connect to server: $e',
      );
      return {'error': true, 'message': e.toString()};
    }
  }
} //end of ApiV1 Class
