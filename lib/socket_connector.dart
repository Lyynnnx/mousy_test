import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketConnector extends StatefulWidget {
  const SocketConnector({super.key});

  @override
  State<SocketConnector> createState() => _SocketConnectorState();
}

class _SocketConnectorState extends State<SocketConnector> {
  double roll = 0.0;  // Наклон влево-вправо (движение по X)
  double yaw = 0.0;   // Поворот телефона (движение по Y)

  double dx = 0.0;
  double dx_old=0.0;
  double dy = 0.0;
  double dy_old=0.0;

  double rollOffset = 0.0; // Начальные значения для калибровки
  double yawOffset = 0.0;

  double sensitivity = 100; // Чувствительность движения
  double deadZone = 1;   // "Мертвая зона" (игнорируем мелкие изменения)

  late WebSocketChannel channel;
  bool firstRead = true;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse('ws://192.168.2.167:8765'));
    startTracking();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void startTracking() {
    gyroscopeEvents.listen((event) {
      double dt = 0.016; // 16ms (частота ~60 Гц)

      roll += event.x * dt;
      yaw += event.z * dt;

      if (firstRead) {
        rollOffset = roll;
        yawOffset = yaw;
        firstRead = false;
      }

      sendCursorMovement();
    });

    accelerometerEvents.listen((event) {
      double accelRoll = atan2(event.x, event.z) * 180 / pi;
      double accelYaw = atan2(event.y, event.z) * 180 / pi;

      roll = roll * 0.98 + accelRoll * 0.02;
      yaw = yaw * 0.98 + accelYaw * 0.02;

      sendCursorMovement();
    });
  }

  void sendCursorMovement() {
    dx_old=dx;
    dy_old=dy;
    dx = (roll - rollOffset) * sensitivity;
    dy = (yaw - yawOffset) * sensitivity;

    // Если изменения меньше порога, не двигаем курсор (чтобы курсор не дрейфил)
    //if (dx.abs() < deadZone) dx = 0;
    //if (dy.abs() < deadZone) dy = 0;
    
    if((dx-dx_old).abs() < deadZone) return;
    if((dy-dy_old).abs() < deadZone) return;
print("$dx_old,$dx, $dy_old, $dy, ${dx-dx_old}, ${dy-dy_old}" );
    

    // Отправляем только если движение есть
    if (dx != 0 || dy != 0) {
      channel.sink.add("movement,${dx},${dy}");
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
            Text("Roll (X-axis): ${roll.toStringAsFixed(2)}°"),
            Text("Yaw (Z-axis): ${yaw.toStringAsFixed(2)}°"),
            ElevatedButton(
              onPressed: () {
                channel.sink.add("1");
              },
              child: Text("Send Test Signal"),
            ),
          ],
        ),
      ),
    );
  }
}
