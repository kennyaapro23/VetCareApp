class CatalogServiceModel {
  final int? id;
  final String code;
  final String name;
  final String? description;
  final double price;
  final double taxPercent;

  CatalogServiceModel({
    this.id,
    required this.code,
    required this.name,
    this.description,
    required this.price,
    required this.taxPercent,
  });

  factory CatalogServiceModel.fromJson(Map<String, dynamic> json) {
    return CatalogServiceModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      code: (json['code'] ?? json['codigo'] ?? '').toString(),
      name: (json['name'] ?? json['nombre'] ?? '').toString(),
      description: (json['description'] ?? json['descripcion'])?.toString(),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : (json['precio'] != null ? double.tryParse(json['precio'].toString()) ?? 0.0 : 0.0),
      taxPercent: json['tax_percent'] != null ? double.tryParse(json['tax_percent'].toString()) ?? 0.0 : (json['impuesto'] != null ? double.tryParse(json['impuesto'].toString()) ?? 0.0 : 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'code': code,
        'name': name,
        'description': description,
        'price': price,
        'tax_percent': taxPercent,
      };
}

