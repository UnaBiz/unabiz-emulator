//  Based on https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing
import processing.serial.*;

Serial myPort;  // Create object from Serial class
String line;     // Data received from the serial port

void setup() {
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 9600);
}

void draw() {
  if (myPort.available() > 0) {  // If data is available,
    line = myPort.readStringUntil('\n');         // read it and store it in val
  } 
  if (line != null) {
    print(line);
    processMessage(line);  //  Send the line to UnaCloud or AWS if necessary.
  }
  line = null;
}

void processMessage(String line) {  
  //  Watch for messages with payload e.g.
  //  - Radiocrafts.sendMessage: g88pi,920e1e00b051680194597b00
  String marker = "Radiocrafts.sendMessage:";
  if (line == null) return;
  int pos = line.indexOf(marker);
  if (pos < 0) return;
  
  String msg = line.substring(pos + marker.length()).trim();
  String[] msgArray = msg.split(",");
  String device = msgArray[0];
  String data = msgArray[1];
  println("device=" + device);
  println("data=" + data);
}