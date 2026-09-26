import '../../shared/models/hangout_model.dart';
import 'page_result.dart';

abstract class HangoutRepository {
  Future<List<HangoutModel>> getHangouts();
  Future<PageResult<HangoutModel>> getHangoutsPage({
    String? cursor,
    int limit = 20,
  });
  Future<List<VenueModel>> getTopPickVenues();
  Future<List<ActivityModel>> getRecentActivities();
  Future<HangoutModel> createHangout(HangoutModel hangout);
}
