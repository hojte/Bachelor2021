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

const int ledPin = 2;
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
const int dirPin_2 = 23;
const int MS1_2 = 18; 
const int MS2_2 = 19; 
const int MS3_2 = 21; 

// Define motor interface type
#define motorInterfaceType 1

// Creates an instance accelstepper
AccelStepper stepper1(motorInterfaceType, stepPin_1, dirPin_1);
AccelStepper stepper2(motorInterfaceType, stepPin_2, dirPin_2);




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

  
  pinMode(MS3_1,OUTPUT);
  pinMode(MS2_1,OUTPUT);
  pinMode(MS1_1,OUTPUT);
  digitalWrite(MS3_1,HIGH);
  digitalWrite(MS2_1,HIGH);
  digitalWrite(MS1_1,HIGH);

  pinMode(MS3_2,OUTPUT);
  pinMode(MS2_2,OUTPUT);
  pinMode(MS1_2,OUTPUT);
  digitalWrite(MS3_2,HIGH);
  digitalWrite(MS2_2,HIGH);
  digitalWrite(MS1_2,HIGH);  
  
  
  
  
}

int connectedUsers = 0;

void loop() {
  stepper1.setMaxSpeed(1000000);     
  stepper2.setMaxSpeed(1000000);     
  
  connectedUsers = VidItServer->getConnectedCount();
  
  if(connectedUsers > 0){    
    digitalWrite(ledPin, HIGH);
    Serial.println(VidItCharacteristic->getValue().c_str());

    //Splitting the input string into direction and speed
    std::string inputFromAPP = VidItCharacteristic->getValue().c_str();
    std::string delimiter = ":"; 
    std::string _direction = inputFromAPP.substr(0,inputFromAPP.find(delimiter));

    //Removes the direction from the string and finds the speed
    inputFromAPP.erase(0, inputFromAPP.find(delimiter) + delimiter.length());
    std::string _speed = inputFromAPP.substr(0,inputFromAPP.find(delimiter));
    double convertedSpeed = atof(_speed.c_str()); 
    // double convertedSpeed = 50000.0; 
    int upDownSpeed = convertedSpeed; 
    int leftRightSpeed= convertedSpeed;
    Serial.println(upDownSpeed);
    Serial.println(leftRightSpeed);


    
    //Debug statement - printing in console.
    if (_direction== "Right"){
      stepper1.setSpeed(-leftRightSpeed);
      stepper1.runSpeed();
      }
      else if (_direction== "Left"){
        stepper1.setSpeed(leftRightSpeed); 
        stepper1.runSpeed();
        }
      else if(_direction== "Up"){
        stepper2.setSpeed(upDownSpeed);
        stepper2.runSpeed();
        }
      else if(_direction== "Down"){
        stepper2.setSpeed(-upDownSpeed); 
        stepper2.runSpeed();
        }
      else if(_direction== "Up & Right"){
        stepper1.setSpeed(-leftRightSpeed);
        stepper2.setSpeed(upDownSpeed);
        stepper1.runSpeed();
        stepper2.runSpeed();
        }
      else if(_direction== "Up & Left"){
        stepper1.setSpeed(leftRightSpeed);
        stepper2.setSpeed(upDownSpeed);
        stepper1.runSpeed();
        stepper2.runSpeed();
        }
      else if(_direction== "Down & Right"){
        stepper1.setSpeed(-leftRightSpeed);
        stepper2.setSpeed(-upDownSpeed);
        stepper1.runSpeed();
        stepper2.runSpeed();
        }
      else if(_direction== "Down & Left"){
        stepper1.setSpeed(leftRightSpeed);
        stepper2.setSpeed(-upDownSpeed);
        stepper1.runSpeed();
        stepper2.runSpeed();
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
