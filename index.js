//  Main program.

const SerialPort = require("serialport");

console.log('Starting UnaBiz Emulator...');
const port = new SerialPort("/dev/ttyUSB0", {
  baudRate: 9600
});

//  Catch the uncaught errors that weren't wrapped in a domain or try catch statement
//  Do not use this in modules, but only in applications, as otherwise we could have
//  multiple of these bound.
process.on('uncaughtException', (err) => {
  //  Handle the error safely
  //  noinspection Eslint
  console.error(err);
  try {
    //common.error({}, 'uncaughtException', { err });
  } catch (err2) {  //  noinspection Eslint
    console.error(err2);
  }
});

port.on('open', function() {
  //  Enable TD LAN RF asynchronous receive mode
  port.write('AT$RL=2\r', function(err) {
    if (err) {
      return console.log('Error on write: ', err.message);
    }
    console.log('UnaBiz Emulator started');
  });
});

// open errors will be emitted as an error event
port.on('error', function(err) {
  console.log('Error: ', err.message);
});

port.on('data', function (data) {
  console.log('UnaBiz Emulator Received Message: ' + data);
});
