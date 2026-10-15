import 'account_model.dart';

class MutationModel {
  final int id;
  final String transactionType;
  final int amount;
  final DateTime occurredAt;
  final String notes;

  MutationModel.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      transactionType = json['transaction_type'] as String,
      amount = rupiahValue(json['amount']),
      occurredAt = DateTime.parse(json['created_at'] as String),
      notes = json['notes'] as String? ?? '';
}

class MutationPage {
  final List<MutationModel> items;
  final int currentPage;
  final int lastPage;

  MutationPage.fromJson(Map<String, dynamic> json)
    : items = (json['data'] as List)
          .map((row) => MutationModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      currentPage = json['current_page'] as int,
      lastPage = json['last_page'] as int;
}