/*
 * Scan's twi interface, and reports over serial what devices are found.
 *
 * from: http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1192228140
 * Has been modified by lstoll@lstoll.net
 *
 */
 
#include <Wire.h>
 
void setup() {
  Serial.begin(115200);
  Wire.begin();
}


void loop()
{
  Serial.println("**** Starting scan ****" );
  int ii;

  for (ii=1;ii<128;ii++)
  {
    if (Wire.checkAddress(ii))
    {
      Serial.print("Device responded on address:\t");
      Serial.print(ii, HEX);
      Serial.println();
    }
  }
  Serial.println("**** Finished scan. Will wait 10 seconds before scanning again ****");
  Serial.println();
  Serial.println();
  delay(10000);
}
