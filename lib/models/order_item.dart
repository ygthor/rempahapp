class OrderItem {
  final String productId;
  final String productName;
  final String skuCode;
  double quantity;
  double unitPrice;
  double discount; // Could be a percentage or a fixed amount
  bool isFreeGood;
  // Trade Return specific fields
  bool isTradeReturn;
  bool
  tradeReturnIsGood; // true if Good, false if Bad (only if isTradeReturn is true)

  OrderItem({
    required this.productId,
    required this.productName,
    required this.skuCode,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.isFreeGood = false,
    this.isTradeReturn = false,
    this.tradeReturnIsGood = true, // Default to good if it's a return
  });

  double get amount {
    if (isFreeGood) return 0.0;
    return (quantity * unitPrice) - discountValue;
  }

  double get discountValue {
    // Assuming discount is a fixed amount for simplicity here.
    // If it's a percentage, the calculation would be (quantity * unitPrice * discount / 100)
    return discount;
  }
}
