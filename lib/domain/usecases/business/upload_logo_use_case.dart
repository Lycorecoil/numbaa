import '../../repositories/business_repository.dart';

class UploadLogoUseCase {
  final BusinessRepository _repo;
  UploadLogoUseCase(this._repo);

  Future<String> call(String filePath) => _repo.uploadLogo(filePath);
}
