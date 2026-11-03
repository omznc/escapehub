part of 'api_client.dart';

class LoyaltyApi {
  LoyaltyApi._(this._client);

  final ApiClient _client;

  Future<Paged<LoyaltyRewardDto>> rewards({
    bool? isActive,
    int? rewardTypeId,
    String? search,
    ListSort? sortBy,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/loyalty/rewards', LoyaltyRewardDto.fromJson, {
    'isActive': isActive,
    'rewardTypeId': rewardTypeId,
    'search': search,
    'sortBy': sortBy?.value,
    'page': page,
    'pageSize': pageSize,
  });

  Future<LoyaltyRewardDto> createReward(SaveLoyaltyRewardRequest request) =>
      _client._post('/api/loyalty/rewards', LoyaltyRewardDto.fromJson, request.toJson());

  Future<LoyaltyRewardDto> updateReward(int id, SaveLoyaltyRewardRequest request) =>
      _client._put('/api/loyalty/rewards/$id', LoyaltyRewardDto.fromJson, request.toJson());

  Future<void> deleteReward(int id) => _client._delete('/api/loyalty/rewards/$id');

  Future<RewardRedemptionDto> redeem(int rewardId) =>
      _client._post('/api/loyalty/rewards/$rewardId/redeem', RewardRedemptionDto.fromJson);

  Future<LoyaltyBalanceDto> myBalance() => _client._get('/api/loyalty/me/balance', LoyaltyBalanceDto.fromJson);

  Future<Paged<LoyaltyTransactionDto>> myTransactions({
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/loyalty/me/transactions', LoyaltyTransactionDto.fromJson, {
    'type': type?.value,
    'from': from,
    'to': to,
    'page': page,
    'pageSize': pageSize,
  });

  Future<Paged<RewardRedemptionDto>> myRedemptions({bool? isUsed, int page = 1, int pageSize = 20}) =>
      _client._getPaged('/api/loyalty/me/redemptions', RewardRedemptionDto.fromJson, {
        'isUsed': isUsed,
        'page': page,
        'pageSize': pageSize,
      });

  Future<Paged<LoyaltyTransactionDto>> transactions({
    int? clientId,
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/loyalty/transactions', LoyaltyTransactionDto.fromJson, {
    'clientId': clientId,
    'type': type?.value,
    'from': from,
    'to': to,
    'search': search,
    'page': page,
    'pageSize': pageSize,
  });

  Future<Paged<RewardRedemptionDto>> redemptions({
    int? clientId,
    int? rewardId,
    bool? isUsed,
    DateTime? from,
    DateTime? to,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/loyalty/redemptions', RewardRedemptionDto.fromJson, {
    'clientId': clientId,
    'rewardId': rewardId,
    'isUsed': isUsed,
    'from': from,
    'to': to,
    'search': search,
    'page': page,
    'pageSize': pageSize,
  });
}
