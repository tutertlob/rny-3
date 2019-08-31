#include "Wire.h"
#include <ctime>
#include <sys/time.h>
#include <list>
#include <Sparkfun_APDS9301_Library.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <BLE2904.h>
#include <Preferences.h>

#define SERVICE_UUID        "4611a4a6-9b40-11e9-a2a3-2a2ae2dbcce4"
#define SENSING_CHARACTERISTIC_UUID "4611ab18-9b40-11e9-a2a3-2a2ae2dbcce4"
#define PINGPONG_CHARACTERISTIC_UUID "4611ad5c-9b40-11e9-a2a3-2a2ae2dbcce4"
#define THRESHOLD_CHARACTERISTIC_UUID "4611aec4-9b40-11e9-a2a3-2a2ae2dbcce4"
#define MINTHRESHOLD_CHARACTERISTIC_UUID "4611aec5-9b40-11e9-a2a3-2a2ae2dbcce4"
#define MAXTHRESHOLD_CHARACTERISTIC_UUID "4611aec6-9b40-11e9-a2a3-2a2ae2dbcce4"

#define RECORDS_SERVICE_UUID        "4611a4a7-9b40-11e9-a2a3-2a2ae2dbcce4"
#define EPOCH_TIME_CHARACTERISTIC_UUID "4611aec7-9b40-11e9-a2a3-2a2ae2dbcce4"
// #define EPOCH_HIGHER_CHARACTERISTIC_UUID "4611aec8-9b40-11e9-a2a3-2a2ae2dbcce4"
#define RECORDS_CHARACTERISTIC_UUID "4611aec9-9b40-11e9-a2a3-2a2ae2dbcce4"
#define DELETE_RECORD_CHARACTERISTIC_UUID "4611aeca-9b40-11e9-a2a3-2a2ae2dbcce4"

Preferences preferences;
APDS9301 apds;
BLEServer *pServer = nullptr;
BLECharacteristic *pSensingCharacteristic = nullptr;
BLECharacteristic *pPingPongCharacteristic = nullptr;
BLECharacteristic *pThresholdCharacteristic = nullptr;
BLECharacteristic *pEpochTimeCharacteristic = nullptr;
// BLECharacteristic *pUpperEpochCharacteristic = nullptr;
BLECharacteristic *pRecordsCharacteristic = nullptr;
BLECharacteristic *pDeleteRecordCharacteristic = nullptr;
// BLECharacteristic *pUpperRecordCharacteristic = nullptr;

uint16_t lightLevelThreshold = 500;
unsigned long intervalNotification = 0;
time_t epochTime = 0;
// uint32_t lowerEpochTime = 0;
// uint32_t upperEpochTime = 0;
bool deviceConnected = false;
std::list<uint32_t> records;
uint32_t recordAfter = 0;
bool isRetrieving = false;

#define INT_PIN 16 // We'll connect the INT pin from our sensor to the
                   // INT0 interrupt pin on the Arduino.
bool lightIntHappened = false; // flag set in the interrupt to let the
                   //  mainline code know that an interrupt occurred.

void retrieveLightLevelThreshold();
void updateLightLevelThreshold();
void retrieveRecord();

class MyCallbackHandler : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    Serial.println("onConnect");
    deviceConnected = true;
  }
  void onDisconnect(BLEServer* pServer) {
    Serial.println("onDisconnect");
    deviceConnected = false;
    pServer->startAdvertising();
  }
};

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {

  void onRead(BLECharacteristic* pCharacteristic) {

    Serial.println("onRead");
    if (pCharacteristic == pRecordsCharacteristic) {
      retrieveRecord();
    }
  }

  void onWrite(BLECharacteristic* pCharacteristic) {

    if (pCharacteristic == pThresholdCharacteristic) {

      Serial.println("onWrite to set Threshold");
      uint8_t *data = pThresholdCharacteristic->getData();
      unsigned int threshold;
      uint8_t *p = (uint8_t *)&threshold;
      for (int i = 0; i < 4; i++) {
        p[i] = data[i];
      }
      Serial.print("Write value: ");
      Serial.println(threshold);
      if (threshold != lightLevelThreshold) {
        lightLevelThreshold = threshold;
        updateLightLevelThreshold();
      }

      Serial.println(pThresholdCharacteristic->getValue().c_str());

    } else if (pCharacteristic == pEpochTimeCharacteristic) {

      Serial.println("onWrite to set epoch time.");
      uint8_t *data = pEpochTimeCharacteristic->getData();
      uint32_t lowerEpoch;
      uint8_t *p = (uint8_t *)&lowerEpoch;
      for (int i = 0; i < 4; i++) {
        p[i] = data[i];
      }
      Serial.println(lowerEpoch);
      epochTime = (time_t)(lowerEpoch);

      struct timeval tv;
      tv.tv_sec = epochTime;
      settimeofday(&tv, nullptr);

    } else if (pCharacteristic == pRecordsCharacteristic) {

      Serial.println("onWrite to prepare to retriev records.");
      uint8_t *data = pRecordsCharacteristic->getData();
      // Set a time where begin to retrieve an item in the records
      uint8_t *p = (uint8_t *)&recordAfter;
      for (int i = 0; i < 4; i++) {
        p[i] = data[i];
      }
      isRetrieving = true;
      Serial.print("Write value: ");
      Serial.println(recordAfter);

    } else if (pCharacteristic == pDeleteRecordCharacteristic) {

      Serial.println("onWrite to delete a record.");
      uint8_t *data = pCharacteristic->getData();
      uint32_t time;
      uint8_t *p = (uint8_t *)&time;
      for (int i = 0; i < 4; i++) {
        p[i] = data[i];
      }
      records.remove_if([&time](uint32_t record) { return record == time; });
    }
  } 

};

