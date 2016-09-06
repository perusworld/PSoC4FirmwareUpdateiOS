# PSoC4FirmwareUpdateiOS

[![CI Status](http://img.shields.io/travis/perusworld/PSoC4FirmwareUpdateiOS.svg?style=flat)](https://travis-ci.org/perusworld/PSoC4FirmwareUpdateiOS)
[![Version](https://img.shields.io/cocoapods/v/PSoC4FirmwareUpdateiOS.svg?style=flat)](http://cocoapods.org/pods/PSoC4FirmwareUpdateiOS)
[![License](https://img.shields.io/cocoapods/l/PSoC4FirmwareUpdateiOS.svg?style=flat)](http://cocoapods.org/pods/PSoC4FirmwareUpdateiOS)
[![Platform](https://img.shields.io/cocoapods/p/PSoC4FirmwareUpdateiOS.svg?style=flat)](http://cocoapods.org/pods/PSoC4FirmwareUpdateiOS)

Bootloader based firmware update library for PSoC4 BLE, tested with the [CY8CKIT-042-BLE Kit](http://www.cypress.com/documentation/development-kitsboards/cy8ckit-042-ble-bluetooth-low-energy-ble-pioneer-kit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Implementation Notes
 - Supports security key
 - Pending SEND_DATA Implementation
 - Pending CRC16 Test

## Installation

PSoC4FirmwareUpdateiOS is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PSoC4FirmwareUpdateiOS"
```

## Test App

The example app has a bluetooth version of the firmware updater. The sample project used for the updater is at [PSoC4OTAUpdate](https://github.com/perusworld/PSoC4OTAUpdate)

## Usage

In order to use the APIs you need the following
 1. The new firmware file to update (**.cyacd** file), the example project referes to files at [PSoC4OTAUpdate Sample Binaries](https://github.com/perusworld/PSoC4OTAUpdate/tree/master/binaries)
 1. The BLE connectivity information for the PSoC4, which includes
    * **Scan Service UUID** - The service to lookup during scan, it could be same as the bootloader update service or could be a separate service just for lookup. The example project searches for a separate service advertised by [PSoC4OTAUpdate](https://github.com/perusworld/PSoC4OTAUpdate) with the UUID **00000000-0000-1000-8000-00805F9B34FB**
    * **Bootloader Service UUID** - The service to send firmware data to, it could be same as the scan service or could be a separate service just for firmware update. The example project searches for a separate service that is **not** advertised by [PSoC4OTAUpdate](https://github.com/perusworld/PSoC4OTAUpdate) with the UUID **00060000-f8ce-11e4-abf4-0002a5d5c51b**
    * **Bootloader tx characteristics UUID** - The characteristics to write the firmware data to, it could be same as the read characteristics or could be a separate characteristics just for writes. The example project defines the same characteristics used by [PSoC4OTAUpdate](https://github.com/perusworld/PSoC4OTAUpdate) with the UUID **00060001-f8ce-11e4-abf4-0002a5d5c51b**
    * **Bootloader rx characteristics UUID** - The characteristics to read the bootloader status from, it could be same as the write characteristics or could be a separate characteristics just for reads. The example project defines the same characteristics used by [PSoC4OTAUpdate](https://github.com/perusworld/PSoC4OTAUpdate) with the UUID **00060001-f8ce-11e4-abf4-0002a5d5c51b**

### Scan

The PSoC4 board needs to be put in the Firmware update mode, inorder to do that click on the firmware update button on the board. For the example project [PSoC4OTAUpdate](https://github.com/perusworld/PSoC4OTAUpdate) that switch is the sw2 on the [CY8CKIT-042-BLE Kit](http://www.cypress.com/documentation/development-kitsboards/cy8ckit-042-ble-bluetooth-low-energy-ble-pioneer-kit)

The example project uses the [BleComm](https://github.com/perusworld/BleComm) library for BLE connectivity
```swift
import BleComm
```

To scan for devices to be updated 
```swift
        var bleScan = BLEScan (
            serviceUUID: CBUUID(string: "00000000-0000-1000-8000-00805F9B34FB"),
            onScanDone: {
                (pheripherals:[String:NSUUID]?)->() in
                for(name, id) in pheripherals! {
                    self.entries["\(name) - (\(id.UUIDString))"] = id
                    self.names.append("\(name) - (\(id.UUIDString))")
                }
                self.tblEntries.reloadData()
            }
        )
```
Replace the UUID **00000000-0000-1000-8000-00805F9B34FB** with the one your board advertises on.

### Update

To update a specific board we need to read the firmware file first, the **.cyacd** file is a text file, in the example project we read the file from [PSoC4OTAUpdate Sample Binaries](https://github.com/perusworld/PSoC4OTAUpdate/tree/master/binaries).

```swift
    func readFirmware() {
        let urlToCall = "https://raw.githubusercontent.com/perusworld/PSoC4OTAUpdate/master/binaries/HelloAppUpdated.cyacd"
        Alamofire.request(.GET, urlToCall)
            .validate()
            .responseString { response in
                if (response.result.isSuccess) {
                    let otaData = FirmwareData()
                    otaData.parse(response.result.value!)
                    self.firmwareUpdater?.firmwareData = otaData
                } else {
                    self.printLog("failed to read firmware file")
                }
        }
    }
    
```

Once the file is read and the device to be updated is selected then to start the update process 

```swift
        var bleComm:  BLEComm
        var firmwareUpdater: FirmwareUpdater

        firmwareUpdater = FirmwareUpdater(delegate: self, progress: self)
        self.readFirmware()
        bleComm = BLEComm (
            deviceId : deviceId,
            serviceUUID: CBUUID(string: "00060000-f8ce-11e4-abf4-0002a5d5c51b"),
            txUUID: CBUUID(string: "00060001-f8ce-11e4-abf4-0002a5d5c51b"),
            rxUUID: CBUUID(string: "00060001-f8ce-11e4-abf4-0002a5d5c51b"),
            onConnect:{
                self.printLog("Connected")
                self.firmwareUpdater?.startUpdate()
            },	
            onDisconnect:{
                self.printLog("Firmware updated \(self.firmwareUpdater!.firmwareUpdated())")
                self.printLog("Disconnect")
            },
            onData: {
                (string:NSString?, rawData: NSData?)->() in
                self.firmwareUpdater?.onData(rawData!)
            },
            mxSize: 150
        )
```

Also the controller or class should implement the following protocols **FirmwareCommDelegate**, **FirmwareUpdateProgressDelegate** 
```swift
    func write(data: NSData) {
        self.bleComm?.writeData(data)
    }
    
    func onProgress(state: String) {
        print(state)
        if ("update.failed" == state) {
            bleComm?.disconnect()
        }
    }
    
    func onProgress(state: String, current: Int, max: Int) {
        printLog("\(state) \(current) of \(max)")
    }    
```

## License

PSoC4FirmwareUpdateiOS is available under the MIT license. See the LICENSE file for more info.
