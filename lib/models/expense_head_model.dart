class ExpenseHeadModel {
  final int? id;
  final String head;
  final String? description;

  ExpenseHeadModel({
    this.id,
    required this.head,
    this.description,
  });

  factory ExpenseHeadModel.fromJson(Map<String, dynamic> json) {
    return ExpenseHeadModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      head: json['head']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'head': head,
      'description': description ?? '',
    };
  }
}
