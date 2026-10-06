import 'models/crop.dart';
import 'models/crop_create_request.dart';
import 'models/crop_update_request.dart';

abstract interface class CropRepositoryContract {
  Future<List<Crop>> getCrops(String farmId);
  Future<Crop> getCrop(String cropId);
  Future<Crop> createCrop(String farmId, CropCreateRequest request);
  Future<Crop> updateCrop(String cropId, CropUpdateRequest request);
}
