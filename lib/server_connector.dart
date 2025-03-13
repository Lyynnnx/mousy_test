import 'dart:io';

import 'package:mouse_test/main_logic.dart';
import 'package:mouse_test/physics_helper.dart';
import 'package:mouse_test/frontend.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ServerConnector {
  late WebSocketChannel channel;
  bool isConnected=false;
  late MainLogic state;
  ServerConnector(String ip, MainLogic state)  {
    this.state = state;
    print("hello");
   // channel = WebSocketChannel.connect(Uri.parse('ws://192.168.178.22:8765'));
   
    //connect(ip);
  }




  Future<bool> isHostReachable(String ip) async {
  try {
    final result = await InternetAddress.lookup(ip);
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch (e) {
    print("❌ Хост недоступен: $e");
  }
  return false;
}

Future<bool> isWebSocketReachable(String ip, {int port = 8765, Duration timeout = const Duration(seconds: 2)}) async {
  try {
    final socket = await Socket.connect(ip, port, timeout: timeout);
    socket.destroy(); // Закрываем соединение сразу же
    return true; // ✅ Хост доступен
  } catch (e) {
    print("❌ WebSocket недоступен на $ip:$port → $e");
    return false; // ❌ Хост недоступен
  }
}

  Future<void> connect(String ip)async{
    print("trying to connect");
     if(isConnected){
      print("its me");
      end();
    }
    isConnected=true;
    try{
      if(await isWebSocketReachable(ip)){
           channel = WebSocketChannel.connect(Uri.parse('ws://$ip:8765'));
           state.physicsHelper=PhysicsHelper(this);
           state.isOk=true;
           return;
      }
    }
    catch(e){
      print("e");
    }
    return;
  }


   void sendCursorMovement(double dx, double dy) {
    // double dx_old = dx;
    // double dy_old = dy;
    // dx = (roll - rollOffset) * sensitivity;
    // dy = (yaw - yawOffset) * sensitivity;

    // //Если изменения меньше порога, не двигаем курсор (чтобы курсор не дрейфил)
    // if (dx.abs() < deadZone) dx = 0;
    // if (dy.abs() < deadZone) dy = 0;

    // if ((dx - dx_old).abs() < deadZone) return;
    // if ((dy - dy_old).abs() < deadZone) return;
    // print("$dx_old,$dx, $dy_old, $dy, ${dx - dx_old}, ${dy - dy_old}");

    // Отправляем только если движение есть
    if (dx != 0 || dy != 0) {
      channel.sink.add("movement,${dx},${dy}");
    }
  }

  void sendLeftClick(){
    channel.sink.add("leftclick");
  }

  void end(){
    channel.sink.close();
    isConnected=false;
    //print("end");
  }


}