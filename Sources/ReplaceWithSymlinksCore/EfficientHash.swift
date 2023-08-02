import Foundation
import CryptoKit

extension HashFunction {
	static func hash(_ url: URL) async throws -> Self.Digest {
		let fh = try FileHandle(forReadingFrom: url)
		var hash = Self.init()

		print("Reading \(url)")
		var buffer = Data(capacity: 1024)
		for try await byte in fh.bytes {
			buffer.append(byte)

			if buffer.count >= 1024 {
				hash.update(data: buffer)
				buffer = Data(capacity: 1024)
			}
		}

		if buffer.isEmpty == false {
			hash.update(data: buffer)
		}
		print("finished \(url)")

		return hash.finalize()
	}
}
