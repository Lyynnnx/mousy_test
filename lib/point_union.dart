import 'package:mouse_test/abstpoint.dart';

class PointUnion extends Abstpoint{
  double gx;
  double gy;
  double gz;
  double ax;
  double ay;
  double az;

  PointUnion(this.gx, this.gy, this.gz, this.ax, this.ay, this.az);

  Map<String, dynamic> toJson() {
    return {
      'x_a': ax,
      'y_a': ay,
      'z_a': az,
      'x_g': gx,
      'y_g': gy,
      'z_g': gz
    };
  }
}