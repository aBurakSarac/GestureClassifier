#pragma once
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <BluetoothSerial.h>

#define SAMPLE_RATE 100
#define TARGET_SAMPLES 250
#define INTERVAL 1000000UL/SAMPLE_RATE

using SensorHandle = Adafruit_MPU6050*;
extern BluetoothSerial btSerial;

namespace sensors {
  SensorHandle initSensors();
  
  void sensorSettings(SensorHandle m);
  void collectSamples(SensorHandle m, float acc[][3], float gyro[][3], unsigned long ts[]);
  void printMessage(const char *message);
  void printData(float ax, float ay, float az, float gx, float gy, float gz, unsigned long t);
}