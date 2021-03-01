/*
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleServer.cpp
    Ported to Arduino ESP32 by Evandro Copercini
    updates by chegewara

    Modified by VidIt to suit our needs.
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID        "ea411899-d14c-45d5-81f0-ce96b217c64a"
#define CHARACTERISTIC_UUID "91235981-23ee-4bca-b7b2-2aec7d075438"

const int ledPin = 2;
BLEServer *VidItServer;
BLEService *VidItService;
BLECharacteristic *VidItCharacteristic;
BLEAdvertising *VidItAdvertising;

void setup() {
  Serial.begin(115200);
  Serial.println("STARTING BLE FOR VIDIT");
  pinMode(ledPin, OUTPUT);

  //Init the BLE device with the name.
  BLEDevice::init("VidItESP32");
  //Creating the BLE device as a BLE server
  VidItServer = BLEDevice::createServer();
  //Creating BLE service with the service UUID
  VidItService = VidItServer->createService(SERVICE_UUID);
  //Creating BLE characteristic with UUID wit properties read and write.
  VidItCharacteristic = VidItService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  //The setValue should be changed in the future to display the state
  VidItCharacteristic->setValue("LOL");
  VidItService->start();
  //The following sets the attributes for the advertising. Such as the UUID, the scan response and start 
  //the BLE adverstising so BT devices can find it. 
  VidItAdvertising = BLEDevice::getAdvertising();
  VidItAdvertising->addServiceUUID(SERVICE_UUID);
  VidItAdvertising->setScanResponse(true);
  VidItAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  VidItAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("READY TO BE PAIRED");
}


int connectedUsers = 0;

void loop() {
  connectedUsers = VidItServer->getConnectedCount();
  if(connectedUsers > 0){
    digitalWrite(ledPin, HIGH);
    //Debug statement - printing in console.
    Serial.println(VidItCharacteristic->getValue().c_str());
    
    
    
  }else
  {
    digitalWrite(ledPin, LOW);
   
  }

  
  






  
  
  
}
