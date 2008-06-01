/* DS1820 & DS18X20 Temperature chip i/o - code based off that at 
 * http://www.arduino.cc/playground/Learning/OneWire
 *
 * Connect pins 1 & 3 (the two outside pins) of the DS1820 to GND, 
 * and pin 3 (the middle one) of the DS1820 to pin 10 on your Arduino.
 * Also connect a 4k7 resistor from pin 10 of the arduino / pin 2 of
 * the DS1820 to 5v. If you are using more than one DS1820, connect its
 * pins 1 & 3 to GND, and its pin 2 to pin 10 of the arduino as well.
 * as soon as I get fritzing up and running, I'll add a breadboard layout
 */

#include <OneWire.h>

OneWire ds(10);  // on pin 10

void setup(void) {
	// initialize inputs/outputs
	// start serial port
	Serial.begin(9600);
}

/**
 * This method is the main loop. It will scan for a device, then when one is found it will
 * check its family. If it's a DS1820 or DS18S20 it will output the address and the contents
 * of the ROM on the device, followed by the calculated temperate over serial. If it's not
 * a device in the right family it will print the address, and a message noting that the device
 * is not in the correct family. It will then rescan the bus for the next device. If no device
 * or no more devices are found it will print a message stating the fact, reset the search
 * and start it again.While processing it will also check the CRC to make sure the data is
 * correct, and if in correct it will notify.
 */

void loop(void) {
	byte i;
	byte present = 0;
	byte data[12];
	byte addr[8];

	// search the OneWire bus for devices.
	/* On the bus, a call to the search ROM command (0xF0) will allow the retrieval
	 * of the addresses of the devices on the bus (very simplified, see the data 
	 * sheet and OneWire library for more information). For at least the DS1820
	 * (and possibly all OneWire devices - don't know) the device will respond with
	 * 64 of data. The least significant (first 8 bits) contain the family code, i.e
	 * the type of device this is (multiple types of device can be on a single bus)
	 * the next 48 bits contain the unique device serial number - this can be used 
	 * to identify the exact device this is (useful when multiple devices from the
	 * same family are on the bus).
	*/
	if ( !ds.search(addr)) {
		Serial.print("No more addresses on bus.\n");
		ds.reset_search();
		delay(200); // wait 0.2s to make sure the output is not flooded on an empty bus.
		return;
	}

	Serial.print("ADDRESS=");
	for( i = 0; i < 8; i++) {
		Serial.print(addr[i], HEX);
		Serial.print(" ");
	}
	Serial.print("| ");

	if ( OneWire::crc8( addr, 7) != addr[7]) {
		Serial.print("CRC is not valid!\n");
		delay(5000);
		return;
	}

	if ( addr[0] != 0x10) { // 0x10 for DS1820/DS18S20. DS18B20 is 0x28, and DS1822 is 0x22, code may support.
		Serial.print("Device is not a DS1820/DS18S20 family device.\n");
		Serial.print("\n");
		return;
	}

	ds.reset();
	ds.select(addr);
	// tell the device to initiate temperature check - and send power if device not already powered
	ds.write(0x44,1); // 1 to provide power the device, 0 if it is already powered

	// wait for calculation
	delay(1000);     // maybe 750ms is enough, maybe not (set to 1000 now)
	// we might do a ds.depower() here, but the reset will take care of it.

	present = ds.reset(); // reset the bus, and see if device asserts a presence pulse.
	ds.select(addr);    
	ds.write(0xBE);         // Read Scratchpad

	Serial.print("PRESENT PULSE= ");
	Serial.print(present,HEX);
	Serial.print(" | ");
	Serial.print("ROM=");
	Serial.print(" ");
	// for each byte returned from ROM read
	for ( i = 0; i < 9; i++) {           // we need 9 bytes
		data[i] = ds.read();
		Serial.print(data[i], HEX);
		Serial.print(" ");
	}
	Serial.print(" CRC=");
	Serial.print( OneWire::crc8( data, 8), HEX);
	Serial.print(" | ");

	// Calculation for DS1820 with 0.5 deg C resolution, by 100 to keep precision in int
	int result100 = (float) (make16(data[1], data[0]) / 2.0) * 100;   

	// Serial.print doesn't handle floats
	// separate off the whole and fractional portions from the above calc (aready * by 100 to keep
	// precision)
	int prepoint = result100 / 100;
	int postpoint = result100 % 100;
	
	Serial.print("TEMP: ");
	Serial.print(prepoint);
	Serial.print(".");
	Serial.print(postpoint);
	Serial.print("c");
	Serial.println();

	delay(1000); // wait 1 sec before searching for next device.
}

/* function to convert two bytes into a int16 */
unsigned int make16(unsigned char hibyte, unsigned char lobyte)
{
	return (unsigned int)(((unsigned int)hibyte << 8) | lobyte);
}

