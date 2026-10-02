class ComponentOption {
  final String type;
  final String seller;
  final int stock;
  final double price;
  final String match;

  ComponentOption({
    required this.type,
    required this.seller,
    required this.stock,
    required this.price,
    required this.match,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'seller': seller,
    'stock': stock,
    'price': price,
    'match': match,
  };

  factory ComponentOption.fromJson(Map<String, dynamic> json) =>
      ComponentOption(
        type: json['type'] ?? '',
        seller: json['seller'] ?? '',
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        match: json['match'] ?? '90%',
      );
}

class BOMComponent {
  final String orig;
  final String local;
  final String notes;
  int qty;
  int selectedOptionIndex;
  List<ComponentOption> options;
  bool isBought;
  bool isCustom;
  String category;
  double? actualCost;
  double? customEstimatedPrice;

  BOMComponent({
    required this.orig,
    required this.local,
    this.notes = '',
    this.qty = 1,
    this.selectedOptionIndex = 0,
    this.options = const [],
    this.isBought = false,
    this.isCustom = false,
    this.category = 'Hardware',
    this.actualCost,
    this.customEstimatedPrice,
  });

  ComponentOption get selectedOption =>
      options.isNotEmpty && selectedOptionIndex < options.length
      ? options[selectedOptionIndex]
      : (options.isNotEmpty
            ? options.first
            : ComponentOption(
                type: 'Standard Option',
                seller: isCustom ? 'Custom Item' : '',
                stock: 0,
                price: customEstimatedPrice ?? 0.0,
                match: '100%',
              ));

  double get unitPrice =>
      options.isNotEmpty ? selectedOption.price : (customEstimatedPrice ?? 0.0);
  double get totalPrice => unitPrice * qty;
  double? get actualTotal => actualCost == null ? null : actualCost! * qty;

  Map<String, dynamic> toJson() => {
    'orig': orig,
    'local': local,
    'notes': notes,
    'qty': qty,
    'selectedOptionIndex': selectedOptionIndex,
    'options': options.map((opt) => opt.toJson()).toList(),
    'isBought': isBought,
    'isCustom': isCustom,
    'category': category,
    if (actualCost != null) 'actualCost': actualCost,
    if (customEstimatedPrice != null)
      'customEstimatedPrice': customEstimatedPrice,
    if (customEstimatedPrice != null)
      'custom_estimated_price': customEstimatedPrice,
  };

  factory BOMComponent.fromJson(Map<String, dynamic> json) => BOMComponent(
    orig: json['orig'] ?? '',
    local: json['local'] ?? '',
    notes: json['notes'] ?? '',
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    selectedOptionIndex:
        (json['selectedOptionIndex'] as num?)?.toInt() ??
        (json['selected_option_index'] as num?)?.toInt() ??
        0,
    options:
        (json['options'] as List<dynamic>?)
            ?.map(
              (opt) => ComponentOption.fromJson(opt as Map<String, dynamic>),
            )
            .toList() ??
        [],
    isBought: json['isBought'] ?? json['is_bought'] ?? false,
    isCustom: json['isCustom'] ?? json['is_custom'] ?? false,
    category: json['category'] ?? 'Hardware',
    actualCost:
        (json['actualCost'] as num?)?.toDouble() ??
        (json['actual_cost'] as num?)?.toDouble(),
    customEstimatedPrice:
        (json['customEstimatedPrice'] as num?)?.toDouble() ??
        (json['custom_estimated_price'] as num?)?.toDouble() ??
        ((json['options'] is List && (json['options'] as List).isNotEmpty)
            ? ((json['options'] as List).first['price'] as num?)?.toDouble()
            : null),
  );

  BOMComponent copyWith({
    String? orig,
    String? local,
    String? notes,
    int? qty,
    int? selectedOptionIndex,
    List<ComponentOption>? options,
    bool? isBought,
    bool? isCustom,
    String? category,
    double? actualCost,
    double? customEstimatedPrice,
  }) {
    return BOMComponent(
      orig: orig ?? this.orig,
      local: local ?? this.local,
      notes: notes ?? this.notes,
      qty: qty ?? this.qty,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      options: options ?? List.from(this.options),
      isBought: isBought ?? this.isBought,
      isCustom: isCustom ?? this.isCustom,
      category: category ?? this.category,
      actualCost: actualCost ?? this.actualCost,
      customEstimatedPrice: customEstimatedPrice ?? this.customEstimatedPrice,
    );
  }
}

const List<String> bomCategories = [
  'Microcontrollers',
  'Sensors',
  'Actuators',
  'Power',
  'Passive Components',
  'Hardware',
  'Modules',
  'Connectivity',
  'Other',
];

String componentIdentity(BOMComponent component) {
  String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // Keep specifications and categories distinct while treating exact name variations as one item.
  return '${normalize(component.orig)}|${normalize(component.local)}|${normalize(component.notes)}|${normalize(component.category)}';
}

List<BOMComponent> normalizeComponents(Iterable<BOMComponent> components) {
  final merged = <String, BOMComponent>{};
  for (final component in components) {
    final identity = componentIdentity(component);
    final existing = merged[identity];
    if (existing == null) {
      merged[identity] = component.copyWith(
        qty: component.qty < 1 ? 1 : component.qty,
      );
      continue;
    }

    merged[identity] = existing.copyWith(
      qty: existing.qty + (component.qty < 1 ? 1 : component.qty),
      options: existing.options.isNotEmpty
          ? existing.options
          : component.options,
      selectedOptionIndex: existing.options.isNotEmpty
          ? existing.selectedOptionIndex
          : component.selectedOptionIndex,
      isBought: existing.isBought || component.isBought,
      isCustom: existing.isCustom || component.isCustom,
      actualCost: existing.actualCost ?? component.actualCost,
      customEstimatedPrice:
          existing.customEstimatedPrice ?? component.customEstimatedPrice,
    );
  }
  return merged.values.toList();
}

class AuditLogEntry {
  final String action;
  final String timestamp;

  AuditLogEntry({required this.action, required this.timestamp});

  Map<String, dynamic> toJson() => {'action': action, 'timestamp': timestamp};

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    action: json['action'] ?? '',
    timestamp: json['timestamp'] ?? '',
  );
}

