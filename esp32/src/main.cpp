#include <Arduino.h>
#include "sensors.h"

SensorHandle m;
BluetoothSerial btSerial;

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

  static float acc[TARGET_SAMPLES][3], gyro[TARGET_SAMPLES][3];
  static unsigned long ts[TARGET_SAMPLES];
  sensors::printMessage("DATA_START");
  sensors::collectSamples(m, acc, gyro, ts);
  sensors::printMessage("DATA_END");
}

void loop() {
  static bool wasConnected = false;

  bool nowConnected = btSerial.hasClient();

  if (wasConnected && !nowConnected) {
    Serial.println("Bluetooth client disconnected. Restarting...");
    delay(100);
    ESP.restart();  // Soft reboot of the board
  }

  wasConnected = nowConnected;

  delay(500);
}
