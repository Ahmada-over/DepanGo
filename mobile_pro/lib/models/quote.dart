class QuoteItem {
  final String? id;
  final String description;
  final String category; // labor, material, travel
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  QuoteItem({
    this.id,
    required this.description,
    required this.category,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'labor',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

class Quote {
  final String? id;
  final String bookingId;
  final String quoteType; // remote_estimate, on_site_quote
  final double totalLabor;
  final double totalMaterials;
  final double totalTravel;
  final double grandTotal;
  final String? estimatedDuration;
  final String? notes;
  final String status;
  final List<QuoteItem> items;

  Quote({
    this.id,
    required this.bookingId,
    required this.quoteType,
    this.totalLabor = 0.0,
    this.totalMaterials = 0.0,
    this.totalTravel = 0.0,
    this.grandTotal = 0.0,
    this.estimatedDuration,
    this.notes,
    this.status = 'draft',
    required this.items,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<QuoteItem> itemsList = list.map((i) => QuoteItem.fromJson(i)).toList();

    return Quote(
      id: json['id'],
      bookingId: json['booking_id'] ?? '',
      quoteType: json['quote_type'] ?? 'on_site_quote',
      totalLabor: (json['total_labor'] ?? 0).toDouble(),
      totalMaterials: (json['total_materials'] ?? 0).toDouble(),
      totalTravel: (json['total_travel'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      estimatedDuration: json['estimated_duration'],
      notes: json['notes'],
      status: json['status'] ?? 'draft',
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'quote_type': quoteType,
      'total_labor': totalLabor,
      'total_materials': totalMaterials,
      'total_travel': totalTravel,
      'grand_total': grandTotal,
      'estimated_duration': estimatedDuration,
      'notes': notes,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