void retrieveRecord()
{
  uint32_t result = 0;
  
  if (!isRetrieving) {
    pRecordsCharacteristic->setValue(result);
    return;
  }

  for (uint32_t record: records) {
    if (record > recordAfter) {
      result = record;
      recordAfter = record;
      break;
    }
  }

  if (result == 0) {
    isRetrieving = false;
    recordAfter = 0;
  }

  pRecordsCharacteristic->setValue(result);

  Serial.print("Result=");
  Serial.println(result);
  Serial.print("recordAfter=");
  Serial.println(recordAfter);
  Serial.print("isRetrieving=");
  Serial.println(isRetrieving);
}


MyCharacteristicCallbacks characteristicCallbacks;

void setupAPDS9301Sensor() {
  Wire.begin(13, 14);
   
  // APDS9301 sensor setup.
  apds.begin(0x39);  // We're assuming you haven't changed the I2C
                     //  address from the default by soldering the
                     //  jumper on the back of the board.
  apds.setGain(APDS9301::HIGH_GAIN); // Set the gain to low. Strictly
                     //  speaking, this isn't necessary, as the gain
                     //  defaults to low.
  apds.setIntegrationTime(APDS9301::INT_TIME_13_7_MS); // Set the
                     //  integration time to the shortest interval.
                     //  Again, not strictly necessary, as this is
                     //  the default.
  apds.setLowThreshold(0); // Sets the low threshold to 0, effectively
                     //  disabling the low side interrupt.
  apds.setHighThreshold(50); // Sets the high threshold to 500. This
                     //  is an arbitrary number I pulled out of thin
                     //  air for purposes of the example. When the CH0
                     //  reading exceeds this level, an interrupt will
                     //  be issued on the INT pin.
  apds.setCyclesForInterrupt(1); // A single reading in the threshold
                     //  range will cause an interrupt to trigger.
  apds.enableInterrupt(APDS9301::INT_ON); // Enable the interrupt.
  apds.clearIntFlag();

  Serial.println(apds.getLowThreshold());
  Serial.println(apds.getHighThreshold());
}

void retrieveLightLevelThreshold()
{
  preferences.begin("rny-3", false);
  lightLevelThreshold = preferences.getUInt("threshold", lightLevelThreshold);
  preferences.end();
}

void updateLightLevelThreshold()
{
  preferences.begin("rny-3", false);
  preferences.putUInt("threshold", lightLevelThreshold);
  preferences.end();
}

void startRny3PeripheralDevice()
{
  BLEDevice::init("rny-3");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyCallbackHandler());
  setupInterphoneSensorService(pServer);
  setupDeviceInformationService(pServer);
  setupRecordsService(pServer);

  // BLEAdvertising *pAdvertising = pServer->getAdvertising();  // this still is working for backward compatibility
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);

  // BLEAdvertisementData advertiseData;
  // advertiseData.setManufacturerData("ertloblab");
  // advertiseData.setServiceData(BLEUUID(SERVICE_UUID), "Interphone monitoring service.");
  // pAdvertising->setAdvertisementData(advertiseData);
  BLEDevice::startAdvertising();
}

void setupDeviceInformationService(BLEServer *pServer)
{
  BLEService *pService = pServer->createService("180A");
  BLECharacteristic *pCharacter = nullptr;

  // Manufacturer Name String
  pCharacter = pService->createCharacteristic(
                                        "2a29", // Maufacturer Name Strig
                                         BLECharacteristic::PROPERTY_READ
                                       );
  pCharacter->setValue("ertloblab");

  // Model Number String
  pCharacter = pService->createCharacteristic(
                                        "2a24",
                                        BLECharacteristic::PROPERTY_READ
  );
  pCharacter->setValue("rny 3.0");

  // Serial Number String
  pCharacter = pService->createCharacteristic(
                                        "2A25",
                                        BLECharacteristic::PROPERTY_READ
  );
  esp_bd_addr_t bd_addr;
  esp_read_mac(bd_addr, ESP_MAC_BT);
  char buf[32];
  sprintf(buf, ESP_BD_ADDR_STR, ESP_BD_ADDR_HEX(bd_addr));
  pCharacter->setValue(buf);

  pService->start();
}

