import 'account_model.dart';

class MutationModel {
  final int id;
  final String transactionType;
  final int amount;
  final DateTime occurredAt;
  final String notes;

  MutationModel.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as num?)?.toInt() ?? 0,
      transactionType = json['transaction_type']?.toString() ?? 'Deposit',
      amount = rupiahValue(json['amount']),
      occurredAt = DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      notes = json['notes'] as String? ?? '';
}

class MutationPage {
  final List<MutationModel> items;
  final int currentPage;
  final int lastPage;

  MutationPage.fromJson(Map<String, dynamic> json)
    : items = (json['data'] as List? ?? [])
          .map((row) => MutationModel.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(),
      currentPage = (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage = (json['last_page'] as num?)?.toInt() ?? 1;
}