class ProjectModel {
  final String id;
  String title;
  final String category; // 'engineering', 'electronics', 'hardware'
  final DateTime createdAt;
  DateTime? deletedAt;
  bool isOptimized;
  bool isCompleted;
  List<BOMComponent> components;
  List<AuditLogEntry> auditLog;
  String? region;
  String? city;
  String? barangay;
  String? promptOrUrl;
  String? authorName;
  String? thumbnailUrl;
  List<String> buildInstructions;
  List<Map<String, dynamic>> suggestedStores;

  ProjectModel({
    required this.id,
    required this.title,
    this.category = 'engineering',
    required this.createdAt,
    this.deletedAt,
    this.isOptimized = true,
    this.isCompleted = false,
    required this.components,
    required this.auditLog,
    this.region,
    this.city,
    this.barangay,
    this.promptOrUrl,
    this.authorName,
    this.thumbnailUrl,
    this.buildInstructions = const [],
    this.suggestedStores = const [],
  });

  double get baseTotalCost {
    return components.fold(
      0.0,
      (sum, comp) => sum + (comp.unitPrice * comp.qty),
    );
  }

  double get estimatedCost => baseTotalCost;

  double get finalCost {
    return isOptimized ? baseTotalCost * 0.75 : baseTotalCost;
  }

  int get partsCount => components.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    'isOptimized': isOptimized,
    'is_optimized': isOptimized,
    'isCompleted': isCompleted,
    'is_completed': isCompleted,
    'components': components.map((comp) => comp.toJson()).toList(),
    'auditLog': auditLog.map((log) => log.toJson()).toList(),
    'audit_log': auditLog.map((log) => log.toJson()).toList(),
    'region': region,
    'city': city,
    'barangay': barangay,
    'promptOrUrl': promptOrUrl,
    'prompt_or_url': promptOrUrl,
    'authorName': authorName,
    'author_name': authorName,
    'thumbnail_url': thumbnailUrl,
    'buildInstructions': buildInstructions,
    'build_instructions': buildInstructions,
    'suggestedStores': suggestedStores,
    'suggested_stores': suggestedStores,
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final rawComps = json['components'];
    final List<BOMComponent> compsList = [];
    if (rawComps is List) {
      for (final item in rawComps) {
        if (item is Map<String, dynamic>) {
          compsList.add(BOMComponent.fromJson(item));
        } else if (item is Map) {
          compsList.add(BOMComponent.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawLogs = json['auditLog'] ?? json['audit_log'];
    final List<AuditLogEntry> logsList = [];
    if (rawLogs is List) {
      for (final item in rawLogs) {
        if (item is Map<String, dynamic>) {
          logsList.add(AuditLogEntry.fromJson(item));
        } else if (item is Map) {
          logsList.add(AuditLogEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawInstructions =
        json['buildInstructions'] ?? json['build_instructions'];
    final List<String> instructionsList = [];
    if (rawInstructions is List) {
      for (final item in rawInstructions) {
        if (item != null) {
          instructionsList.add(item.toString());
        }
      }
    }

    final rawStores = json['suggestedStores'] ?? json['suggested_stores'];
    final List<Map<String, dynamic>> storesList = [];
    if (rawStores is List) {
      for (final item in rawStores) {
        if (item is Map<String, dynamic>) {
          storesList.add(item);
        } else if (item is Map) {
          storesList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return ProjectModel(
      id:
          json['id']?.toString() ??
          'proj-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Untitled Project',
      category: json['category']?.toString() ?? 'engineering',
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      deletedAt: parseNullableDate(json['deletedAt'] ?? json['deleted_at']),
      isOptimized: json['isOptimized'] ?? json['is_optimized'] ?? true,
      isCompleted: json['isCompleted'] ?? json['is_completed'] ?? false,
      components: normalizeComponents(compsList),
      auditLog: logsList,
      region: json['region']?.toString(),
      city: json['city']?.toString(),
      barangay: json['barangay']?.toString(),
      promptOrUrl:
          json['promptOrUrl']?.toString() ?? json['prompt_or_url']?.toString(),
      authorName:
          json['authorName']?.toString() ?? json['author_name']?.toString(),
      thumbnailUrl:
          json['thumbnailUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      buildInstructions: instructionsList,
      suggestedStores: storesList,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool? isOptimized,
    bool? isCompleted,
    List<BOMComponent>? components,
    List<AuditLogEntry>? auditLog,
    String? region,
    String? city,
    String? barangay,
    String? promptOrUrl,
    String? authorName,
    String? thumbnailUrl,
    List<String>? buildInstructions,
    List<Map<String, dynamic>>? suggestedStores,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isOptimized: isOptimized ?? this.isOptimized,
      isCompleted: isCompleted ?? this.isCompleted,
      components: components ?? List.from(this.components),
      auditLog: auditLog ?? List.from(this.auditLog),
      region: region ?? this.region,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      promptOrUrl: promptOrUrl ?? this.promptOrUrl,
      authorName: authorName ?? this.authorName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      buildInstructions: buildInstructions ?? List.from(this.buildInstructions),
      suggestedStores: suggestedStores ?? List.from(this.suggestedStores),
    );
  }
}
