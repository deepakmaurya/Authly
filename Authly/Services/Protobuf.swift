import Foundation

/// Minimal protobuf wire-format reader. Just enough for the
/// Google Authenticator migration payload — varints, length-delimited fields.
struct ProtoReader {
    private let data: Data
    private var index: Int

    init(_ data: Data) {
        self.data = data
        self.index = 0
    }

    var isAtEnd: Bool { index >= data.count }

    mutating func readVarint() -> UInt64? {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while index < data.count {
            let byte = data[index]
            index += 1
            result |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 { return result }
            shift += 7
            if shift >= 64 { return nil }
        }
        return nil
    }

    mutating func readTag() -> (field: Int, wire: Int)? {
        guard let v = readVarint() else { return nil }
        return (Int(v >> 3), Int(v & 0x07))
    }

    mutating func readLengthDelimited() -> Data? {
        guard let len = readVarint() else { return nil }
        let length = Int(len)
        guard index + length <= data.count else { return nil }
        let slice = data.subdata(in: index..<(index + length))
        index += length
        return slice
    }

    mutating func skip(wire: Int) {
        switch wire {
        case 0: _ = readVarint()
        case 1: index = min(index + 8, data.count)
        case 2: _ = readLengthDelimited()
        case 5: index = min(index + 4, data.count)
        default: index = data.count
        }
    }
}
