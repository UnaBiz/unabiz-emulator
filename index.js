//  Main program.

const util = require('util');
const url = require('url');
const http = require('http');
const https = require('https');
const SerialPort = require('serialport');
const config = require('./config.json');
/* eslint-disable no-console */

function sendHTTPRequest(req, method, requestURL, headers, body) {
  const parsedURL = url.parse(requestURL);
  const requestParams = {
    host: parsedURL.hostname,
    port: parsedURL.port,
    path: parsedURL.path,
    method,
    headers,
    body,
  };
  let protocol = null;
  if (parsedURL.protocol === 'https:') protocol = https;
  else if (parsedURL.protocol === 'http:') protocol = http;
  else return Promise.reject(new Error(`sendHTTPRequest: Unknown protocol ${parsedURL.protocol}`));
  return new Promise((resolve, reject) => {
    const request = protocol.request(requestParams, (response) => {
      let responseBody = '';
      response.on('data', (chunk) => {
        responseBody += chunk;
      });
      response.on('end', () => {
        if (response.statusCode !== 302 &&
          (response.statusCode < 200 || response.statusCode > 299)) {
          console.error(response.body);
          return reject(new Error(responseBody));
        }
        console.error({ responseBody });
        return resolve(responseBody);
      });
    }).on('error', (e) => {
      console.error(e);
      return reject(e);
    });
    //  Make the request and wait for callback.
    request.end(body);
  });
}

console.log('Starting UnaBiz Emulator...');
const port = new SerialPort('/dev/ttyUSB0', {
  baudRate: 9600,
  parser: SerialPort.parsers.readline('\n'),
});

//  Catch the uncaught errors that weren't wrapped in a domain or try catch statement
//  Do not use this in modules, but only in applications, as otherwise we could have
//  multiple of these bound.
process.on('uncaughtException', (err) => {
  //  Handle the error safely
  //  noinspection Eslint
  console.error(err);
  try {
    //  common.error({}, 'uncaughtException', { err });
  } catch (err2) {  //  noinspection Eslint
    console.error(err2);
  }
});

port.on('open', () => {
  //  Enable TD LAN RF asynchronous receive mode.
  port.write('AT$RL=2\r', (err) => {
    if (err) {
      return console.log('*****ERROR: Can\'t write: ', err);
    }
    console.log('UnaBiz Emulator started');
    return null;
  });
});

// open errors will be emitted as an error event
port.on('error', (err) => console.error('*****ERROR: ', err));

port.on('data', (data0) => {
  //  Every emulation message has 17 bytes:
  //  +RX_LAN=0102030405060708090a0b0c0d0e0f1011
  //  device ID (4 bytes) + sequence number (1 byte) + payload (max 12 bytes)
  let data = data0.split('\r').join('');
  const req = {};
  const prefix = '+RX_LAN=';
  if (data.indexOf(prefix) !== 0) {
    //  Ignore corrupted messages.
    console.log(`Skipping ${data}`);
    return;
  }
  data = data.substr(prefix.length);

  let device = data.substr(0, 8).toUpperCase();
  while (device[0] === '0') device = device.substr(1);  //  Strip leading 0s.
  const seqNumber = data.substr(8, 2);
  data = data.substr(10);
  console.log('<< UnaBiz Emulator received msg');
  console.log(util.inspect({ device, seqNumber, data }, { colors: true }));

  //  TODO: Check whether we missed any messages with the sequence number.
  //  Construct the message to be posted to UnaCloud.
  const msg = {
    device,
    data,
    time: parseInt(Date.now() / 1000, 10),
    duplicate: 'false',  //  TODO
    snr: '18.88',  //  TODO
    station: '0000',  //  TODO: Replace by the server's device ID.
    avgSnr: '15.55',  //  TODO
    lat: '1',
    lng: '104',
    rssi: '-123.45',  //  TODO
    seqNumber,
    ack: 'false',
    longPolling: 'false',
  };

  //  Post the message to UnaCloud.
  const body = JSON.stringify(msg, null, 2);
  const headers = {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  };
  sendHTTPRequest(req, 'POST', `${config.postMessageURL}?type=emulator`, headers, body)
    .then(() => console.log(`\n>> UnaBiz Emulator sent to UnaCloud ${JSON.stringify({
      device, seqNumber })}\n`))
    .catch((error) => console.error(`***** ERROR: Failed to send to UnaCloud ${JSON.stringify({
      error, device, seqNumber }, null, 2)}`));
});
