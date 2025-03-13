import 'dart:async';

import 'package:mouse_test/abstpoint.dart';
import 'package:mouse_test/physics_helper.dart';
import 'package:mouse_test/server_connector.dart';
import 'package:mouse_test/types_of_click.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MainLogic {

  double avgx = 0.0;
  double avgy = 0.0;
  double avgz=0.0;

  StreamSubscription? gyroscopeSubscription;
  StreamSubscription? accelerometerSubscription;

  List<Abstpoint> points = [];

  bool firstRead = true;
  double sensitivity = 100; // Чувствительность движения

  List<double> accXBuffer = []; // Буфер значений по X
  List<double> accYBuffer = []; // Буфер значений по X
  List<double> accZBuffer = []; // Буфер значений по X
  final int bufferSize = 1; // Размер окна (чем больше, тем стабильнее)
  final int floatingBufferSize = 1; // Размер окна (чем больше, тем стабильнее)
  final double threshold = 20; // Порог движения (чем меньше, тем чувствительнее)
  bool isMoving = false; // Флаг движения

  var oldTime = DateTime.now();
  var newTime = DateTime.now();

  late PhysicsHelper physicsHelper;
  late ServerConnector serverConnector;
  bool isConnectionInitialised=false;
//double deadZone = 0.05;
  double deadZone = 0.05; // "Мертвая зона" (игнорируем мелкие изменения)
  double floatingZone = 0.1; // "Мертвая зона" (игнорируем мелкие изменения)

  bool isOnGround(double z){
    if((avgz-z).abs() < floatingZone){
      accZBuffer.add(z);
        
        if (accZBuffer.length > floatingBufferSize) {
          accZBuffer.removeAt(0);
        }
        avgz = accZBuffer.fold(0.0, (sum, x) => sum + (x)) / accZBuffer.length;
      //print("on ground");
      
      return true;
    }
   // print("in the sky");
    avgz = z;
    return false;
  }


  double biasX = 0.0;
double biasY = 0.0;

