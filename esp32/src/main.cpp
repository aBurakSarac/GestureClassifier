#include <Arduino.h>
#include "sensors.h"

SensorHandle m;
BluetoothSerial btSerial;
static float acc[TARGET_SAMPLES][3], gyro[TARGET_SAMPLES][3];
static unsigned long ts[TARGET_SAMPLES];

void setup() {
  Serial.begin(115200);
  if (!btSerial.begin("ESP32_BT")) {
    sensors::printMessage("Bluetooth init failed!");
    while (1) delay(1000);
  }
  while (!btSerial.hasClient()) {
    delay(100);
  }
  sensors::printMessage("Connection successful!");
  m = sensors::initSensors();
  sensors::sensorSettings(m);

}

void loop() {
  static bool wasConnected = false;

  bool nowConnected = btSerial.hasClient();

  if (wasConnected && !nowConnected) {
    Serial.println("Bluetooth client disconnected.");
    while (!btSerial.hasClient()) {
      delay(100);
    }
    Serial.println("Client reconnected!");
  }

  wasConnected = nowConnected;

 

  if (btSerial.available()) {
    String cmd = btSerial.readStringUntil('\n');
    cmd.trim();
    if (cmd == "COLLECT") {
      sensors::printMessage("DATA_START");
      sensors::collectSamples(m, acc, gyro, ts);
      sensors::printMessage("DATA_END");
    }
  }
  delay(10);

}
