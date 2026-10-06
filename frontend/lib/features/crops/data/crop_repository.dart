import 'crop_api.dart';
import 'crop_repository_contract.dart';
import 'models/crop.dart';
import 'models/crop_create_request.dart';
import 'models/crop_update_request.dart';

class CropRepository implements CropRepositoryContract {
  CropRepository(this._api);

  final CropApi _api;

  @override
  Future<List<Crop>> getCrops(String farmId) => _api.getCrops(farmId);

  @override
  Future<Crop> getCrop(String cropId) => _api.getCrop(cropId);

  @override
  Future<Crop> createCrop(String farmId, CropCreateRequest request) =>
      _api.createCrop(farmId, request);

  @override
  Future<Crop> updateCrop(String cropId, CropUpdateRequest request) =>
      _api.updateCrop(cropId, request);
}