void setupInterphoneSensorService(BLEServer *pServer)
{
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // For monitoring data in real-time
  pSensingCharacteristic = pService->createCharacteristic(
                                         SENSING_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
  pSensingCharacteristic->addDescriptor(new BLE2902());
  // pCharacteristic->setCallbacks(&characteristicCallbacks);
  unsigned int val = apds.readCH0Level();
  pSensingCharacteristic->setValue(val);

  // For a notification purpose
  pPingPongCharacteristic = pService->createCharacteristic(
                                         PINGPONG_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
  pPingPongCharacteristic->addDescriptor(new BLE2902());
//  pPingPongCharacteristic->setCallbacks(&characteristicCallbacks);

  // For configuration of the threshold to notify
  pThresholdCharacteristic = pService->createCharacteristic(
                                         THRESHOLD_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  pThresholdCharacteristic->setValue(lightLevelThreshold);
  pThresholdCharacteristic->setCallbacks(&characteristicCallbacks);

  BLECharacteristic *pCharacteristic;
  pCharacteristic = pService->createCharacteristic(
                                         MAXTHRESHOLD_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ
                                       );
  uint16_t limit = 65535U;
  pCharacteristic->setValue(limit);
//  pThresholdCharacteristic->setCallbacks(&characteristicCallbacks);

  pCharacteristic = pService->createCharacteristic(
                                         MINTHRESHOLD_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ
                                       );
  limit = 0U;
  pCharacteristic->setValue(limit);
//  pThresholdCharacteristic->setCallbacks(&characteristicCallbacks);

  pService->start();
}

void setupRecordsService(BLEServer *pServer)
{

  BLEService *pService = pServer->createService(RECORDS_SERVICE_UUID);

  // For configuration of the epoch time
  pEpochTimeCharacteristic = pService->createCharacteristic(
                                         EPOCH_TIME_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  uint32_t value = 0U;
  pEpochTimeCharacteristic->setValue(value);
  pEpochTimeCharacteristic->setCallbacks(&characteristicCallbacks);

  // For retrieving records
  pRecordsCharacteristic = pService->createCharacteristic(
                                         RECORDS_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  pRecordsCharacteristic->setValue(value);
  pRecordsCharacteristic->setCallbacks(&characteristicCallbacks);

  pDeleteRecordCharacteristic = pService->createCharacteristic(
                                         DELETE_RECORD_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_WRITE
  );
  pDeleteRecordCharacteristic->setCallbacks(&characteristicCallbacks);

  pService->start();
}

void setup() 
{
  delay(5);    // The CCS811 wants a brief delay after startup.
  Serial.begin(115200);

  preferences.begin("rny-3", false);
  lightLevelThreshold = preferences.getUInt("threshold", lightLevelThreshold);
  preferences.end();

  setupAPDS9301Sensor();

  // Interrupt setup
  pinMode(INT_PIN, INPUT_PULLUP); // This pin must be a pullup or have
                     //  a pullup resistor on it as the interrupt is a
                     //  negative going open-collector type output.
  attachInterrupt(digitalPinToInterrupt(16), lightInt, FALLING);

  startRny3PeripheralDevice();
}
    
void loop() 
{
  static unsigned long outLoopTimer = 0;
  unsigned long current = millis();
  apds.clearIntFlag();                          

  // This is a once-per-second timer that calculates and prints off
  //  the current lux reading.
  if (millis() - outLoopTimer >= 2000)
  {
    outLoopTimer = millis();
    
    unsigned int val = apds.readCH0Level();
    pSensingCharacteristic->setValue(val);

    if (deviceConnected) {
      Serial.print("Luminous flux: ");
      Serial.println(val);
      pSensingCharacteristic->notify();
    }

    if (val >= lightLevelThreshold) {
      Serial.println("Exceeded threshold");
      pPingPongCharacteristic->setValue(val);
      pPingPongCharacteristic->notify();
      if (epochTime != 0 && (intervalNotification == 0 || current - intervalNotification >= 60000)) {
        struct timeval tv;
        gettimeofday(&tv, nullptr);
        Serial.println("Push record");
        records.push_back(tv.tv_sec);
        if (records.size() > 10) {
          records.pop_front();
        }

        intervalNotification = current;
      }
    }

    if (lightIntHappened)
    {
      Serial.println("Interrupt");
      lightIntHappened = false;
    }
  }
}

void lightInt()
{
  lightIntHappened = true;
}
