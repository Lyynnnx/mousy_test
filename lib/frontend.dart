import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:mouse_test/abstpoint.dart';
import 'package:mouse_test/main_logic.dart';
import 'package:mouse_test/physics_helper.dart';
import 'package:mouse_test/point.dart';
import 'package:mouse_test/point_union.dart';
import 'package:mouse_test/server_connector.dart';
import 'package:mouse_test/types_of_click.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketConnector extends StatefulWidget {
  const SocketConnector({super.key});

  @override
  State<SocketConnector> createState() => _SocketConnectorState();
}

class _SocketConnectorState extends State<SocketConnector> {

  MainLogic mainLogic = MainLogic();
  bool userMode=false;
  final formatKey = GlobalKey<FormState>();
  bool isValidationOk=true;
  bool isTryingToConnect=false;
  String hardCodedIp="192.168.178.82";

  @override
  void initState() {
    print("погнали");
    super.initState();

  }


  @override
  void dispose() {
    mainLogic.serverConnector.end();
    mainLogic.accelerometerSubscription?.cancel();
    mainLogic.gyroscopeSubscription?.cancel();
    super.dispose();
  }

  // void testTracking() {
  //   print("hi");
  //   accelerometerEvents.listen((event) {
  //     //double dt = 0.016; // 16ms (частота ~60 Гц)
  //     print("${event.x} ${event.y} ${event.z}");
  //     //   if(event.x* sensitivity<deadZone && event.y*sensitivity<deadZone){return;} //return;
  //     //   vx1 = event.x * dt + vx0;
  //     //   vy1 = event.y * dt + vy0;
  //     //   vz1 = event.z * dt + vz0;
  //     //   x1 = x0 + vx0 * dt + 0.5 * event.x * dt * dt;
  //     //   dx = x1 - x0;
  //     //   y1 = y0 + vy0 * dt + 0.5 * event.y * dt * dt;
  //     //   dy = y1 - y0;
  //     //  z1 = z0 + vz0 * dt + 0.5 * event.z * dt * dt;
  //     //   dz = z1 - z0;
  //     //   sendCursorMovement(dx, dy);
  //     //   x0 = x1;
  //     //   y0 = y1;
  //     //   z0 = z1;
  //     //   vx0 = vx1;
  //     //   vy0 = vy1;
  //     //   vz0 = vz1;

  //     // ax0=ax1;
  //     // ax1=ax2;
  //     // ax2=event.x;
  //     // avgx=(ax0+ax1+ax2)/2;
  //     // if( ((avgx-(event.x)).abs()*sensitivity )<deadZone){
  //     //   print("it doesn't move $ax0 $ax1 $ax2, ${(avgx-(event.x)).abs()*sensitivity}");
  //     // }
  //   });
  //   // sendCursorMovement(dx, dy);
  // }

  // void startTracking() {
  //   // accelerometerEventStream().listen((event) {
  //   //   double dt = 0.016; // 16ms (частота ~60 Гц)

  //   //   roll += event.x * dt;
  //   //   yaw += event.z * dt;

  //   //   if (firstRead) {
  //   //     rollOffset = roll;
  //   //     yawOffset = yaw;
  //   //     firstRead = false;
  //   //   }

  //   //   sendCursorMovement(roll, yaw);
  //   // });

  //   // gyroscopeEventStream().listen((event) {
  //   //   double accelRoll = atan2(event.x, event.z) * 180 / pi;
  //   //   double accelYaw = atan2(event.y, event.z) * 180 / pi;

  //   //   roll = roll * 0.98 + accelRoll * 0.02;
  //   //   yaw = yaw * 0.98 + accelYaw * 0.02;

  //   //   sendCursorMovement(roll, yaw);
  //   // });
  // }

  // void sendCursorMovement(double dx, double dy) {
  //   // double dx_old = dx;
  //   // double dy_old = dy;
  //   // dx = (roll - rollOffset) * sensitivity;
  //   // dy = (yaw - yawOffset) * sensitivity;

  //   // //Если изменения меньше порога, не двигаем курсор (чтобы курсор не дрейфил)
  //   // if (dx.abs() < deadZone) dx = 0;
  //   // if (dy.abs() < deadZone) dy = 0;

  //   // if ((dx - dx_old).abs() < deadZone) return;
  //   // if ((dy - dy_old).abs() < deadZone) return;
  //   // print("$dx_old,$dx, $dy_old, $dy, ${dx - dx_old}, ${dy - dy_old}");

  //   // Отправляем только если движение есть
  //   if (dx != 0 || dy != 0) {
  //     channel.sink.add("movement,${dx},${dy}");
  //   }
  // }
  

  void saveIp(){
 
    if(userMode){
     
      if(formatKey.currentState!.validate()){
      formatKey.currentState!.save();
    }
    }
    else{
      print(":)");
      formatKey.currentState!.save();
    }
    
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("IMU Mouse Controller")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){
              mainLogic.sendToServer(TypesOfClick.LEFT_CLICK);

            }, child: Text("Left Click")),
            Text("Enter your Server ip:"),
            Form(key: formatKey,
              child: TextFormField(
                validator: (value){
                  if(!isValidationOk){
                     isValidationOk=true;
                    return "Wrong IP, please try another one";
                  }
                  if(value == null || value.isEmpty){
                    return "Please enter your server ip";
                  }
                  return null;
                },
                onSaved: (newValue){
                  print("hi");
                  if(!userMode){
                    newValue=hardCodedIp;
                  }
                  setState((){
                    isTryingToConnect=true;
                  });
                  Future<bool> result =  mainLogic.startConnection(newValue!);
                  result.then((value) {
                    if(!value){
                      isValidationOk=false;
                      formatKey.currentState!.validate();
                      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection failed, try another ip")));
                    }
                    else{
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection successful")));
                    }
                  });
                  setState((){
                    isTryingToConnect=false;;
                  });
                },
                
            ),),
            isTryingToConnect?CircularProgressIndicator():
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    //print("pressed");
                      saveIp();
                    // channel.sink.add("1");
                  },
                  child: Text("Connect!"),
                ),
                ElevatedButton(
                  child:SizedBox(width: 100, height:100, child: Text("отделить",)),
                  onPressed: (){
                    print("##################################################################################################");
                  },
                )
              ],
              
            ),
          ],
        ),
      ),
    );
  }
}
