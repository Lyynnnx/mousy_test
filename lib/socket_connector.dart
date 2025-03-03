import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketConnector extends StatefulWidget {
  const SocketConnector({super.key});

  @override
  State<SocketConnector> createState() => _SocketConnectorState();
}



class _SocketConnectorState extends State<SocketConnector> {

  
  double accX = 0, accY = 0, accZ = 0; // Акселерометр (ускорение)
  double gyroX = 0, gyroY = 0, gyroZ = 0; // Гироскоп (вращение)
  double magX = 0, magY = 0, magZ = 0; // Магнитометр (ориентация)
  Timer? _timer;
 WebSocketChannel channel = WebSocketChannel.connect(Uri.parse('ws://192.168.2.167:8765'));


@override
void initState() {
  super.initState();
  channel = WebSocketChannel.connect(Uri.parse('ws://192.168.2.167:8765'));
  startTracking();
} 

@override
  void dispose() {
    _timer?.cancel();
    channel.closeReason;
    super.dispose();
  }


void startTracking() {

  accelerometerEvents.listen((AccelerometerEvent event) {
      
        accX = event.x;
        accY = event.y;
        accZ = event.z;
      
    });

    // Отслеживание гироскопа
    gyroscopeEvents.listen((GyroscopeEvent event) {
      
        gyroX = event.x;
        gyroY = event.y;
        gyroZ = event.z;
      
    });

    // Отслеживание магнитометра (если нужно)
    magnetometerEvents.listen((MagnetometerEvent event) {
      
        magX = event.x;
        magY = event.y;
        magZ = event.z;
     
    });
  
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // final dx = _currentPosition.dx - _previousPosition.dx;
          // final dy = _currentPosition.dy - _previousPosition.dy;
          // print("X: ${_currentPosition.dx}, Y: ${_currentPosition.dy} | ΔX: $dx, ΔY: $dy");

          // _previousPosition = _currentPosition;
        });
      }
    });
  }

void SendRandom(){
  print("send random");
  channel.sink.add("1");
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Socket Connector"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Accelerometer: X: $accX, Y: $accY, Z: $accZ", style: TextStyle(fontSize: 5),),
            Text("Gyroscope: X: $gyroX, Y: $gyroY, Z: $gyroZ", style: TextStyle(fontSize: 5),),
            
            ElevatedButton(onPressed: SendRandom, child: Text("Send Random")),
          ],
        ),
      ),
    );
  }
}