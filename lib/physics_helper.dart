import 'package:mouse_test/server_connector.dart';

class PhysicsHelper {


  double x0=0;
  double x1=0;
  double y0=0;
  double y1=0;
  double z0=0;
  double z1=0;
  double vx0=0;
  double vx1=0;
  double vy0=0;
  double vy1=0;
  double vz0=0;
  double vz1=0;
  double dt=0;

  double prevax=0;
  double prevay=0;
  double dx=0;
  double dy=0;

  List<double> bufferX = [];
   List<double> bufferY = [];
  int bufferSize = 7;

double smoothValueX(double newValue) {
  bufferX.add(newValue);
  if (bufferX.length > bufferSize) {
    bufferX.removeAt(0);
  }
  return bufferX.reduce((a, b) => a + b) / bufferX.length;
}


double smoothValueY(double newValue) {
  bufferY.add(newValue);
  if (bufferY.length > bufferSize) {
    bufferY.removeAt(0);
  }
  return bufferY.reduce((a, b) => a + b) / bufferY.length;
}

  late ServerConnector serverConnector;
  PhysicsHelper(ServerConnector serverConnector){
    this.serverConnector=serverConnector;
  }


  void wasStopped(){
    print(":(");
    vx0*=0.5;
    vy0*=0.5;
    x0=0;
    y0=0;
    //prevax=0;
    //prevay=0;
    // bufferY.add(0);
    // if (bufferY.length > bufferSize) {
    // bufferY.removeAt(0);
    // }
    // bufferX.add(0);
    // if (bufferX.length > bufferSize) {
    // bufferX.removeAt(0);
    // }
    prevax=smoothValueX(0);
    prevax=smoothValueX(0);
    prevax=smoothValueX(0);
    prevay=smoothValueY(0);
    prevay=smoothValueY(0);
    prevay=smoothValueY(0);
  }


  void findDelta(double ax, double ay, double dt) {
    //print("$ax $ay $dt");
    //переводим в см
    //переводим в см

    //print("$ax $ay $dt");

    

   
    ax = (ax.abs() < 0.02) ? 0 : ax;
    ay = (ay.abs() < 0.02) ? 0 : ay;

    if ((ax > 0 && prevax < 0) || (ax < 0 && prevax > 0)) ax = 0;
    if ((ay > 0 && prevay < 0) || (ay < 0 && prevay > 0)) ay = 0;

    ax= smoothValueX(ax);
    ay= smoothValueY(ay);

    double alpha = 0.4;
    ax = alpha * ax + (1 - alpha) * prevax;
    ay = alpha * ay + (1 - alpha) * prevay;
    if(ax==0 && ay==0){
      wasStopped();
      return;}
    //  ax-=prevax;
    // ay-=prevay; 

    

    // const double threshold = 0.03;
    // if ((ax - prevax).abs() < threshold) ax = prevax;
    // if ((ay - prevay).abs() < threshold) ay = prevay;

    print("$ax $ay $dt");
    prevax = ax;
    prevay = ay;
    vx1 = ax * dt + vx0;
    vy1 = ay * dt + vy0;

    // if (vx1.abs() < 0.01) vx1 = 0;
    // if (vy1.abs() < 0.01) vy1 = 0;

     vx1 *= 0.9;
      vy1 *= 0.9;

    // Интегрируем скорость -> перемещение
    x1 = x0 + vx1 * dt;
    y1 = y0 + vy1 * dt;

    dx = x1 - x0;
    dy = y1 - y0;
   
    print("Δx: ${dx*100} ${dy*100}");
    //print("$x1 $y1");
    print("-----------------");
    if(ax!=0 || ay!=0){
      serverConnector.sendCursorMovement(dx*10, dy*10);
      
    }
    x0 = x1;
    y0 = y1;
    z0 = z1;
    vx0 = vx1;
    vy0 = vy1;
    //vx0=0;
    //vy0=0;
    
    //wasStopped();
    
  }


 



}