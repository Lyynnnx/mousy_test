import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:mouse_test/abstpoint.dart';
import 'package:mouse_test/direction.dart';
import 'package:mouse_test/physics_helper.dart';
import 'package:mouse_test/server_connector.dart';
import 'package:mouse_test/types_of_click.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sensors_plus/sensors_plus.dart' as dchsMotionSensors;
import 'package:simple_kalman/simple_kalman.dart';


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
  double deadZone = 0.1; // "Мертвая зона" (игнорируем мелкие изменения)
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
    
    accelerometerSubscription = accelerometerEventStream(samplingPeriod: Duration(milliseconds: 50)).listen(
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




// final kalmanX = SimpleKalman(errorMeasure: 150, errorEstimate: 200, q: 0.8);
// final kalmanY = SimpleKalman(errorMeasure: 1, errorEstimate: 100, q: 0.2);
      

//   void startAccelerometerListenerKalman() {
    
//     accelerometerSubscription = accelerometerEvents.listen(
//       (
//       AccelerometerEvent event,
//     ) {
//       double x1=kalmanX.filtered(event.x);
//       double y1=kalmanY.filtered(event.y);

      
//        //меряем время для delta t
//       newTime = event.timestamp;
//       // print(newTime.difference(oldTime).inMilliseconds);
//       double dt= newTime.difference(oldTime).inMilliseconds/1000;
//       oldTime = newTime;
//     //делаем первый average
//       if (firstRead) {
//         avgx = x1;
//         avgy = y1;
//         firstRead = false;

//         oldTime = event.timestamp;
//         return;
//       }
//       //если телефон в воздухе, или нет сильного движения
//       if (!isOnGround(event.z)||((avgx - x1).abs() < deadZone && (avgy - y1).abs() < deadZone)) {
//           //усредняем

//           physicsHelper.wasStopped();
//           accXBuffer.add(x1);
//           accYBuffer.add(y1);
//           if (accXBuffer.length > bufferSize) {
//             accXBuffer.removeAt(0);
//           }
//           if (accYBuffer.length > bufferSize) {
//             accYBuffer.removeAt(0);
//           }

          

//           double oldavgx = avgx;
//           double oldavgy = avgy;
//           //сохраняем average
//           avgx = accXBuffer.fold(0.0, (sum, x) => sum + (x)) / accXBuffer.length;
//           avgy = accYBuffer.fold(0.0, (sum, x) => sum + (x)) / accYBuffer.length;
//           oldTime = DateTime.now();
//          //print("no movement: x:${(event.x - oldavgx).abs()} y:${(event.y - oldavgy).abs()}",);
//           return;
//       } else {
//           double oldavgx = avgx;
//           double oldavgy = avgy;
//           accXBuffer.clear();
//           accYBuffer.clear();
          
//           physicsHelper.findDelta(x1-avgx, y1-avgy, dt);
//           //physicsHelper.findDelta(event.x-biasX, event.y-biasY, dt);

//           //сохраняем новый average
//           //print("it was a movement: ${event.x} ${event.y}");
//           avgx = x1;
//           avgy = y1;
//           accXBuffer.add(x1);
//           accYBuffer.add(y1);
//           if (accXBuffer.length > bufferSize) {
//             accXBuffer.removeAt(0);
//           }
//           if (accYBuffer.length > bufferSize) {
//             accYBuffer.removeAt(0);
//           }
//       }
//     });
    

//     oldTime = DateTime.now();
//   }

  List<double> mxBuffer=[];
  List<double> myBuffer=[];
  int mBufferSize=2;
  double avgMx=0;
  double avgMy=0;
  double mDeadZone=0.02;
  bool mFirstRead=true;


  double biasX = 0, biasY = 0, biasZ = 0;
bool calibrated = false;

void calibrate(double x, double y) {
  biasX = x;
  biasY = y;
  calibrated = true;
}

  List<Direction> directionFounder(double mx, double my){
    //log( "$mx $my");
    if(!calibrated) calibrate(mx, my);
    mx-=biasX;
    my-=biasY;
    List<Direction> ans=[];
    String answerX="";  
    String answerY="";  
    if(mFirstRead){
      avgMx=mx;
      avgMy=my;
      mFirstRead=false;
      ans.add(Direction.NO_MOVEMENT);
      ans.add(Direction.NO_MOVEMENT);
      return ans;
    }
    if((mx-avgMx).abs() < mDeadZone){
      mxBuffer.add(mx);    
      if (mxBuffer.length > mBufferSize) {
        mxBuffer.removeAt(0);
      }
      for(int i=0;i<mxBuffer.length;i++){
        avgMx+=mxBuffer[i]* (1/(mxBuffer.length-i));
      }
      //avgMx = mxBuffer.fold(0.0, (sum, x) => sum + (x)) / mxBuffer.length;
      answerX="no movement";
      ans.add(Direction.NO_MOVEMENT);
    } 
    else{
      if(mx>avgMx){
        answerX="right";
        ans.add(Direction.RIGHT);
        avgMx=mx;
      }
      else{
        answerX="left";
        ans.add(Direction.LEFT);
        avgMx=mx;
      }
    }

    if((my-avgMy).abs() < mDeadZone){
      myBuffer.add(my);    
      if (myBuffer.length > mBufferSize) {
        myBuffer.removeAt(0);
      }
      avgMy = myBuffer.fold(0.0, (sum, x) => sum + (x)) / myBuffer.length;
      ans.add(Direction.NO_MOVEMENT);
      answerY="no movement";
    } 
    else{
      if(my>avgMy){
        ans.add(Direction.UP);
        answerY="up";
        avgMy=my;
      }
      else{
        ans.add(Direction.DOWN);
        answerY="down";
        avgMy=my;
      }
    }

    return ans;


  } 




  void dataScanning(List<List<dynamic>> values) {
    if (isProcessing) return; // Пропуск, если обработка не завершена
        isProcessing = true;

      var accel = values[0]; // Данные акселерометра
      var mag = values[1];   // Данные магнитометра
      var gyr = values[2];
    
      double ax=accel[0] as double;
      double ay=accel[1] as double;
      double az=accel[2] as double;

      double mx=mag[0] as double;
      double my=mag[1] as double;
      double mz=mag[2] as double;

      double gx=gyr[0] as double;
      double gy=gyr[1] as double;
      double gz=gyr[2] as double;

      var ans=directionFounder(gx, gy);
      log("direction: ${ans[0]} ${ans[1]}");

       //меряем время для delta t
      newTime = accel[3] as DateTime;
      // print(newTime.difference(oldTime).inMilliseconds);
      double dt= newTime.difference(oldTime).inMilliseconds/1000;
      oldTime = newTime;
    //делаем первый average
      if (firstRead) {
        avgx = ax;
        avgy = ay;
        firstRead = false;

        oldTime = accel[3] as DateTime;
        isProcessing = false;
        return;
      }
      //если телефон в воздухе, или нет сильного движения
      if (!isOnGround(az)||((avgx -ax).abs() < deadZone && (avgy - ay).abs() < deadZone)) {
          //усредняем

          physicsHelper.wasStopped();
          accXBuffer.add(ax);
          accYBuffer.add(ay);
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
          isProcessing = false;
          return;
      } else {
          double oldavgx = avgx;
          double oldavgy = avgy;
          accXBuffer.clear();
          accYBuffer.clear();
          
          physicsHelper.findDelta(ax-avgx, ay-avgy, dt);
          //physicsHelper.findDelta(event.x-biasX, event.y-biasY, dt);

          //сохраняем новый average
          //print("it was a movement: ${event.x} ${event.y}");
          avgx = ax;
          avgy = ay;
          accXBuffer.add(ax);
          accYBuffer.add(ay);
          if (accXBuffer.length > bufferSize) {
            accXBuffer.removeAt(0);
          }
          if (accYBuffer.length > bufferSize) {
            accYBuffer.removeAt(0);
          }
      }
      isProcessing = false;
    
    //isProcessing = false;
    oldTime = DateTime.now();
  }








  bool isProcessing=false;
  late StreamSubscription magnetometerSubscription;
  void startAccelerometerListenerMagnetometer() {
    
     final accelStream = accelerometerEventStream(samplingPeriod: Duration(milliseconds: 100)).map((event) => [event.x, event.y, event.z, event.timestamp]);
     final magStream =magnetometerEvents.map((e) => [e.x, e.y, e.z, e.timestamp]);
     final gyrStream = gyroscopeEvents.map((e) => [e.x, e.y, e.z, e.timestamp]);
     StreamZip([accelStream, magStream, gyrStream]).listen((values)async {
        

      //  if (isProcessing) return; // Пропуск, если обработка не завершена
      //   isProcessing = true;

      var accel = values[0]; // Данные акселерометра
      var mag = values[1];   // Данные магнитометра
      var gyr = values[2];
    
      double ax=accel[0] as double;
      double ay=accel[1] as double;
      double az=accel[2] as double;

      double mx=mag[0] as double;
      double my=mag[1] as double;
      double mz=mag[2] as double;

      double gx=gyr[0] as double;
      double gy=gyr[1] as double;
      double gz=gyr[2] as double;

      var ans=directionFounder(gx, gy);
      //log("direction: ${ans[0]} ${ans[1]}");
      //return;
       //меряем время для delta t
      newTime = accel[3] as DateTime;
      // print(newTime.difference(oldTime).inMilliseconds);
      double dt= newTime.difference(oldTime).inMilliseconds/1000;
      oldTime = newTime;
    //делаем первый average
      if (firstRead) {
        avgx = ax;
        avgy = ay;
        firstRead = false;

        oldTime = accel[3] as DateTime;
        isProcessing = false;
        return;
      }
      //если телефон в воздухе, или нет сильного движения
      if (!isOnGround(az)||((avgx -ax).abs() < deadZone && (avgy - ay).abs() < deadZone)) {
          //усредняем

          physicsHelper.wasStopped();
          accXBuffer.add(ax);
          accYBuffer.add(ay);
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
          isProcessing = false;
          return;
      } else {
          double oldavgx = avgx;
          double oldavgy = avgy;
          accXBuffer.clear();
          accYBuffer.clear();
          
          physicsHelper.findDelta(ax-avgx, ay-avgy, dt);
          //physicsHelper.findDelta(event.x-biasX, event.y-biasY, dt);

          //сохраняем новый average
          //print("it was a movement: ${event.x} ${event.y}");
          avgx = ax;
          avgy = ay;
          accXBuffer.add(ax);
          accYBuffer.add(ay);
          if (accXBuffer.length > bufferSize) {
            accXBuffer.removeAt(0);
          }
          if (accYBuffer.length > bufferSize) {
            accYBuffer.removeAt(0);
          }
      }
      isProcessing = false;
    });
    
    //isProcessing = false;
    oldTime = DateTime.now();
  }
  //  void startAccelerometerListenerMagnetometer() {
  //  // SensorInterval();
    
  //  // final accelStream = accelerometerEventStream(samplingPeriod: Duration(milliseconds: 100)).map((e) => [e.x, e.y, e.z, e.timestamp]);
  //   final accelStream = accelerometerEvents.map((e) => [e.x, e.y, e.z, e.timestamp]);
  //   //final magStream = magnetometerEvents.map((e) => [e.x, e.y, e.z, e.timestamp]);
  //   //dchsMotionSensors.accelerometerEvents. setUpdateInterval(SensorType.Gyroscope, 50000);
      
  //     final magStream = magnetometerEventStream(samplingPeriod: Duration(milliseconds: 100)).map((e) => [e.x, e.y, e.z, e.timestamp]);

  //    StreamZip([accelStream, magStream]).listen((values) {
  //     var accel = values[0]; // Данные акселерометра
  //     var mag = values[1];   // Данные магнитометра
    
  //     double ax=accel[0] as double;
  //     double ay=accel[1] as double;
  //     double az=accel[2] as double;

  //     double mx=mag[0] as double;
  //     double my=mag[1] as double;
  //     double mz=mag[2] as double;

  //     //print("$mx, $my, $mz");
  //     //return;
  //     //List<Direction> direction =directionFounder(mx, my);
      
  //      //меряем время для delta t
  //     newTime = accel[3] as DateTime;
     
  //     double dt= newTime.difference(oldTime).inMilliseconds/1000;
  //     oldTime = newTime;
  //   //делаем первый average
  //     if (firstRead) {
  //       avgx =ax;
  //       avgy = ay;
  //       firstRead = false;

  //       oldTime =accel[3] as DateTime;
  //       return;
  //     }
  //     //если телефон в воздухе, или нет сильного движения
  //     if (!isOnGround(az)||((avgx - ax).abs() < deadZone && (avgy - ay).abs() < deadZone)) {
  //         //усредняем

  //         physicsHelper.wasStopped();
  //         accXBuffer.add(ax);
  //         accYBuffer.add(ay);
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
  //        //print("no movement: x:${(ax - oldavgx).abs()} y:${(ay - oldavgy).abs()}",);
  //         return;
  //     } else {
  //         double oldavgx = avgx;
  //         double oldavgy = avgy;
  //         accXBuffer.clear();
  //         accYBuffer.clear();
          
  //         //physicsHelper.findDeltaMagnitometer(ax-avgx, ay-avgy, dt, direction[0], direction[1] );
  //         physicsHelper.findDelta(ax-avgx, ax-avgy, dt);
  //         //physicsHelper.findDelta(event.x-avgx, event.y-avgy, dt);

  //         //сохраняем новый average
  //         //log("it was a movement: ${ax} ${ay} + ${direction[0]} ${direction[1]}");
  //         avgx = ax;
  //         avgy = ay;
  //         accXBuffer.add(ax);
  //         accYBuffer.add(ay);
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
        case TypesOfClick.DOUBLE_CLICK:
          serverConnector.sendDoubleClick();
          break;
        case TypesOfClick.RIGHT_CLICK:
          serverConnector.sendRightClick();
          break;
        case TypesOfClick.SCROLL_DOWN:
          serverConnector.sendScrollDown();
          break;
        case TypesOfClick.SCROLL_UP:
          serverConnector.sendScrollUp();
          break;
        case TypesOfClick.LONG_LEFT_START:
          serverConnector.sendLongLeftStart();
          break;
        case TypesOfClick.LONG_LEFT_END:
          serverConnector.sendLongLeftEnd();
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