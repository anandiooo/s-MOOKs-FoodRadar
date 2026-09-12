import Foundation

// Minimal, dependency-free PNG writer (8-bit greyscale).
//
// The sandbox has no image libraries and no network, so this encodes PNG directly:
// zlib container + DEFLATE "stored" (uncompressed) blocks. Files are larger than
// they need to be, which is irrelevant for design mockups and keeps the code short
// enough to audit in one sitting.

public enum PNG {
    /// Encodes a framebuffer as an 8-bit greyscale PNG, nearest-neighbour scaled.
    /// The 4-bit panel values 0...15 are mapped linearly onto 0...255.
    public static func encode(_ fb: FrameBuffer, scale: Int = 1) -> Data {
        let w = fb.width * scale
        let h = fb.height * scale

        // Raw scanlines: one filter byte (0 = None) per row, then w grey bytes.
        var raw = [UInt8]()
        raw.reserveCapacity(h * (w + 1))
        for y in 0..<h {
            raw.append(0)
            let srcY = y / scale
            for x in 0..<w {
                let v = fb.get(x / scale, srcY)
                raw.append(UInt8(min(255, Int(v) * 17))) // 15 * 17 = 255
            }
        }

        var out = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        var ihdr = Data()
        ihdr.append(be32(UInt32(w)))
        ihdr.append(be32(UInt32(h)))
        ihdr.append(contentsOf: [8, 0, 0, 0, 0]) // depth 8, greyscale, no interlace
        out.append(chunk("IHDR", ihdr))
        out.append(chunk("IDAT", zlibStored(raw)))
        out.append(chunk("IEND", Data()))
        return out
    }

    public static func write(_ fb: FrameBuffer, to url: URL, scale: Int = 1) throws {
        try encode(fb, scale: scale).write(to: url)
    }

    // MARK: - Container plumbing

    private static func be32(_ v: UInt32) -> Data {
        Data([UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)])
    }

    private static func chunk(_ type: String, _ payload: Data) -> Data {
        var d = be32(UInt32(payload.count))
        let typeBytes = Data(type.utf8)
        d.append(typeBytes)
        d.append(payload)
        d.append(be32(crc32(typeBytes + payload)))
        return d
    }

    /// zlib stream using stored DEFLATE blocks (max 65535 bytes each).
    private static func zlibStored(_ bytes: [UInt8]) -> Data {
        var d = Data([0x78, 0x01]) // CM=8, CINFO=7, FCHECK ok, no dictionary
        var offset = 0
        while offset < bytes.count {
            let len = min(65535, bytes.count - offset)
            let isFinal: UInt8 = (offset + len >= bytes.count) ? 1 : 0
            d.append(isFinal)
            d.append(UInt8(len & 0xFF))
            d.append(UInt8((len >> 8) & 0xFF))
            let nlen = ~UInt16(len)
            d.append(UInt8(nlen & 0xFF))
            d.append(UInt8((nlen >> 8) & 0xFF))
            d.append(contentsOf: bytes[offset..<(offset + len)])
            offset += len
        }
        d.append(be32(adler32(bytes)))
        return d
    }

    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 == 1) ? (0xEDB8_8320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    private static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in data {
            c = crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8)
        }
        return c ^ 0xFFFF_FFFF
    }

    private static func adler32(_ bytes: [UInt8]) -> UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0
        for byte in bytes {
            a = (a + UInt32(byte)) % 65521
            b = (b + a) % 65521
        }
        return (b << 16) | a
    }
}
