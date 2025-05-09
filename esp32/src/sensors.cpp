#include "sensors.h"

static Adafruit_MPU6050 mpuInstance;


SensorHandle sensors::initSensors() {
  Wire.begin(21, 22);
  if (!mpuInstance.begin()) {
    printMessage("MPU6050 başlatılamadı!");
    while (1) delay(1000);
  }
  printMessage("MPU6050 başlatıldı! Ölçüm yapılıyor...");
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

    printData(acc[i][0], acc[i][1], acc[i][2],
      gyro[i][0], gyro[i][1], gyro[i][2], ts[i]);

    //10 ms bekle
    nextTime += INTERVAL;
  }
}

void sensors::printMessage(const char *message) {
  btSerial.println(message);
  Serial.println(message);
}

void sensors::printData(float ax, float ay, float az, float gx, float gy, float gz, unsigned long t) {
  String out = String(ax, 6) + "," + String(ay, 6) + "," + String(az, 6) + "," +
               String(gx, 6) + "," + String(gy, 6) + "," + String(gz, 6) + "," +
               String(t);
  Serial.println(out);
  if (btSerial.hasClient()) btSerial.println(out);
}