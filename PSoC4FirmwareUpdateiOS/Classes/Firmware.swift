import Foundation

let COMMAND_START_BYTE: UInt8 = 0x01
let COMMAND_END_BYTE: UInt8 = 0x17
//Bootloader command codes
let VERIFY_CHECKSUM: UInt8 = 0x31
let GET_FLASH_SIZE: UInt8 = 0x32
let SEND_DATA: UInt8 = 0x37
let ENTER_BOOTLOADER: UInt8 = 0x38
let PROGRAM_ROW: UInt8 = 0x39
let VERIFY_ROW: UInt8 = 0x3A
let EXIT_BOOTLOADER: UInt8 = 0x3B
// Bootloader status/Error codes
let SUCCESS = "00"
let ERROR_FILE = "0x01"
let ERROR_EOF = "0x02"
let ERROR_LENGTH = "0x03"
let ERROR_DATA = "0x04"
let ERROR_COMMAND = "0x05"
let ERROR_DEVICE = "0x06"
let ERROR_VERSION = "0x07"
let ERROR_CHECKSUM = "0x08"
let ERROR_ARRAY = "0x09"
let ERROR_ROW = "0x0A"
let ERROR_BOOTLOADER = "0x0B"
let ERROR_APPLICATION = "0x0C"
let ERROR_ACTIVE = "0x0D"
let ERROR_UNKNOWN = "0x0F"
let ERROR_ABORT = "0xFF"

let COMMAND_PACKET_MIN_SIZE = 7
let FILE_HEADER_MAX_LENGTH = 12
let FILE_PARSER_ERROR_CODE = 555
let MAX_DATA_SIZE = 133

let RESPONSE_START = 1

let STATUS_FAILED = "update.failed"
let STATUS_PROGRESS = "update.progress"


extension NSData {
    
    func hexArray()->[String] {
        var ret = [String]()
        let dataLength:Int = self.length
        let dataBytes = UnsafePointer<UInt8>(self.bytes)
        for idx in 0..<dataLength {
            ret.append(String(format:"%02x", arguments: [dataBytes[idx]]))
        }
        
        return ret
    }
    
}


extension String {
    
    func subStr(from:Int, to: Int) ->String {
        let start = self.startIndex.advancedBy(from)
        let end = self.startIndex.advancedBy(to)
        let range = start..<end
        return self.substringWithRange(range)
    }
    
    func hexInt(from:Int, to: Int) ->Int {
        let value = self.subStr(from, to: to)
        var outVal: CUnsignedInt = 0
        let scanner: NSScanner = NSScanner(string: value)
        scanner.scanHexInt(&outVal)
        return Int(outVal)
    }
    
    func hexByteArray() ->[UInt8] {
        var ret = [UInt8]()
        var index = 0
        while index + 2 <= characters.count {
            ret.append(UInt8(self.hexInt(index, to: index+2)))
            index += 2
        }
        return ret
    }
    
    func asciiArray() -> [UInt8] {
        return unicodeScalars.filter{$0.isASCII()}.map{UInt8($0.value)}
    }
    
}


public protocol FirmwareCommDelegate: Any {
    func write(data:NSData)
}

public protocol FirmwareUpdateProgressDelegate: Any {
    func onProgress(state: String)
    func onProgress(state:String, current:Int, max:Int)
}

public class FirmwareUpdater: NSObject {

    var isWriteRowDataSuccess: Bool!
    var isWritePacketDataSuccess: Bool!
    var isApplicationValid: Bool!

    var siliconIDString: String!
    var siliconRevString: String!
    var checkSumType: String!
    var programRowStartPos: Int!
    var checkSum: UInt8!
    var delegate: FirmwareCommDelegate!
    var progress: FirmwareUpdateProgressDelegate!
    public var firmwareData: FirmwareData!
    var commandCode: UInt8!
    var rowIndex = 0
    var arrayId: UInt8 = 0

    public init(delegate:FirmwareCommDelegate, progress: FirmwareUpdateProgressDelegate){
        super.init()
        self.delegate = delegate
        self.progress = progress
    }
    
    public func firmwareUpdated() -> Bool {
        return nil != commandCode && commandCode == EXIT_BOOTLOADER
    }

