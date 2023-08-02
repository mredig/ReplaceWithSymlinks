import Foundation
import CryptoKit

public enum ReplaceWithSymlinksCore {
	public static func replaceFiles(
		in destinationDirectory: URL,
		withFileSymlinksFrom sourceDirectory: URL,
		compareHashes: Bool) async throws {

			let fm = FileManager.default

			let destinationContents = try fm.contentsOfDirectory(at: destinationDirectory, includingPropertiesForKeys: nil)

			let sourceContents = try fm.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil)

			let dups = try await duplicates(
				betweenSourceContent: sourceContents,
				andDestinationContent: destinationContents,
				comparingHashes: compareHashes)
			print("matches: ")
			dups.forEach { print($0.lastPathComponent) }
		}

	private static func duplicates(
		betweenSourceContent sourceContents: [URL],
		andDestinationContent destinationContent: [URL],
		comparingHashes: Bool) async throws -> [URL] {

			let destinationNames = destinationContent.reduce(into: [String: URL](), {
				$0[$1.lastPathComponent] = $1
			})
			let matches = sourceContents.filter { destinationNames[$0.lastPathComponent] != nil }

			guard comparingHashes else { return matches }

			let hashMatches = try await withThrowingTaskGroup(of: URL?.self) { group in
				for sourceURL in matches {
					guard let destinationURL = destinationNames[sourceURL.lastPathComponent] else { continue }
					group.addTask {
						print("Comparing files named \(sourceURL.lastPathComponent)...")
						async let sourceHash = Insecure.MD5.hash(sourceURL)
						async let destinationHash = Insecure.MD5.hash(destinationURL)

						guard try await sourceHash == (try await destinationHash) else { return nil }
						print("\(sourceURL.lastPathComponent) match!")
						return sourceURL
					}
				}

				var matchingURLs: [URL] = []
				for try await matchingURL in group {
					guard let matchingURL else { continue }
					matchingURLs.append(matchingURL)
				}
				return matchingURLs
			}

			return hashMatches
		}
}
