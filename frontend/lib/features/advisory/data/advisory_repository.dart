import 'advisory_api.dart';
import 'advisory_repository_contract.dart';
import 'models/crop_advisory.dart';

class AdvisoryRepository implements AdvisoryRepositoryContract {
  AdvisoryRepository(this._api);

  final AdvisoryApi _api;

  @override
  Future<CropAdvisory> getCropAdvisory(String cropId) {
    return _api.getCropAdvisory(cropId);
  }
}
