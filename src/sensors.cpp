#include "sensors.h"

static Adafruit_MPU6050 mpuInstance;
extern BluetoothSerial btSerial;

SensorHandle sensors::initSensors() {
  Wire.begin(21, 22);
  if (!mpuInstance.begin()) {
    Serial.println("MPU6050 başlatılamadı!");
    while (1) delay(1000);
  }
  Serial.println("MPU6050 hazır. Ölçüm başlıyor...");
  return &mpuInstance;
}

void sensors::sensorSettings(SensorHandle m) {
  m->setAccelerometerRange(MPU6050_RANGE_4_G);
  m->setGyroRange(MPU6050_RANGE_500_DEG);
  m->setFilterBandwidth(MPU6050_BAND_21_HZ);
}

void sensors::collectSamples(SensorHandle m, float acc[][3], float gyro[][3], unsigned long ts[]) {
  unsigned long nextTime = micros();
  for (int i = 0; i < TARGET_SAMPLES; i++) {
    while (micros() < nextTime) {
      // Bekle
    } 

    ts[i] = nextTime;
    sensors_event_t a, g, temp;
    m->getEvent(&a, &g, &temp);
    acc[i][0]  = a.acceleration.x;
    acc[i][1]  = a.acceleration.y;
    acc[i][2]  = a.acceleration.z;
    gyro[i][0] = g.gyro.x;
    gyro[i][1] = g.gyro.y;
    gyro[i][2] = g.gyro.z;

    Serial.print(acc[i][0], 6);  Serial.print(',');
    Serial.print(acc[i][1], 6);  Serial.print(',');
    Serial.print(acc[i][2], 6);  Serial.print(',');
    Serial.print(gyro[i][0],6);   Serial.print(',');
    Serial.print(gyro[i][1],6);   Serial.print(',');
    Serial.print(gyro[i][2],6);   Serial.print(',');
    Serial.println(ts[i]);
    //10 ms bekle
    nextTime += INTERVAL;
  }
}