#include <Arduino.h>
#include "sensors.h"

SensorHandle m;
BluetoothSerial btSerial;

void setup() {
  Serial.begin(115200);
  m = sensors::initSensors();
  sensors::sensorSettings(m);

  static float acc[TARGET_SAMPLES][3], gyro[TARGET_SAMPLES][3];
  static unsigned long ts[TARGET_SAMPLES];
  Serial.println("DATA_START");
  sensors::collectSamples(m, acc, gyro, ts);
  Serial.println("DATA_END");
}

void loop() {}