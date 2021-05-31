# AVR Microcontroller Project

_A course project for MICRO-210 as part of MT-BA4 at EPFL, May 2021._

Designed to run on the STK-300 board with an ATmega128 daughterboard.
Build using Atmel Studio and flash using AVRISP-U.
AVRA compiler is also supported.

## Description

This is a course project written in assembly with the purpose of teaching us about microcontroller hardware and capability, protocols, processor instructions and peripheral interfaces.

This program displays a welcome message, prompts the user to select a temperature unit, allows the user to calibrate the server motor and then displays the measured temperature on the screen, also moving the servo to a specified position, proportional to the measured value. By pushing down on the analogue encoder, a synchronous interrupt is triggered, allowing the selection of a new unit and servo recalibration.

## Usage

Plug the S3003 FUTABA SERVO on port D on pin 4. Plug the DS18B20 Programmable Resolution 1-Wire Digital Thermometer on port B on pin 5. Plug the angular encoder on port E on pins 4, 5 and 6. Also requires a Hitachi HD44780U LCD controller (internal hardware connection to port A).

Flash the binary, configure the MCU to run at 4 MHz. Launch the program, use the angular encoder to navigate menus.

## Authors

- Marcus Cemes
- Julien Moreno

## License

This project is released under the MIT license.

See [LICENSE](LICENSE).
