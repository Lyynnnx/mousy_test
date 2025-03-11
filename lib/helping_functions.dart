import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:mouse_test/abstpoint.dart';
import 'package:mouse_test/point.dart';
import 'package:mouse_test/point_union.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HelpingFunctions {
  StreamSubscription? gyroscopeSubscription;
  StreamSubscription? accelerometerSubscription;
  void testAcceler() {
    //print("hi");
    accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      print("{x: ${event.x}, y: ${event.y}, z: ${event.z}}");
    });
  }

  void timeMesaure() {
    var oldTime = DateTime.now();
    var newTime = DateTime.now();

    accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      newTime = DateTime.now();
      print(newTime.difference(oldTime).inMilliseconds);
      oldTime = newTime;
    });
  }

  void testGyro(List<Abstpoint> points) {
    int ctr = 0;
    gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (ctr < 201) {
        if (ctr == 200) {
          saveToFile("gyro", points);
          //sleep(const Duration(hours: 5));
        }
        print("{x: ${event.x},\t y: ${event.y},\t z: ${event.z}}");
        points.add(new Point1(event.x, event.y, event.z));
        ctr++;
      }
    });
  }

  void testAcc(List<Abstpoint> points) {
    int ctr = 0;
    accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      if (ctr < 201) {
        if (ctr == 200) {
          saveToFile("acc", points);
          //sleep(const Duration(hours: 5));
        }
        print("{x: ${event.x},\t y: ${event.y},\t z: ${event.z}}");
        points.add(new Point1(event.x, event.y, event.z));
        ctr++;
      }
    });
  }

  void smartGyro() {
    gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      double ans =
          1 /
          (1 +
              exp(
                -(-0.23284816852948964 +
                    0.0018713666405181589 * event.x +
                    0.01674713888086815 * event.y +
                    0.0038221924972819273 * event.z),
              ));
      if (ans >= 0.44444444444) {
        print("moving yay");
      } else {
        print(":(");
      }
    });
  }

  void testGyroAcc(List<Abstpoint> points) {
    int ctr = 0;
    double lastAx = 0, lastAy = 0, lastAz = 0;
    double lastGx = 0, lastGy = 0, lastGz = 0;

    StreamGroup<dynamic> sensorGroup = StreamGroup<dynamic>();
    sensorGroup.add(gyroscopeEvents);
    sensorGroup.add(accelerometerEvents);

    sensorGroup.stream.listen((event) {
      if (ctr < 201) {
        if (ctr == 200) {
          saveToFile("gyroAcc", points);
          gyroscopeSubscription?.cancel();
          accelerometerSubscription?.cancel();
        }

        if (event is GyroscopeEvent) {
          lastGx = event.x;
          lastGy = event.y;
          lastGz = event.z;
        } else if (event is AccelerometerEvent) {
          lastAx = event.x;
          lastAy = event.y;
          lastAz = event.z;
        }
        print(
          "{ax: $lastAx, ay: $lastAy, az: $lastAz, gx: $lastGx, gy: $lastGy, gz: $lastGz}",
        );
        points.add(PointUnion(lastAx, lastAy, lastAz, lastGx, lastGy, lastGz));
        ctr++;
      }
    });
  }



   Future<void> saveToFile(String name, List<Abstpoint> points) async {
    if (true) {
      try {
        var status = await Permission.storage.request();
        Directory? directory = Directory(
          '/storage/emulated/0/Download',
        ); // Для Android
        if (!directory.existsSync()) {
          directory = await getExternalStorageDirectory();
        }
        File file = File('${directory!.path}/${name}_data.json');
        String jsonString = jsonEncode(points); // Преобразуем в JSON
        await file.writeAsString(jsonString); // Асинхронно записываем в файл

        print("✅ Данные сохранены в: ${file.path}");
      } catch (e) {
        print("❌ Ошибка при сохранении файла: $e");
      }
    }
  }

}