void calibrateAccelerometer() {
    // Усредняем значения за несколько измерений
    for (int i = 0; i < 100; i++) {
        accelerometerEvents.first.then((event) {
            biasX += event.x;
            biasY += event.y;
        });
    }
    biasX /= 100;
    biasY /= 100;
}



  void startAccelerometerListener() {
    
    accelerometerSubscription = accelerometerEvents.listen(
      (
      AccelerometerEvent event,
    ) {
      
       //меряем время для delta t
      newTime = event.timestamp;
      // print(newTime.difference(oldTime).inMilliseconds);
      double dt= newTime.difference(oldTime).inMilliseconds/1000;
      oldTime = newTime;
    //делаем первый average
      if (firstRead) {
        avgx = event.x;
        avgy = event.y;
        firstRead = false;

        oldTime = event.timestamp;
        return;
      }
      //если телефон в воздухе, или нет сильного движения
      if (!isOnGround(event.z)||((avgx - event.x).abs() < deadZone && (avgy - event.y).abs() < deadZone)) {
          //усредняем

          physicsHelper.wasStopped();
          accXBuffer.add(event.x);
          accYBuffer.add(event.y);
          if (accXBuffer.length > bufferSize) {
            accXBuffer.removeAt(0);
          }
          if (accYBuffer.length > bufferSize) {
            accYBuffer.removeAt(0);
          }

          

          double oldavgx = avgx;
          double oldavgy = avgy;
          //сохраняем average
          avgx = accXBuffer.fold(0.0, (sum, x) => sum + (x)) / accXBuffer.length;
          avgy = accYBuffer.fold(0.0, (sum, x) => sum + (x)) / accYBuffer.length;
          oldTime = DateTime.now();
         //print("no movement: x:${(event.x - oldavgx).abs()} y:${(event.y - oldavgy).abs()}",);
          return;
      } else {
          double oldavgx = avgx;
          double oldavgy = avgy;
          accXBuffer.clear();
          accYBuffer.clear();
          
          physicsHelper.findDelta(event.x-avgx, event.y-avgy, dt);
          //physicsHelper.findDelta(event.x-biasX, event.y-biasY, dt);

          //сохраняем новый average
          //print("it was a movement: ${event.x} ${event.y}");
          avgx = event.x;
          avgy = event.y;
          accXBuffer.add(event.x);
          accYBuffer.add(event.y);
          if (accXBuffer.length > bufferSize) {
            accXBuffer.removeAt(0);
          }
          if (accYBuffer.length > bufferSize) {
            accYBuffer.removeAt(0);
          }
      }
    });
    

    oldTime = DateTime.now();
  }


    bool isOk=false;

   Future<bool> startConnection(String ip)async{
    if(isConnectionInitialised && isOk){
      serverConnector.connect(ip); 
      print("tut");
      return true;}

    try{
      serverConnector = ServerConnector(ip, this);
      print("server sozdalsa");
      await serverConnector.connect(ip);
      isConnectionInitialised=true;}
    catch(e){
      print(e);
      return false;
    }
    if(isOk){
      startAccelerometerListener();
      return true;
    }
    return false;
   // physicsHelper = PhysicsHelper(serverConnector);
    
  }

  void sendToServer(TypesOfClick signal){
    if(!isConnectionInitialised){
      return;
    }
      switch(signal){
        case TypesOfClick.LEFT_CLICK:
          serverConnector.sendLeftClick();
          break;
        default:
          break;
      }
    }
}


    


  // double roll = 0.0; // Наклон влево-вправо (движение по X)
  // double yaw = 0.0; // Поворот телефона (движение по Y)

  // double x0 = 0.0;
  // double x1 = 0.0;
  // double y0 = 0.0;
  // double y1 = 0.0;
  // double z0 = 0.0;
  // double z1 = 0.0;
  // double vx0 = 0.0;
  // double vx1 = 0.0;
  // double vy0 = 0.0;
  // double vy1 = 0.0;
  // double vz0 = 0.0;
  // double vz1 = 0.0;
  // double dt = 0.016; // 16ms (частота ~60 Гц)
  // double dx = 0.0;
  // double dy = 0.0;
  // double dz = 0.0;
  // double deadZone = 0.05; // "Мертвая зона" (игнорируем мелкие изменения)
  // double floatingZone = 0.1; // "Мертвая зона" (игнорируем мелкие изменения)
  // double ax0 = 0.0;
  // double ax1 = 0.0;
  // double ax2 = 0.0;

  // double avgx = 0.0;
  // double avgy = 0.0;
  // double avgz=0.0;

  // StreamSubscription? gyroscopeSubscription;
  // StreamSubscription? accelerometerSubscription;

  // List<Abstpoint> points = [];

  // bool firstRead = true;
  // double sensitivity = 100; // Чувствительность движения

  // List<double> accXBuffer = []; // Буфер значений по X
  // List<double> accYBuffer = []; // Буфер значений по X
  // List<double> accZBuffer = []; // Буфер значений по X
  // final int bufferSize = 1; // Размер окна (чем больше, тем стабильнее)
  // final int floatingBufferSize = 1; // Размер окна (чем больше, тем стабильнее)
  // final double threshold = 10; // Порог движения (чем меньше, тем чувствительнее)
  // bool isMoving = false; // Флаг движения

  // void testAcceler() {
  //   //print("hi");
  //   accelerometerSubscription = accelerometerEvents.listen((
  //     AccelerometerEvent event,
  //   ) {
  //     print("{x: ${event.x}, y: ${event.y}, z: ${event.z}}");
  //   });
  // }

  // void timeMesaure() {
  //   var oldTime = DateTime.now();
  //   var newTime = DateTime.now();

  //   accelerometerSubscription = accelerometerEvents.listen((
  //     AccelerometerEvent event,
  //   ) {
  //     newTime = DateTime.now();
  //     print(newTime.difference(oldTime).inMilliseconds);
  //     oldTime = newTime;
  //   });
  // }

  // void testGyro() {
  //   int ctr = 0;
  //   gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
  //     if (ctr < 201) {
  //       if (ctr == 200) {
  //         saveToFile("gyro");
  //         //sleep(const Duration(hours: 5));
  //       }
  //       print("{x: ${event.x},\t y: ${event.y},\t z: ${event.z}}");
  //       points.add(new Point1(event.x, event.y, event.z));
  //       ctr++;
  //     }
  //   });
  // }

  // void testAcc() {
  //   int ctr = 0;
  //   accelerometerSubscription = accelerometerEvents.listen((
  //     AccelerometerEvent event,
  //   ) {
  //     if (ctr < 201) {
  //       if (ctr == 200) {
  //         saveToFile("acc");
  //         //sleep(const Duration(hours: 5));
  //       }
  //       print("{x: ${event.x},\t y: ${event.y},\t z: ${event.z}}");
  //       points.add(new Point1(event.x, event.y, event.z));
  //       ctr++;
  //     }
  //   });
  // }

  // void smartGyro() {
  //   gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
  //     double ans =
  //         1 /
  //         (1 +
  //             exp(
  //               -(-0.23284816852948964 +
  //                   0.0018713666405181589 * event.x +
  //                   0.01674713888086815 * event.y +
  //                   0.0038221924972819273 * event.z),
  //             ));
  //     if (ans >= 0.44444444444) {
  //       print("moving yay");
  //     } else {
  //       print(":(");
  //     }
  //   });
  // }

  // void testGyroAcc() {
  //   int ctr = 0;
  //   double lastAx = 0, lastAy = 0, lastAz = 0;
  //   double lastGx = 0, lastGy = 0, lastGz = 0;

  //   StreamGroup<dynamic> sensorGroup = StreamGroup<dynamic>();
  //   sensorGroup.add(gyroscopeEvents);
  //   sensorGroup.add(accelerometerEvents);

  //   sensorGroup.stream.listen((event) {
  //     if (ctr < 201) {
  //       if (ctr == 200) {
  //         saveToFile("gyroAcc");
  //         gyroscopeSubscription?.cancel();
  //         accelerometerSubscription?.cancel();
  //       }

  //       if (event is GyroscopeEvent) {
  //         lastGx = event.x;
  //         lastGy = event.y;
  //         lastGz = event.z;
  //       } else if (event is AccelerometerEvent) {
  //         lastAx = event.x;
  //         lastAy = event.y;
  //         lastAz = event.z;
  //       }
  //       print(
  //         "{ax: $lastAx, ay: $lastAy, az: $lastAz, gx: $lastGx, gy: $lastGy, gz: $lastGz}",
  //       );
  //       points.add(PointUnion(lastAx, lastAy, lastAz, lastGx, lastGy, lastGz));
  //       ctr++;
  //     }
  //   });
  // }

  // void testGyroAcc() {
  //   int ctrg = 0;
  //   int ctra = 0;
  //   //gyrodone=false;
  //   //accdone=false;
  //   StreamGroup<dynamic> sensorGroup = StreamGroup<dynamic>();
  //   sensorGroup.add(gyroscopeEvents);
  //   sensorGroup.add(accelerometerEvents);
  //   // for (int i = 0; i < 201; i++) {
  //   //   points.add(new PointUnion(0, 0, 0, 0, 0, 0));
  //   // }
  //   sensorGroup.stream.listen((event) {
  //     if (ctrg < 201) {
  //       if (ctrg == 200) {
  //         //gyrodone=true;
  //         saveToFile("gyroAcc");
  //         gyroscopeSubscription?.cancel();
  //       }
  //       print("{gx: ${event.x},\t gy: ${event.y},\t gz: ${event.z}}");
  //       PointUnion mama = points[ctrg] as PointUnion;
  //       mama.gx = event.x;
  //       mama.gy = event.y;
  //       mama.gz = event.z;
  //       points[ctrg] = mama;
  //       ctrg++;
  //     }
  //   });

  // }

  //bool gyrodone = true;
  //bool accdone = true;
  // Future<void> saveToFile(String name) async {
  //   if (true) {
  //     try {
  //       var status = await Permission.storage.request();
  //       Directory? directory = Directory(
  //         '/storage/emulated/0/Download',
  //       ); // Для Android
  //       if (!directory.existsSync()) {
  //         directory = await getExternalStorageDirectory();
  //       }
  //       File file = File('${directory!.path}/${name}_data.json');
  //       String jsonString = jsonEncode(points); // Преобразуем в JSON
  //       await file.writeAsString(jsonString); // Асинхронно записываем в файл

  //       print("✅ Данные сохранены в: ${file.path}");
  //     } catch (e) {
  //       print("❌ Ошибка при сохранении файла: $e");
  //     }
  //   }
  // }

  // bool isOnGround(double z){
  //   if((avgz-z).abs() < floatingZone){
  //     accZBuffer.add(z);
        
  //       if (accZBuffer.length > floatingBufferSize) {
  //         accZBuffer.removeAt(0);
  //       }
  //       avgz = accZBuffer.fold(0.0, (sum, x) => sum + (x)) / accZBuffer.length;
  //     //print("on ground");
      
  //     return true;
  //   }
  //  // print("in the sky");
  //   avgz = z;
  //   return false;
  // }

  // void startAccelerometerListenerOld() {
  //   accelerometerSubscription = accelerometerEvents.listen((
  //     AccelerometerEvent event,
  //   ) {
  //     double accX = event.x;
  //     if (firstRead) {
  //       avgx = event.x;
  //       avgy = event.y;
  //       firstRead = false;
  //       return;
  //     }
  //     if (((avgx - event.x).abs() < deadZone && (avgy - event.y).abs() < deadZone)) {
  //       accXBuffer.add(accX);
  //       accYBuffer.add(event.y);
  //       if (accXBuffer.length > bufferSize) {
  //         accXBuffer.removeAt(0);
  //       }
  //       if (accYBuffer.length > bufferSize) {
  //         accYBuffer.removeAt(0);
  //       }

  //       double oldavgx = avgx;
  //       double oldavgy = avgy;
  //       avgx = accXBuffer.fold(0.0, (sum, x) => sum + (x)) / accXBuffer.length;
  //       avgy = accYBuffer.fold(0.0, (sum, x) => sum + (x)) / accYBuffer.length;
  //       print(
  //         "no movement: x:${(event.x - oldavgx).abs()} y:${(event.y - oldavgy).abs()}",
  //       );
  //       return;
  //     } else {
  //       accXBuffer.clear();
  //       accYBuffer.clear();
  //       print("it was a movement: ${event.x} ${event.y}");
  //       avgx = event.x;
  //       avgy = event.y;
  //       accXBuffer.add(accX);
  //       accYBuffer.add(event.y);
  //       if (accXBuffer.length > bufferSize) {
  //         accXBuffer.removeAt(0);
  //       }
  //       if (accYBuffer.length > bufferSize) {
  //         accYBuffer.removeAt(0);
  //       }
  //     }
  //   });
  // }

  // var oldTime = DateTime.now();
  // var newTime = DateTime.now();

  // late PhysicsHelper physicsHelper;
  // late ServerConnector serverConnector;





  // void startAccelerometerListener() {
  //   accelerometerSubscription = accelerometerEvents.listen((
  //     AccelerometerEvent event,
  //   ) {
  //      //меряем время для delta t
  //     newTime = DateTime.now();
  //     // print(newTime.difference(oldTime).inMilliseconds);
  //     double dt= newTime.difference(oldTime).inMilliseconds/1000;
  //     oldTime = newTime;
  //   //делаем первый average
  //     if (firstRead) {
  //       avgx = event.x;
  //       avgy = event.y;
  //       firstRead = false;

  //       oldTime = DateTime.now();
  //       return;
  //     }
  //     //если телефон в воздухе, или нет сильного движения
  //     if (!isOnGround(event.z)||((avgx - event.x).abs() < deadZone && (avgy - event.y).abs() < deadZone)) {
  //         //усредняем

  //         physicsHelper.wasStopped();
  //         accXBuffer.add(event.x);
  //         accYBuffer.add(event.y);
  //         if (accXBuffer.length > bufferSize) {
  //           accXBuffer.removeAt(0);
  //         }
  //         if (accYBuffer.length > bufferSize) {
  //           accYBuffer.removeAt(0);
  //         }

          

  //         double oldavgx = avgx;
  //         double oldavgy = avgy;
  //         //сохраняем average
  //         avgx = accXBuffer.fold(0.0, (sum, x) => sum + (x)) / accXBuffer.length;
  //         avgy = accYBuffer.fold(0.0, (sum, x) => sum + (x)) / accYBuffer.length;
  //         oldTime = DateTime.now();
  //        //print("no movement: x:${(event.x - oldavgx).abs()} y:${(event.y - oldavgy).abs()}",);
  //         return;
  //     } else {
  //         double oldavgx = avgx;
  //         double oldavgy = avgy;
  //         accXBuffer.clear();
  //         accYBuffer.clear();
          
  //         physicsHelper.findDelta(event.x-avgx, event.y-avgy, dt);

  //         //сохраняем новый average
  //         //print("it was a movement: ${event.x} ${event.y}");
  //         avgx = event.x;
  //         avgy = event.y;
  //         accXBuffer.add(event.x);
  //         accYBuffer.add(event.y);
  //         if (accXBuffer.length > bufferSize) {
  //           accXBuffer.removeAt(0);
  //         }
  //         if (accYBuffer.length > bufferSize) {
  //           accYBuffer.removeAt(0);
  //         }
  //     }
  //   });

  //   oldTime = DateTime.now();
  // }