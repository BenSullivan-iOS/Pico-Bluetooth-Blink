//
//  ContentView.swift
//  core-bluetooth
//
//  Created by Andrew on 2022-07-14.
//  Modified by MrMcSwiftface on 2023-02-21
//

import SwiftUI
import CoreBluetooth

class BluetoothViewModel: NSObject, ObservableObject {
    
    @Published var stateText: [String] = []
    
    private var picoPeripheral: CBPeripheral?
    private var centralManager: CBCentralManager?
    private var timer: Timer!
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    
    /// Starts the BT scanning process once the manager is turned on
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            stateText.append("Scanning")
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    /// Discovers all services once connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stateText.append("Connected to \(peripheral.name!)")
        stateText.append("Discovering services")
        peripheral.discoverServices(nil)
    }
        
    /// Detects any BT device in range
    /// Once we match the one we're looking for,
    /// we connect to it and ignore every other peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard picoPeripheral == nil else { return }
        
        // I'm not sure how to find some kind of UUID for ensuring it's the matching device.
        // Please create a PR if you know the correct way to do this.
        // Both of these names have appeared for my Pico
        if peripheral.name == "nRF SPP" || peripheral.name == "Nordic SPP Counter" {
            peripheral.delegate = self
            picoPeripheral = peripheral
            stateText.append("Connecting to \(peripheral.name!)")
            central.connect(peripheral)
        }
    }
}

extension BluetoothViewModel: CBPeripheralDelegate {
    
    /// Called when services are discovered
    /// the services can be used to start discovering characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        stateText.append("\(services.count) service discovered")
        stateText.append("Discovering characteristics")

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /// Called when characteristics have been discovered
    /// Kicks off a loop to toggle the LED
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        guard let characteristics = service.characteristics else {
            return
        }
        
        stateText.append("\(characteristics.count) characteristics discovered")
        stateText.append("Writing value `t` every 0.5 seconds to toggle onboard LED")

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            /// Writing a value to the peripheral send the value to the device
            peripheral.writeValue(Data("t".utf8),
                                  for: characteristics.first!,
                                  type: .withoutResponse)
        }
    }
}

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        NavigationView {
            List(bluetoothViewModel.stateText, id: \.self) { peripheral in
                Text(peripheral)
            }
            .navigationTitle("Find my Pico!")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