    public func startUpdate(securityKey: String = "") {
        rowIndex = 0
        if ("00" == self.firmwareData.checksumType) {
            self.checkSumType = CHECK_SUM
        } else {
            self.checkSumType = CRC_16
        }
        if ("" == securityKey) {
            let data = self.createCommandPacketWithCommand(ENTER_BOOTLOADER, dataLength: 0, row: nil)
            self.delegate.write(data)
        } else {
            let key = securityKey.asciiArray()
            var row = FirmwareRow()
            row.dataArray = key
            let data = self.createCommandPacketWithCommand(ENTER_BOOTLOADER, dataLength: key.count, row: row)
            self.delegate.write(data)
        }
    }

    func getFlashSize() {
        let data = self.createCommandPacketWithCommand(GET_FLASH_SIZE, dataLength: 1, row: firmwareData.data[rowIndex])
        self.delegate.write(data)
    }

    func programRow(index: Int) {
        progress.onProgress(STATUS_PROGRESS, current: index + 1, max: firmwareData.data.count)
        var row : FirmwareRow
        let startPos = programRowStartPos
        row = firmwareData.data[rowIndex]
        if (row.arrayId == arrayId) {
            if ((row.dataLength - startPos) <= MAX_DATA_SIZE) {
                let data = self.createCommandPacketWithCommand(PROGRAM_ROW, dataLength: row.dataLength + 3, row: firmwareData.data[rowIndex])
                self.delegate.write(data)
            } else {
                print("too long \(row.dataLength) send data not implemented yet")
                progress.onProgress(STATUS_FAILED)
            }
        } else {
            progress.onProgress(STATUS_FAILED)
        }
    }

    func verifyRow(index: Int) {
        var row : FirmwareRow
        row = firmwareData.data[rowIndex]
        if (row.arrayId == arrayId) {
            let data = self.createCommandPacketWithCommand(VERIFY_ROW, dataLength: 3, row: firmwareData.data[rowIndex])
            self.delegate.write(data)
        } else {
            progress.onProgress(STATUS_FAILED)
        }
    }

    func verifyChecksum() {
        let data = self.createCommandPacketWithCommand(VERIFY_CHECKSUM, dataLength: 0, row: nil)
        self.delegate.write(data)
    }

    func exitBootLoader() {
        let data = self.createCommandPacketWithCommand(EXIT_BOOTLOADER, dataLength: 0, row: nil)
        self.delegate.write(data)
    }

    func createCommandPacketWithCommand(commandCode: UInt8, dataLength: Int, row: FirmwareRow?) -> NSData {
        var data: NSData = NSData()
        var commandPacket = [UInt8]()
        self.commandCode = commandCode
        commandPacket.append(COMMAND_START_BYTE)
        commandPacket.append(commandCode)
        commandPacket.append(UInt8(dataLength))
        commandPacket.append(UInt8(dataLength >> 8))

        if commandCode == GET_FLASH_SIZE {
            commandPacket.append(row!.arrayId)
            self.arrayId = row!.arrayId
        }
        if commandCode == PROGRAM_ROW || commandCode == VERIFY_ROW {
            commandPacket.append(row!.arrayId)
            commandPacket.append(UInt8(row!.rowNumber & 0xff))
            commandPacket.append(UInt8(row!.rowNumber >> 8))
        }
        if ((commandCode == SEND_DATA || commandCode == PROGRAM_ROW) || (commandCode == ENTER_BOOTLOADER && 0 < dataLength)) {
            for byte in row!.dataArray {
                commandPacket.append(byte)
            }
        }
        let checkSum: UInt16 = Checksum().checksum(commandPacket, type: checkSumType)
        commandPacket.append(UInt8(checkSum & 0xff))
        commandPacket.append(UInt8(checkSum >> 8))
        commandPacket.append(COMMAND_END_BYTE)
        data = NSData(bytes: commandPacket, length: (commandPacket.count))
        return data
    }

    public func onData(rawData: NSData) {
        let data = rawData.hexArray()
        let errorCode = data[1]
        if (errorCode == SUCCESS) {
            switch commandCode {
            case ENTER_BOOTLOADER:
                self.onEnterBootLoader(data)
                break
            case GET_FLASH_SIZE:
                self.onGetFlashSize(data)
                break
            case PROGRAM_ROW:
                self.onProgramRow(data)
                break
            case VERIFY_ROW:
                self.onVerifyRow(data)
                break
            case VERIFY_CHECKSUM:
                self.onVerifyChecksum(data)
                break
            default:
                print(data);
                progress.onProgress(STATUS_FAILED)
                break
            }
        } else {
            print(data);
            progress.onProgress(STATUS_FAILED)
        }
    }

