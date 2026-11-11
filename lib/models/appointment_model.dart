import 'account_model.dart';

class WithdrawalLimitsModel {
  final int balance;
  final int minimumBalance;
  final int maxWithdrawable;
  final int dailyWithdrawalLimit;
  final int appointmentThreshold;
  final int todayWithdrawn;
  final int remainingDailyLimit;

  WithdrawalLimitsModel({
    required this.balance,
    required this.minimumBalance,
    required this.maxWithdrawable,
    required this.dailyWithdrawalLimit,
    required this.appointmentThreshold,
    required this.todayWithdrawn,
    required this.remainingDailyLimit,
  });

  factory WithdrawalLimitsModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalLimitsModel(
      balance: rupiahValue(json['balance']),
      minimumBalance: rupiahValue(json['minimum_balance']),
      maxWithdrawable: rupiahValue(json['max_withdrawable']),
      dailyWithdrawalLimit: rupiahValue(json['daily_withdrawal_limit']),
      appointmentThreshold: rupiahValue(json['appointment_threshold']),
      todayWithdrawn: rupiahValue(json['today_withdrawn']),
      remainingDailyLimit: rupiahValue(json['remaining_daily_limit']),
    );
  }
}

class AppointmentModel {
  final int id;
  final String appointmentCode;
  final int amount;
  final String scheduledDate;
  final String? notes;
  final String status;
  final String creatorRole;
  final String? rejectionReason;
  final String? approvedAt;
  final String createdAt;

  AppointmentModel({
    required this.id,
    required this.appointmentCode,
    required this.amount,
    required this.scheduledDate,
    this.notes,
    required this.status,
    required this.creatorRole,
    this.rejectionReason,
    this.approvedAt,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      appointmentCode: json['appointment_code']?.toString() ?? '',
      amount: rupiahValue(json['amount']),
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      notes: json['notes'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      creatorRole: (json['creator_role'] as String?) ?? 'student',
      rejectionReason: json['rejection_reason'] as String?,
      approvedAt: json['approved_at'] as String?,
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }
}

class AppointmentPage {
  final List<AppointmentModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AppointmentPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory AppointmentPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List list;
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;

    if (rawData is Map) {
      list = (rawData['data'] as List?) ?? [];
      currentPage = (rawData['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (rawData['last_page'] as num?)?.toInt() ?? 1;
      total = (rawData['total'] as num?)?.toInt() ?? list.length;
    } else if (rawData is List) {
      list = rawData;
      currentPage = (json['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (json['last_page'] as num?)?.toInt() ?? 1;
      total = (json['total'] as num?)?.toInt() ?? list.length;
    } else {
      list = [];
    }

    return AppointmentPage(
      items: list
          .map((e) => AppointmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }
}

