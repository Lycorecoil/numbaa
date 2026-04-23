import 'package:uuid/uuid.dart';
import '../../../core/constants/enums.dart';
import '../../entities/business_entity.dart';
import '../../repositories/business_repository.dart';

class SaveBusinessUseCase {
  final BusinessRepository _repository;
  SaveBusinessUseCase(this._repository);

  Future<BusinessEntity> call({
    required String userId,
    required String name,
    required BusinessCategory category,
    String? logoPath,
    String whatsapp = '',
  }) {
    final business = BusinessEntity(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      category: category,
      logoPath: logoPath,
      contact: ContactInfo(whatsapp: whatsapp),
    );
    return _repository.saveBusiness(business);
  }
}
