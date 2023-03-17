# Pico-Bluetooth-Blink

This is based off of the below repo which detects and displays all BT devices:

https://github.com/Andrew11US/AF-Swift-Tutorials/tree/main/core-bluetooth

Ensure you have the latest Pico-SDK https://github.com/raspberrypi/pico-sdk

I used the below repo for the Pico code. I used CMake and VSCode and just had to update the location of the `pico-sdk`.

https://github.com/sonnny/picow_ble_nordic_spp

![Image](https://pbs.twimg.com/media/Fpfazu4WcAEjY4g?format=jpg&name=large)

To receive data that has been sent via SPP using Bluetooth in Swift, you can use the CoreBluetooth framework provided by Apple. Here's an example code snippet that demonstrates how to discover and connect to a peripheral device that supports SPP, and receive data sent by the peripheral:

import CoreBluetooth

// Set the UUID of the SPP service and characteristic
let sppServiceUUID = CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB")
let sppCharacteristicUUID = CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB")

// Create a CBCentralManager instance to manage Bluetooth connections
let centralManager = CBCentralManager()

// Discover and connect to the peripheral device that supports SPP
func discoverAndConnect() {
    centralManager.scanForPeripherals(withServices: [sppServiceUUID], options: nil)
}

func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    if let name = peripheral.name, name == "My SPP Device" {
        centralManager.stopScan()
        central.connect(peripheral, options: nil)
    }
}

func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices([sppServiceUUID])
}

// Receive data sent by the peripheral device
extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([sppCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let receivedData = String(decoding: data, as: UTF8.self)
        print(receivedData)
    }
}

In this example code, you first set the UUID of the SPP service and characteristic that you want to use. Then, you create a CBCentralManager instance to manage Bluetooth connections. You can call the scanForPeripherals method to start scanning for peripheral devices that advertise the SPP service UUID. Once you discover the peripheral device, you can connect to it by calling the connect method on the CBCentralManager instance. Once connected, you can discover the SPP service and characteristic by implementing the CBPeripheralDelegate protocol and calling the discoverServices and discoverCharacteristics methods on the peripheral object. Finally, you can receive data sent by the peripheral device by implementing the didUpdateValueFor method and calling the setNotifyValue method with the true parameter to enable notifications for the SPP characteristic. In the didUpdateValueFor method, you can decode the received data and print it to the console.
