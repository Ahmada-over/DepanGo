class ServiceCategoryModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final double? basePrice;

  ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.basePrice,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon_name'] ?? 'build',
      basePrice: (json['base_price'] as num?)?.toDouble(),
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'client',
      token: token ?? json['access_token'],
    );
  }
}

class BookingModel {
  final String id;
  final String clientId;
  final String categoryId;
  final String description;
  final String? photoUrl;
  final String status;
  final double latitude;
  final double longitude;
  final String addressText;
  final String? technicianId;
  final String? scheduledEta;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.categoryId,
    required this.description,
    this.photoUrl,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    this.technicianId,
    this.scheduledEta,
    required this.createdAt,
  });

  BookingModel copyWith({
    String? id,
    String? clientId,
    String? categoryId,
    String? description,
    String? photoUrl,
    String? status,
    double? latitude,
    double? longitude,
    String? addressText,
    String? technicianId,
    String? scheduledEta,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressText: addressText ?? this.addressText,
      technicianId: technicianId ?? this.technicianId,
      scheduledEta: scheduledEta ?? this.scheduledEta,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      description: json['description'] ?? '',
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'pending',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 14.6937,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -17.4441,
      addressText: json['address_text'] ?? 'Dakar',
      technicianId: json['technician_id'],
      scheduledEta: json['scheduled_eta'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? 'User',
      content: json['content'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type;
  bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}
