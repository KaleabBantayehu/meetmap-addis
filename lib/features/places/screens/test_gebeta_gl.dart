import 'package:gebeta_gl/gebeta_gl.dart';

void test(GebetaMapController controller) {
  // Try using addLine or line methods to see if they are valid
  controller.addLine(
    const LineOptions(
      geometry: [LatLng(9.0, 38.0), LatLng(9.1, 38.1)],
      lineColor: '#FF0000',
      lineWidth: 3.0,
    ),
  );
}
