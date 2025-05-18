class Customer {
  final String? id; // API might return int, ensure fromJson handles it.
  final String? customerCode;
  final String?
  name; // A general name field, distinct from companyName if needed.
  final String? companyName;
  final String? address; // A general address field.
  final String? address1; // Specific address line 1.
  final String? address2; // Specific address line 2.
  final String? postcode;
  final String? state;
  final String? territory;
  final String? telephone1;
  final String? telephone2;
  final String? faxNo;
  final String? contactPerson;
  final String? customerGroup;
  final String? customerType; // From detailed form / API
  final String? lotType;
  final String? segment; // From detailed form
  final String? paymentType; // From detailed form
  final String? paymentTerm; // From detailed form
  final String? maxDiscount; // From detailed form
  final String? email;
  final String? phone;
  final String? avatarUrl;

  Customer({
    this.id,
    this.customerCode,
    this.name,
    this.companyName,
    this.address,
    this.address1,
    this.address2,
    this.postcode,
    this.state,
    this.territory,
    this.telephone1,
    this.telephone2,
    this.faxNo,
    this.contactPerson,
    this.customerGroup,
    this.customerType,
    this.lotType,
    this.segment,
    this.paymentType,
    this.paymentTerm,
    this.maxDiscount,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      // API might send 'id' as int, convert to String if needed, or handle as int.
      // If your API consistently sends String ID, `json['id'] as String?` is fine.
      // If it can be int or String, more robust parsing is needed.
      id: json['id']?.toString(), // Safely convert to String if not null
      customerCode:
          json['customer_code'] as String?, // API often uses snake_case
      name: json['name'] as String?,
      companyName: json['company_name'] as String?,
      address: json['address'] as String?, // General address field
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      postcode: json['postcode'] as String?,
      state: json['state'] as String?,
      territory: json['territory'] as String?,
      telephone1: json['telephone1'] as String?,
      telephone2: json['telephone2'] as String?,
      faxNo: json['fax_no'] as String?,
      contactPerson: json['contact_person'] as String?,
      customerGroup: json['customer_group'] as String?,
      customerType:
          json['customer_type'] as String?, // Field from detailed form
      lotType: json['lot_type'] as String?,
      segment: json['segment'] as String?, // Field from detailed form
      paymentType: json['payment_type'] as String?, // Field from detailed form
      paymentTerm: json['payment_term'] as String?, // Field from detailed form
      maxDiscount: json['max_discount']?.toString(), // API might send as number
      email: json['email'] as String?,
      phone:
          json['phone']
              as String?, // API might use 'telephone1' or a specific 'phone' field
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  // Method to convert Customer object to a Map for API calls (e.g., create/update)
  // Ensure keys match what your API expects (e.g., snake_case if Laravel backend expects that)
  // The Laravel controller in the canvas currently expects camelCase based on its validation.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_code':
          customerCode, // Or 'customerCode' if API expects camelCase
      'name': name,
      'company_name': companyName, // Or 'companyName'
      'address': address,
      'address1': address1,
      'address2': address2,
      'postcode': postcode,
      'state': state,
      'territory': territory,
      'telephone1': telephone1,
      'telephone2': telephone2,
      'fax_no': faxNo, // Or 'faxNo'
      'contact_person': contactPerson, // Or 'contactPerson'
      'customer_group': customerGroup, // Or 'customerGroup'
      'customer_type': customerType, // Or 'customerType'
      'lot_type': lotType, // Or 'lotType'
      'segment': segment,
      'payment_type': paymentType, // Or 'paymentType'
      'payment_term': paymentTerm, // Or 'paymentTerm'
      'max_discount': maxDiscount, // Or 'maxDiscount'
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl, // Or 'avatarUrl'
    };
  }
}
