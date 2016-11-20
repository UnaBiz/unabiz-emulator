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

static Serial arduinoPort;  // Serial port connected to Arduino debug output.
static String line;     // Data received from the serial port

void setup() {  //  Will be called only once.
  //  Open the serial port that connects to the Arduino device.
  String[] serialPorts = Serial.list();
  println(prefix + "Found COM / serial ports: " + join(serialPorts, ", "));
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
  println(prefix + "Connecting to Arduino at port " + portName + "...");
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
  println(prefix + "Emulating SIGFOX message:" + json + "...");
  for (String url: emulateServerURLs) {
    //  For each emulate server URL, send the device and data.
    JSONRequest post = new JSONRequest(url);
    post.addHeader("Content-Type", "application/json");
    post.addJson(json);
    post.send();
    println(prefix + "Emulate server reponse:" + post.getContent());
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
      println(prefix + "Detected message for device=" + device + ", data=" + data);
      //  Emulate the SIGFOX message by sending to an emulation server.
      sendEmulatedMessage(device, data);
      break;
    }
    case 1: {  //  stop
      println(prefix + "Arduino stopped: " + msg);      
      exit();
      break;
    }
    default: break;
  }
}

function decodeMessage(msg) { /* eslint-disable no-bitwise, operator-assignment */
  //  Decode the packed binary SIGFOX message e.g. 920e5a00b051680194597b00
  //  2 bytes name, 2 bytes float * 10, 2 bytes name, 2 bytes float * 10, ...
  if (!msg) return {};
  const result = {};
  for (let i = 0; i < msg.length; i = i + 8) {
    const name = msg.substring(i, i + 4);
    const val = msg.substring(i + 4, i + 8);
    let name2 =
      (parseInt(name[2], 16) << 12) +
      (parseInt(name[3], 16) << 8) +
      (parseInt(name[0], 16) << 4) +
      parseInt(name[1], 16);
    const val2 =
      (parseInt(val[2], 16) << 12) +
      (parseInt(val[3], 16) << 8) +
      (parseInt(val[0], 16) << 4) +
      parseInt(val[1], 16);

    //  Decode name.
    const name3 = [0, 0, 0];
    for (let j = 0; j < 3; j = j + 1) {
      const code = name2 & 31;
      const ch = decodeLetter(code);
      if (ch > 0) name3[2 - j] = ch;
      name2 = name2 >> 5;
    }
    const name4 = String.fromCharCode(name3[0], name3[1], name3[2]);
    result[name4] = val2 / 10.0;
  }
  return result;
}

const firstLetter = 1;
const firstDigit = 27;

function decodeLetter(code) {
  //  Convert the 5-bit code to a letter.
  if (code === 0) return 0;
  if (code >= firstLetter && code < firstDigit) return (code - firstLetter) + 'a'.charCodeAt(0);
  if (code >= firstDigit) return (code - firstDigit) + '0'.charCodeAt(0);
  return 0;
}

static String prefix = " > ";