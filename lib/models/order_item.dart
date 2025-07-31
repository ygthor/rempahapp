class OrderItem {
  final String? id;
  final String? uniqueKey;
  final String? referenceNo;
  final int? itemCount;
  final String? productId;
  final String? productNo;
  final String? productName;
  final String? description;
  final String? skuCode;
  final String? unit;
  final double? quantity;
  final double? unitPrice;
  final double? discount;
  final double? amount;
  final bool? isFreeGood;
  final bool? isTradeReturn;
  final bool? tradeReturnIsGood;

  OrderItem({
    this.id,
    this.uniqueKey,
    this.referenceNo,
    this.itemCount,
    this.productId,
    this.productNo,
    this.productName,
    this.description,
    this.skuCode,
    this.unit,
    this.quantity,
    this.unitPrice,
    this.discount,
    this.amount,
    this.isFreeGood,
    this.isTradeReturn,
    this.tradeReturnIsGood,
  });

  /// Safe fallback if [amount] is null.
  double get calculatedAmount {
    if (isFreeGood == true) return 0.0;
    final qty = quantity ?? 0.0;
    final price = unitPrice ?? 0.0;
    final disc = discount ?? 0.0;
    return (qty * price) - disc;
  }

  Map<String, dynamic> toJson() {
    return {
      if (uniqueKey != null) 'unique_key': uniqueKey,
      if (referenceNo != null) 'reference_no': referenceNo,
      if (itemCount != null) 'item_count': itemCount,
      if (productId != null) 'product_id': productId,
      if (productNo != null) 'product_no': productNo,
      if (productName != null) 'product_name': productName,
      if (description != null) 'description': description,
      if (skuCode != null) 'sku_code': skuCode,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (discount != null) 'discount': discount,
      'amount': amount ?? calculatedAmount,
      if (isFreeGood != null) 'is_free_good': isFreeGood,
      if (isTradeReturn != null) 'is_trade_return': isTradeReturn,
      if (tradeReturnIsGood != null) 'trade_return_is_good': tradeReturnIsGood,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderItem(
      id: json['id']?.toString(),
      uniqueKey: json['unique_key'],
      referenceNo: json['reference_no'],
      itemCount: json['item_count'],
      productId: json['product_id']?.toString(),
      productNo: json['product_no'],
      productName: json['product_name'],
      description: json['description'],
      skuCode: json['sku_code'],
      unit: json['unit'],
      quantity: parseDouble(json['quantity']),
      unitPrice: parseDouble(json['unit_price']),
      discount: parseDouble(json['discount']),
      amount: parseDouble(json['amount']),
      isFreeGood: json['is_free_good'] == 1 || json['is_free_good'] == true,
      isTradeReturn:
          json['is_trade_return'] == 1 || json['is_trade_return'] == true,
      tradeReturnIsGood:
          json['trade_return_is_good'] == null
              ? null
              : json['trade_return_is_good'] == 1 ||
                  json['trade_return_is_good'] == true,
    );
  }
}
