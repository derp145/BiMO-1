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

  factory ComponentOption.fromJson(Map<String, dynamic> json) => ComponentOption(
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

  BOMComponent({
    required this.orig,
    required this.local,
    required this.notes,
    this.qty = 1,
    this.selectedOptionIndex = 1,
    required this.options,
    this.isBought = false,
    this.isCustom = false,
    this.category = 'Hardware',
    this.actualCost,
  });

  ComponentOption get selectedOption =>
      options.isNotEmpty && selectedOptionIndex < options.length
          ? options[selectedOptionIndex]
          : (options.isNotEmpty
              ? options.first
              : ComponentOption(
                  type: 'Standard Edition',
                  seller: 'MakerStore',
                  stock: 100,
                  price: 350.0,
                  match: '95%'));

  double get unitPrice => selectedOption.price;
  double get totalPrice => unitPrice * qty;

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
    );
  }
}

class AuditLogEntry {
  final String action;
  final String timestamp;

  AuditLogEntry({required this.action, required this.timestamp});
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
  });

  double get baseTotalCost {
    return components.fold(
        0.0, (sum, comp) => sum + (comp.unitPrice * comp.qty));
  }

  double get finalCost {
    return isOptimized ? baseTotalCost * 0.75 : baseTotalCost;
  }

  int get partsCount => components.length;

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
    );
  }
}
