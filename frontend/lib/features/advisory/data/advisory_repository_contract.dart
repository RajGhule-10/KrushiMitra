import 'models/crop_advisory.dart';

abstract interface class AdvisoryRepositoryContract {
  Future<CropAdvisory> getCropAdvisory(String cropId);
}
