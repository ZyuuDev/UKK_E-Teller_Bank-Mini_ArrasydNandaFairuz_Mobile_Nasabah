int rupiahValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty) return 0;
  final clean = text.split('.').first;
  return int.tryParse(clean) ?? (double.tryParse(text)?.toInt() ?? 0);
}

class SaverAccount {
  final String accountNumber;
  final int balance;
  final int reservedBalance;
  final int availableBalance;
  final String qrCodeToken;

  SaverAccount.fromJson(Map<String, dynamic> json)
    : accountNumber = json['account_number']?.toString() ?? '',
      balance = rupiahValue(json['balance']),
      reservedBalance = rupiahValue(json['reserved_balance']),
      availableBalance = rupiahValue(json['available_balance']),
      qrCodeToken = json['qr_code_token']?.toString() ?? '';
}

class AccountModel {
  final String studentNumber;
  final String fullName;
  final int? graduationYear;
  final SaverAccount? saver;
  final String serviceStatus;

  AccountModel.fromJson(Map<String, dynamic> json)
    : studentNumber = json['member']?['student_number']?.toString() ?? '',
      fullName = json['member']?['full_name']?.toString() ?? '',
      graduationYear = (json['member']?['graduation_year'] as num?)?.toInt(),
      saver = json['saver'] == null
          ? null
          : SaverAccount.fromJson(Map<String, dynamic>.from(json['saver'] as Map)),
      serviceStatus = (json['service_status'] as String?)?.toLowerCase() ?? 'buka';
}
