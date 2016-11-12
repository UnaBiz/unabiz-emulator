## UnaBiz Emulator

- Node.js program that emulates a SIGFOX base station by receiving messages from TD1208 modules in emulation mode nearby and pushes the 
                     messages to UnaCloud.

- Designed to work with the SIGFOX developer kits distributed by UnaBiz

UnaBiz Emulator Requirements
----------------------------

To assemble the emulator you will need the following:

0. Raspberry Pi 3

0. Snootlab Breakout for TD1208R: 
   http://snootlab.com/lang-en/snootlab-shields/962-breakout-td1208-connectivity-1-year-accessories-en.html
   
0. Antenna for TD1208R
   
0. 4D Systems uUSB-PA5 microUSB to Serial-TTL UART bridge converter:
   https://www.4dsystems.com.au/product/uUSB-PA5/
   http://sg.rs-online.com/web/p/interface-development-kits/8417872/

0. USB 2.0 cable, USB A to USB B Mini:
   http://sg.rs-online.com/web/p/usb-cable-assemblies/8223226/
   
UnaBiz Emulator Installation
----------------------------

0. Connect TX of TD1208R to RX of microUSB-UART Converter

0. Connect RX of TD1208R to TX of microUSB-UART Converter

0. Connect a 3V or 3.3V Power Supply to VDD of microUSB-UART Converter

0. Connect GND of TD1208R, GND of microUSB-UART Converter and GND of 3V Power Supply together

0. Connect antenna to TD1208R

0. Connect microUSB-UART Converter to Raspberry Pi with USB cable

0. Install latest version of Raspbian on Raspberry Pi

0. Boot up Raspbian on Raspberry Pi

0. Test the serial connection from the Pi to TD1208R.  Log in to the Pi and run:

    ```
    sudo apt install screen
    screen /dev/ttyUSB0    
    ```

0. Type `AT` and Enter. You should see `OK`.

0. Exit `screen` by pressing `Ctrl-A` then `\` and `y`

0. If `/dev/ttyUSB0` is missing, download microUSB-UART Converter drivers for Linux from:
   http://www.silabs.com/products/mcu/pages/usbtouartbridgevcpdrivers.aspx#linux

0. Install Node.js and `node-serialport` for Pi:
   https://github.com/nebrius/raspi-io/wiki/Getting-a-Raspberry-Pi-ready-for-NodeBots

0. If your Mac can't detect the Arduino board, follow the instructions here:
   https://www.kiwi-electronics.nl/blog?journal_blog_post_id=7