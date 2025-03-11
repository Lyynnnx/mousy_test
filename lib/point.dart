import 'package:mouse_test/abstpoint.dart';

class Point1 extends Abstpoint{
  double x;
  double y;
  double z;
  Point1(this.x, this.y, this.z);


  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }
}