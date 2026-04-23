import '../entities/business_entity.dart';

/// Contract for business profile operations.
abstract class BusinessRepository {
  Future<BusinessEntity?> getBusiness(String userId);
  Future<BusinessEntity> saveBusiness(BusinessEntity business);
  Future<BusinessEntity> updateBusiness(BusinessEntity business);
}
