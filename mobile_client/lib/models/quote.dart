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
}

class Quote {
  final String id;
  final String bookingId;
  final String technicianId;
  final String clientId;
  final String quoteType; // remote_estimate | on_site_quote
  final String status; // draft | pending_client_approval | accepted | rejected
  final double totalLabor;
  final double totalMaterials;
  final double totalTravel;
  final double grandTotal;
  final String? estimatedDuration;
  final String? notes;
  final DateTime createdAt;
  final List<QuoteItem> items;

  Quote({
    required this.id,
    required this.bookingId,
    required this.technicianId,
    required this.clientId,
    required this.quoteType,
    required this.status,
    this.totalLabor = 0.0,
    this.totalMaterials = 0.0,
    this.totalTravel = 0.0,
    this.grandTotal = 0.0,
    this.estimatedDuration,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    final items = list.map((i) => QuoteItem.fromJson(i)).toList();
    return Quote(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      technicianId: json['technician_id'] ?? '',
      clientId: json['client_id'] ?? '',
      quoteType: json['quote_type'] ?? 'on_site_quote',
      status: json['status'] ?? 'draft',
      totalLabor: (json['total_labor'] ?? 0).toDouble(),
      totalMaterials: (json['total_materials'] ?? 0).toDouble(),
      totalTravel: (json['total_travel'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      estimatedDuration: json['estimated_duration'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: items,
    );
  }

  String get quoteTypeLabel {
    switch (quoteType) {
      case 'remote_estimate':
        return 'Estimation à distance';
      case 'on_site_quote':
        return 'Devis sur place';
      default:
        return quoteType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'pending_client_approval':
        return 'En attente de votre réponse';
      case 'accepted':
        return 'Accepté';
      case 'rejected':
        return 'Refusé';
      default:
        return status;
    }
  }
}
