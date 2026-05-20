import '../../shared/models/hangout_model.dart';

abstract class HangoutRepository {
  Future<List<HangoutModel>> getHangouts();
}
