// defines pins numbers
const int stepPin = 0; 
const int dirPin = 2; 

void setup() {
  // put your setup code here, to run once:
  // Sets the two pins as Outputs
  pinMode(stepPin,OUTPUT); 
  pinMode(dirPin,OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT); 
  Serial.begin(115200);
  delay(10); //Vent, elers går det for hurtigt

  pinMode(LED_BUILTIN, OUTPUT); 
  digitalWrite(LED_BUILTIN, LOW);
  Serial.println("\nCounter-Clockwise"+HIGH);
  digitalWrite(dirPin,HIGH); // Enables the motor to move in a particular direction
  
  digitalWrite(stepPin,HIGH); // don't clock step pin(calibration)
}

void loop() {
  // put your main code here, to run repeatedly:

}