    func onEnterBootLoader(data: [String]) {
        siliconIDString = ""
        var idx = 7
        while idx >= 4 {
            siliconIDString.appendContentsOf(data[idx])
            idx -= 1
        }
        siliconRevString = data[8]
        if (siliconIDString.caseInsensitiveCompare(firmwareData.siliconID) == .OrderedSame && siliconRevString.caseInsensitiveCompare(firmwareData.siliconRev) == .OrderedSame) {
            self.getFlashSize()
        } else {
            progress.onProgress(STATUS_FAILED)
        }
    }

    func onGetFlashSize(data: [String]) {
        rowIndex = 0
        programRowStartPos = 0
        programRow(rowIndex)
    }

    func onProgramRow(data: [String]) {
        self.verifyRow(rowIndex)
    }

    func onVerifyRow(data: [String]) {
        let row = firmwareData.data[rowIndex]
        let chkSm:[UInt8] = [row.checksum, row.arrayId, UInt8(row.rowNumber & 0xff), UInt8(row.rowNumber >> 8), UInt8(row.dataLength & 0xff), UInt8(row.dataLength >> 8)]
        var sum = 0
        for item in chkSm {
            sum = sum + Int(item)
        }
        let checkSum = String(format:"%02x", arguments: [UInt8(sum & 0xff)]);
        if (checkSum == data[4]) {
            rowIndex += 1;
            if (rowIndex < firmwareData.data.count) {
                programRow(rowIndex)
            } else {
                verifyChecksum()
            }
        } else {
            progress.onProgress(STATUS_FAILED)
        }
    }

    func onVerifyChecksum(data: [String]) {
        if ("00" == data[4]) {
            progress.onProgress(STATUS_FAILED)
        } else {
            exitBootLoader()
        }
    }

    func swap(value: UInt32) -> UInt32 {
        let b1 = (value >> 0) & 0xff
        let b2 = (value >> 8) & 0xff
        let b3 = (value >> 16) & 0xff
        let b4 = (value >> 24) & 0xff
        return b1 << 24 | b2 << 16 | b3 << 8 | b4 << 0
    }

    func hexInt(data: String, reverse: Bool = true) -> Int {
        let scanner = NSScanner(string: data)
        var result : UInt32 = 0
        if scanner.scanHexInt(&result) {
            return reverse ? Int(swap(result)) : Int(result)
        }
        return -1;
    }

}

struct FirmwareRow {
    var arrayId: UInt8 = 0
    var rowNumber: Int = 0
    var dataLength: Int = 0
    var checksum: UInt8 = 0
    var data = ""
    var dataArray = [UInt8]()
}

public class FirmwareData: NSObject {

    var siliconID: String!
    var siliconRev: String!
    var checksumType: String!
    var data = [FirmwareRow]()

    public func parse(data: String) {
        let newlineChars = NSCharacterSet.newlineCharacterSet()
        let lineArray = data.componentsSeparatedByCharactersInSet(newlineChars).filter{!$0.isEmpty}
        let cleaned = self.removeEmptyRowsAndJunkDataFromArray(lineArray)

        var first = true
        for line in cleaned {
            if (first) {
                first = false;
                if (FILE_HEADER_MAX_LENGTH <= line.characters.count) {
                    siliconID = line.subStr(0, to: 8)
                    siliconRev = line.subStr(8, to: 10)
                    checksumType = line.subStr(10, to: 12)
                } else {
                    //ERROR
                    break;
                }
            } else {
                var row = FirmwareRow()
                row.arrayId = UInt8(line.hexInt(0, to: 2))
                row.rowNumber = line.hexInt(2, to: 6)
                row.dataLength = line.hexInt(6, to: 10)
                row.checksum = UInt8(line.hexInt(line.characters.count - 2, to: line.characters.count))
                row.data = line.subStr(10, to: line.characters.count - 2)
                if (row.dataLength == row.data.characters.count/2) {
                    row.dataArray = row.data.hexByteArray()
                    self.data.append(row)
                } else {
                    //ERROR
                    break;
                }
            }
        }
    }

    func removeEmptyRowsAndJunkDataFromArray(dataArray: [String]) -> [String] {
        var ret = [String]()
        var i = 0
        while i < dataArray.count {
            if (dataArray[i] == "") {
                //NOOP
            }
            else {
                let charactersToRemove: NSCharacterSet = NSCharacterSet.alphanumericCharacterSet().invertedSet
                let trimmedReplacement: String = dataArray[i].componentsSeparatedByCharactersInSet(charactersToRemove).joinWithSeparator("")
                ret.append(trimmedReplacement)
                i += 1
            }

        }
        return ret
    }


}