class  MutationModel {
    final int id;
    final String transactionType;
    final int amount;
    final String date;
    final String notes;

    MutationModel({
        required this.id,
        required this.transactionType,
        required this.amount,
        required this.date,
        required this.notes,
    });

    factory MutationModel.fromJson(Map<String, dynamic> json) {
        return MutationModel(
            id: json['id'] ?? 0,
            transactionType: json['transaction_type'] ?? 0,
            date: json['date'] ?? '',
            notes: json['notes'] ?? '',
        );
    }
}