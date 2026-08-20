#include <Arduino.h>
#include <HardwareSerial.h>
#include <hp_BH1750.h>
#include "Seeed_Arduino_mmWave.h"

// On XIAO ESP32C6 the USB CDC port remains available as Serial, while UART0
// talks to the MR60BHA2 module on the kit.
HardwareSerial mmWaveSerial(0);
SEEED_MR60BHA2 mmWave;
hp_BH1750 lightSensor;

bool lightSensorReady = false;
unsigned long nextStatusMs = 0;

void printEventPrefix(const char *kind) {
  Serial.printf("{\"t_ms\":%lu,\"kind\":\"%s\"", millis(), kind);
}

void setup() {
  Serial.begin(115200);
  delay(1500);

  mmWave.begin(&mmWaveSerial, 115200);
  lightSensorReady = lightSensor.begin(BH1750_TO_GROUND);
  if (lightSensorReady) {
    lightSensor.start();
  }

  printEventPrefix("startup");
  Serial.printf(",\"light_sensor\":%s}\n", lightSensorReady ? "true" : "false");
}

void loop() {
  if (mmWave.update(20)) {
    float totalPhase;
    float breathPhase;
    float heartPhase;
    if (mmWave.getHeartBreathPhases(totalPhase, breathPhase, heartPhase)) {
      printEventPrefix("phase");
      Serial.printf(",\"total\":%.5f,\"breath\":%.5f,\"heart\":%.5f}\n",
                    totalPhase, breathPhase, heartPhase);
    }

    float breathRate;
    if (mmWave.getBreathRate(breathRate)) {
      printEventPrefix("breath_rate");
      Serial.printf(",\"bpm\":%.2f}\n", breathRate);
    }

    float heartRate;
    if (mmWave.getHeartRate(heartRate)) {
      printEventPrefix("heart_rate");
      Serial.printf(",\"bpm\":%.2f}\n", heartRate);
    }

    float distance;
    if (mmWave.getDistance(distance)) {
      printEventPrefix("distance");
      // The module reports this field in centimetres (the upstream example
      // also compares it directly with 70).
      Serial.printf(",\"cm\":%.2f}\n", distance);
    }

    // v1.0.0 cannot distinguish a fresh "no human" report from no fresh
    // presence report, so this emits only positive presence events.
    if (mmWave.isHumanDetected()) {
      printEventPrefix("presence");
      Serial.println(",\"detected\":true}");
    }

    PeopleCounting targets;
    if (mmWave.getPeopleCountingTargetInfo(targets)) {
      printEventPrefix("targets");
      Serial.printf(",\"count\":%u,\"items\":[", (unsigned)targets.targets.size());
      for (size_t i = 0; i < targets.targets.size(); ++i) {
        const TargetN &target = targets.targets[i];
        if (i > 0) {
          Serial.print(',');
        }
        Serial.printf(
            "{\"x_m\":%.3f,\"y_m\":%.3f,\"doppler_index\":%ld,"
            "\"cluster_index\":%ld,\"speed_cm_s\":%.2f}",
            target.x_point, target.y_point, (long)target.dop_index,
            (long)target.cluster_index, target.dop_index * RANGE_STEP);
      }
      Serial.println("]}");
    }

    FirmwareInfo firmware;
    if (mmWave.getFirmwareInfo(firmware)) {
      const FirmwareVersion &v = firmware.firmware_verson;
      printEventPrefix("firmware");
      Serial.printf(",\"project\":%u,\"major\":%u,\"sub\":%u,\"modified\":%u}\n",
                    v.project_name, v.major_version, v.sub_version,
                    v.modified_version);
    }
  }

  if (lightSensorReady && lightSensor.hasValue()) {
    printEventPrefix("illuminance");
    Serial.printf(",\"lux\":%.2f}\n", lightSensor.getLux());
    lightSensor.start();
  }

  if ((long)(millis() - nextStatusMs) >= 0) {
    printEventPrefix("status");
    Serial.println(",\"alive\":true}");
    nextStatusMs = millis() + 5000;
  }
}
