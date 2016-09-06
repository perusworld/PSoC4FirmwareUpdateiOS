import UIKit
import CoreBluetooth
import BleComm
import Alamofire
import PSoC4FirmwareUpdateiOS

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FirmwareCommDelegate, FirmwareUpdateProgressDelegate {

    @IBOutlet weak var tblLogs: UITableView!
    
    var bleComm:  BLEComm?
    var firmwareUpdater: FirmwareUpdater?
    var logs = [String]()
    
    var deviceId : NSUUID!
    
    let textCellIdentifier = "TextCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tblLogs.delegate = self
        tblLogs.dataSource = self
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
    }
    
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
    
    override func viewWillDisappear(animated: Bool) {
        bleComm!.disconnect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func printLog(logString:String) {
        logs.insert(logString, atIndex: 0)
        tblLogs.reloadData()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        let row = indexPath.row
        cell.textLabel?.text = logs[row]
        return cell
    }
    
}

