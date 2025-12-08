// lib/models/subscription_model.dart
class SubscriptionModel {
  final String id;
  final String userId;
  final String? revenueCatCustomerId;
  final String? revenueCatEntitlementId;

  final SubscriptionStatus status;
  final SubscriptionTier? tier;

  final DateTime? trialStartAt;
  final DateTime? trialEndAt;
  final DateTime? subscriptionStartAt;
  final DateTime? subscriptionEndAt;
  final DateTime? cancelledAt;

  final String? platform;
  final String? productId;

  final DateTime createdAt;
  final DateTime updatedAt;

  // 计算属性
  bool get isActive {
    if (status == SubscriptionStatus.active &&
        subscriptionEndAt != null &&
        subscriptionEndAt!.isAfter(DateTime.now())) {
      return true;
    }
    if (status == SubscriptionStatus.trial &&
        trialEndAt != null &&
        trialEndAt!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  bool get isFree => status == SubscriptionStatus.free;
  bool get isTrialing => status == SubscriptionStatus.trial;
  bool get isPro => isActive;

  /// 试用剩余天数
  int? get trialDaysLeft {
    if (status == SubscriptionStatus.trial && trialEndAt != null) {
      final now = DateTime.now();
      if (trialEndAt!.isAfter(now)) {
        return trialEndAt!.difference(now).inDays;
      }
    }
    return null;
  }

  SubscriptionModel({
    required this.id,
    required this.userId,
    this.revenueCatCustomerId,
    this.revenueCatEntitlementId,
    required this.status,
    this.tier,
    this.trialStartAt,
    this.trialEndAt,
    this.subscriptionStartAt,
    this.subscriptionEndAt,
    this.cancelledAt,
    this.platform,
    this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      userId: json['user_id'],
      revenueCatCustomerId: json['revenue_cat_customer_id'],
      revenueCatEntitlementId: json['revenue_cat_entitlement_id'],
      status: SubscriptionStatus.fromString(json['status']),
      tier: json['tier'] != null
          ? SubscriptionTier.fromString(json['tier'])
          : null,
      trialStartAt: json['trial_start_at'] != null
          ? DateTime.parse(json['trial_start_at'])
          : null,
      trialEndAt: json['trial_end_at'] != null
          ? DateTime.parse(json['trial_end_at'])
          : null,
      subscriptionStartAt: json['subscription_start_at'] != null
          ? DateTime.parse(json['subscription_start_at'])
          : null,
      subscriptionEndAt: json['subscription_end_at'] != null
          ? DateTime.parse(json['subscription_end_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      platform: json['platform'],
      productId: json['product_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

enum SubscriptionStatus {
  free,
  trial,
  active,
  cancelled,
  expired;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.free,
    );
  }
}

enum SubscriptionTier {
  monthly,
  yearly,
  lifetime;

  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere((e) => e.name == value);
  }
}
