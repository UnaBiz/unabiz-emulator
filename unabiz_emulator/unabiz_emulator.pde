//  Read the debug output from the Arduino device to watch out for SIGFOX
//  messages sent by the device.  Send a copy of the message to UnaCloud / AWS
//  to emulate thw tansmission of the message to the cloud.
//  Based on https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing
import processing.serial.*;
import http.requests.*;

//  If you have multiple serial ports, change this number to select the specific port.
//  Valid values: 0 to (total number of ports) - 1.
static int serialPortIndex = 0;

static String[] emulateServerURLs = {  //  URLs for the SIGFOX emulation servers.
  //  Can't use https because need to install SSL cert locally. So we use nginx to run
  //  a http proxy to https.  See nginx.conf.
  //  "https://l0043j2svc.execute-api.us-west-2.amazonaws.com/prod/ProcessSIGFOXMessage"
  "http://chendol.tp-iot.com/prod/ProcessSIGFOXMessage"  //  nginx proxy to API Gateway.
};

Serial arduinoPort;  // Serial port connected to Arduino debug output.
String line;     // Data received from the serial port

void setup() {  //  Will be called only once.
  //  Open the serial port that connects to the Arduino device.
  String[] serialPorts = Serial.list();
  println("Found COM / serial ports: " + join(serialPorts, ", "));
  if (serialPortIndex >= serialPorts.length) {
    if (serialPorts.length == 0)
      println("****Error: No COM / serial ports found. Check your Arduino USB connection");
    else if (serialPortIndex > 0)
      println("****Error: No COM / serial ports found at index " + str(serialPortIndex) + 
        ". Edit unabiz_emulator.pde, change serialPortIndex to a number between 0 and " +
        str(serialPorts.length - 1));
    exit();
  }
  String portName = Serial.list()[serialPortIndex];
  println("Connecting to Arduino at port " + portName + "...");
  arduinoPort = new Serial(this, portName, 9600);  
  //  Upon connection, the Arduino will automatically restart the sketch.
}

void draw() {  //  Will be called when screen needs to be refreshed.
  //  Receive one line at a time from the serial port, which is connected
  //  to the debug output of the Arduino.
  if (arduinoPort.available() > 0) {  // If data is available,
    line = arduinoPort.readStringUntil('\n');         // read it and store it in val
  } 
  if (line != null) {
    print(line);
    processMessage(line);  //  Send the line to UnaCloud or AWS if necessary.
  }
  line = null;
}

void sendEmulatedMessage(String device, String data) {
  //  Send a message to UnaCloud or AWS to emulate a device message.
  String json = "{\"device\": \"" + device + "\", \"data\": \"" + data + "\"}";
  println("Emulating SIGFOX message:" + json + "...");
  for (String url: emulateServerURLs) {
    //  For each emulate server URL, send the device and data.
    JSONRequest post = new JSONRequest(url);
    post.addHeader("Content-Type", "application/json");
    post.addJson(json);
    post.send();
    println("Emulate server reponse:" + post.getContent());
  }
}

void processMessage(String line) {  
  //  Watch for messages with markers and process them.
  String[] markers = {
    "Radiocrafts.sendMessage:",  //  - Radiocrafts.sendMessage: g88pi,920e1e00b051680194597b00
    "STOPSTOPSTOP:"  //  STOPSTOPSTOP: End
  };
  if (line == null) return;
  String msg = null;  String[] msgArray = null;  int i = 0;
  //  Hunt for each marker.
  for (String marker: markers) {
    int pos = line.indexOf(marker);
    if (pos < 0) { i++; continue; }
    
    msg = line.substring(pos + marker.length()).trim();
    msgArray = msg.split(",");
    break;
  }
  if (msg == null) return;
  
  switch(i) {
    case 0: {  //  sendMessage
      String device = msgArray[0];
      String data = msgArray[1];
      println("Detected message for device=" + device + ", data=" + data);
      //  Emulate the SIGFOX message by sending to an emulation server.
      sendEmulatedMessage(device, data);
      break;
    }
    case 1: {  //  stop
      println("stop=" + msg);      
      exit();
      break;
    }
    default: break;
  }
}