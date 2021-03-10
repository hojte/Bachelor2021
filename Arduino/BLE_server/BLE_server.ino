/*
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleServer.cpp
    Ported to Arduino ESP32 by Evandro Copercini
    updates by chegewara

    Modified by VidIt to suit our needs.
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <AccelStepper.h>


#define SERVICE_UUID        "ea411899-d14c-45d5-81f0-ce96b217c64a"
#define CHARACTERISTIC_UUID "91235981-23ee-4bca-b7b2-2aec7d075438"
#define CHARACTERISTIC_UUID_RX "52e6a8f9-5688-4d81-b1ad-ece87b095e52"

const int ledPin = 3;
BLEServer *VidItServer;
BLEService *VidItService;
BLECharacteristic *VidItCharacteristic;
BLEAdvertising *VidItAdvertising;

// defines pins numbers
// 1st motor
const int stepPin_1 = 33; 
const int dirPin_1 = 32; 
const int MS1_1 = 27; 
const int MS2_1 = 26; 
const int MS3_1 = 25; 

// 2nd motor
const int stepPin_2 = 22; 
const int dirPin_2 = 2;
const int MS1_2 = 18; 
const int MS2_2 = 19; 
const int MS3_2 = 21; 

// Define motor interface type
#define motorInterfaceType 1



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

  
  pinMode(stepPin_1,OUTPUT); 
  pinMode(dirPin_1,OUTPUT);
  digitalWrite(stepPin_1,HIGH);
  
}


int connectedUsers = 0;

void loop() {
  
  connectedUsers = VidItServer->getConnectedCount();
  
  if(connectedUsers > 0){
    
    digitalWrite(ledPin, HIGH);
    Serial.println(VidItCharacteristic->getValue().c_str());
    //Debug statement - printing in console.
    
    if (VidItCharacteristic->getValue()== "Right"){
       //Counter clockwise
       digitalWrite(dirPin_1,HIGH); // Enables the motor to move in a particular direction      
            digitalWrite(stepPin_1,HIGH); 
          delayMicroseconds(500); 
          digitalWrite(stepPin_1,LOW); 
          delayMicroseconds(500); 
          
        delay(10); 
      }
      else if (VidItCharacteristic->getValue()== "Left"){
          //Clockwise
          digitalWrite(dirPin_1,LOW); //Changes the rotations direction
          // Makes 400 pulses for making two full cycle rotation
          //while(VidItCharacteristic->getValue()== "Left"){
            digitalWrite(stepPin_1,HIGH);
            delayMicroseconds(500);
            digitalWrite(stepPin_1,LOW);
            delayMicroseconds(500);
  delay(10); 
        }
        else if(VidItCharacteristic->getValue()== "Up"){
          digitalWrite(dirPin_2,HIGH); // Enables the motor to move in a particular direction      
            digitalWrite(stepPin_2,HIGH); 
          delayMicroseconds(500); 
          digitalWrite(stepPin_2,LOW); 
          delayMicroseconds(500); 
          delay(10);
          }
          else if(VidItCharacteristic->getValue()== "Down"){
          digitalWrite(dirPin_2,LOW); // Enables the motor to move in a particular direction      
            digitalWrite(stepPin_2,HIGH); 
          delayMicroseconds(500); 
          digitalWrite(stepPin_2,LOW); 
          delayMicroseconds(500); 
          delay(10);
          }
        else{
          //Do nothing
          //Serial.println("FUCKING HOLD BITHC");  
          }
           
  }
  else{
    digitalWrite(ledPin, LOW);
  }
}
