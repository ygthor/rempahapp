class Customer {
  final String? id;
  final String? customerCode; // Maps to 'Customer Code' field
  final String? name; // Maps to 'Customer Code' field
  final String? companyName;
  final String? address;
  final String? customerType;
  final String? segment;
  final String? paymentType;
  final String? paymentTerm;
  final String? maxDiscount; // Consider using double if it's a numerical value
  // Fields from your original controllers, add them to the form if needed
  final String? email;
  final String? phone;
  final String? avatarUrl;

  Customer({
    this.id,
    this.customerCode,
    this.name,
    this.companyName,
    this.address,
    this.customerType,
    this.segment,
    this.paymentType,
    this.paymentTerm,
    this.maxDiscount,
    this.email,
    this.phone,
    this.avatarUrl,
  });
}
