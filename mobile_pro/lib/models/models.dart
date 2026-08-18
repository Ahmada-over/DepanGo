class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? json['user_name'] ?? 'Technicien',
      phone: json['phone'] ?? json['user_phone'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'technician',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'role': role,
  };
}

class TechnicianProfileModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<String> categoryIds;
  final String transportMode;
  final String availabilityStatus; // 'online' | 'offline' | 'busy'
  final double averageRating;
  final double? latitude;
  final double? longitude;
  final bool verified;

  TechnicianProfileModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.categoryIds,
    required this.transportMode,
    required this.availabilityStatus,
    required this.averageRating,
    this.latitude,
    this.longitude,
    required this.verified,
  });

  factory TechnicianProfileModel.fromJson(Map<String, dynamic> json) {
    return TechnicianProfileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['name'] ?? json['user_name'] ?? 'Technicien',
      userPhone: json['phone'] ?? json['user_phone'] ?? '',
      categoryIds: (json['category_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['cat_plumbing', 'cat_electrical', 'cat_hvac'],
      transportMode: json['transport_mode'] ?? 'moto',
      availabilityStatus: json['availability_status'] ?? 'online',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      verified: json['verified'] ?? true,
    );
  }
}

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String categoryId;
  final String description;
  final String? photoUrl;
  final String status; // 'pending' | 'matched' | 'in_progress' | 'on_site' | 'completed' | 'cancelled'
  final double latitude;
  final double longitude;
  final String addressText;
  final String? technicianId;
  final String? scheduledEta;
  final String? cancellationReason;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.categoryId,
    required this.description,
    this.photoUrl,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    this.technicianId,
    this.scheduledEta,
    this.cancellationReason,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      clientName: json['client_name'] ?? 'Client Inconnu',
      clientPhone: json['client_phone'] ?? json['user_phone'] ?? '+221 77 000 00 00',
      categoryId: json['category_id'] ?? 'cat_plumbing',
      description: json['description'] ?? '',
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'matched',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 14.6937,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -17.4441,
      addressText: json['address_text'] ?? json['address'] ?? 'Dakar, Sénégal',
      technicianId: json['technician_id'],
      scheduledEta: json['scheduled_eta'] ?? '15 min',
      cancellationReason: json['cancellation_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BookingModel copyWith({
    String? status,
    String? scheduledEta,
    String? cancellationReason,
    String? addressText,
  }) {
    return BookingModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      categoryId: categoryId,
      description: description,
      photoUrl: photoUrl,
      status: status ?? this.status,
      latitude: latitude,
      longitude: longitude,
      addressText: addressText ?? this.addressText,
      technicianId: technicianId,
      scheduledEta: scheduledEta ?? this.scheduledEta,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt,
    );
  }
}

class MatchOfferModel {
  final String bookingId;
  final String clientName;
  final String clientPhone;
  final String categoryId;
  final String description;
  final String? photoUrl;
  final String addressText;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int timeoutSeconds;

  MatchOfferModel({
    required this.bookingId,
    required this.clientName,
    required this.clientPhone,
    required this.categoryId,
    required this.description,
    this.photoUrl,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.timeoutSeconds = 90,
  });

  factory MatchOfferModel.fromJson(Map<String, dynamic> json) {
    return MatchOfferModel(
      bookingId: json['booking_id'] ?? json['id'] ?? '',
      clientName: json['client_name'] ?? 'Client Inconnu',
      clientPhone: json['client_phone'] ?? json['user_phone'] ?? '+221 77 000 00 00',
      categoryId: json['category_id'] ?? 'cat_plumbing',
      description: json['description'] ?? '',
      photoUrl: json['photo_url'],
      addressText: json['address_text'] ?? json['address'] ?? 'Dakar, Sénégal',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 14.6937,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -17.4441,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.8,
      timeoutSeconds: json['timeout_seconds'] ?? 90,
    );
  }
}
