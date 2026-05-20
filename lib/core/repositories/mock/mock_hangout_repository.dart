import '../../../shared/data/mock_hangouts.dart';
import '../../../shared/models/hangout_model.dart';
import '../hangout_repository.dart';

class MockHangoutRepository implements HangoutRepository {
  @override
  Future<List<HangoutModel>> getHangouts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [activeHangout, ...quickHangouts];
  }
}
