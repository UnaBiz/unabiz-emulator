//  Based on https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing
import processing.serial.*;

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port

void setup() {
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 9600);
}

void draw() {
  if (myPort.available() > 0) {  // If data is available,
    val = myPort.readStringUntil('\n');         // read it and store it in val
  } 
  if (val != null) print(val); // print it out in the console
  val = null;
}