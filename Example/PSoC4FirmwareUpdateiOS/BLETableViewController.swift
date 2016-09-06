import UIKit
import CoreBluetooth
import BleComm

class BLETableViewController: UITableViewController {
    
    var bleScan : BLEScan!
    var entries : [String:NSUUID] = [:]
    var names : [String] = []

    @IBOutlet var tblEntries: UITableView!

    let textCellIdentifier = "TextCell"
    let segueIdentifier = "ConnectToDevice"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        entries = [:]
        names = []
        tblEntries.reloadData()
        bleScan = BLEScan (
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        let row = indexPath.row
        cell.textLabel?.text = names[row]
        return cell

        //return cell
    }



    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdentifier {
            if let destination = segue.destinationViewController as? ViewController {
                if let nameIndex = tableView.indexPathForSelectedRow?.row {
                    destination.deviceId = entries[names[nameIndex]]
                }
            }
        }
    }
    
    
}
