class AccountModel {
  final String accountNumber;
  final String fullName;
  final String className;
  final int balance;
  final String qrCodeToken;

  AccountModel({
    required this.accountNumber,
    required this.fullName,
    required this.className,
    required this.balance,
    required this.qrCodeToken,
  });

  // respon json dari endpoint /api/nasabah/balance menjadi dart
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountNumber: json['account_number'] ?? '',
      fullName: json['full_name'] ?? '',
      className: json['class_name'] ?? '',
      balance: int.tryParse(json['balance'].toString()) ?? 0,
      qrCodeToken: json['qr_code_token'] ?? '',
    );
  }
}
