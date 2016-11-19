'use strict';

//  AWS Lambda function to process the SIGFOX message passed by UnaBiz Emulator or UnaCloud.

console.log('Loading function');

//  Init the AWS connection.
const AWS = require('aws-sdk');
AWS.config.region = 'us-west-2';
//  AWS.config.logger = process.stdout;  //  Debug

exports.handler = (input, context2, callback2) => {
  //  This is the main program flow.
  if (input.domain) delete input.domain;  //  TODO: Contains self-reference loop.
  console.log('ProcessSIGFOXMessage Input:', JSON.stringify(input, null, 2));
  console.log('ProcessSIGFOXMessage Context:', context2);

  const decoded_data = decodeMessage(input.data);
  return callback2(null, decoded_data);
};

function decodeMessage(msg) {
  //  Decode the packed binary SIGFOX message e.g. 920e5a00b051680194597b00
  //  2 bytes name, 2 bytes float * 10, 2 bytes name, 2 bytes float * 10, ...
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
    const name3 = '   ';
    for (let j = 0; j < 3; j++) {
      const code = name2 & 31;
      const ch = decodeLetter(code);
      if (ch > 0) name3[2 - j] = ch;
      name2 = name2 >> 5;
    }
    result[name] = val2 / 10.0;
  }
  return result;
}

function hexDigitToDecimal(ch) {
  //  Convert 0..9, a..f, A..F to decimal.
  if (ch >= 1 * '0' && ch <= 1 * '9') return ch - '0'[0];
  if (ch >= 1 * 'a' && ch <= 1 * 'z') return ch - 'a'[0] + 10;
  if (ch >= 1 * 'A' && ch <= 1 * 'Z') return ch - 'A'[0] + 10;
  return 0;
}

const firstLetter = 1;
const firstDigit = 27;

function decodeLetter(code) {
  //  Convert the 5-bit code to a letter.
  if (code === 0) return 0;
  if (code >= firstLetter && code < firstDigit) return code - firstLetter + 1 * 'a'[0];
  if (code >= firstDigit) return code - firstDigit + 1 * '0'[0];
  return 0;
}

//  Unit test cases that will be run on a local PC/Mac instead of AWS Lambda.

function isProduction() {
  //  Return true if this is production server.
  if (process.env.LAMBDA_TASK_ROOT) return true;
  const environment = process.env.NODE_ENV || 'development';
  return environment !== 'development';
}

/* eslint-disable no-unused-vars, quotes, quote-props, max-len, comma-dangle, no-console */

const test_input = {
  data: '920e5a00b051680194597b00'
};

const test_context = {
  "awsRequestId": "98dc0220-0eba-11e6-b84a-f75570995fc5",
  "invokeid": "98dc0220-0eba-11e6-b84a-f75570995fc5",
  "logGroupName": "/aws/lambda/SendSensorDataToElasticsearch2",
  "logStreamName": "2016/04/30/[$LATEST]3f3acb23c5294fbcad74c08097c0b03e",
  "functionName": "SendSensorDataToElasticsearch2",
  "memoryLimitInMB": "128",
  "functionVersion": "$LATEST",
  "invokedFunctionArn": "arn:aws:lambda:us-west-2:595779189490:function:SendSensorDataToElasticsearch2"
};

//  Run the unit test if we are in development environment.
function runTest() {
  return exports.handler(test_input, test_context, (err, result) => {
    if (err) console.error(err);
    else console.log(result);
  });
}

if (!isProduction()) runTest();
