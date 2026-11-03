int rupiahValue(dynamic value) {
  if (value is int) return value;
  final text = value.toString();
  if (!RegExp(r'^\d+(?:\.0+)?$').hasMatch(text)) {
    throw const FormatException('Nominal dari server tidak valid.');
  }
  return int.parse(text.split('.').first);
}

class SaverAccount {
  final String accountNumber;
  final int balance;
  final int reservedBalance;
  final int availableBalance;
  final String qrCodeToken;

  SaverAccount.fromJson(Map<String, dynamic> json)
    : accountNumber = json['account_number'] as String,
      balance = rupiahValue(json['balance']),
      reservedBalance = rupiahValue(json['reserved_balance']),
      availableBalance = rupiahValue(json['available_balance']),
      qrCodeToken = json['qr_code_token'] as String;
}

class AccountModel {
  final String studentNumber;
  final String fullName;
  final int? graduationYear;
  final SaverAccount? saver;
  final String serviceStatus;

  AccountModel.fromJson(Map<String, dynamic> json)
    : studentNumber = json['member']['student_number'] as String,
      fullName = json['member']['full_name'] as String,
      graduationYear = json['member']['graduation_year'] as int?,
      saver = json['saver'] == null
          ? null
          : SaverAccount.fromJson(Map<String, dynamic>.from(json['saver'])),
      serviceStatus = (json['service_status'] as String?)?.toLowerCase() ?? 'buka';
}
