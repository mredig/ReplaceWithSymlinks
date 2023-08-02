import Foundation
import CryptoKit

public enum ReplaceWithSymlinksCore {
	public static func replaceFiles(
		in destinationDirectory: URL,
		withFileSymlinksFrom sourceDirectory: URL,
		commit: Bool,
		compareHashes: Bool) async throws {

			let fm = FileManager.default

			let destinationContents = try fm
				.contentsOfDirectory(at: destinationDirectory, includingPropertiesForKeys: [URLResourceKey.isSymbolicLinkKey])
				.filter {
					let values = try $0.resourceValues(forKeys: [.isSymbolicLinkKey])
					return values.isSymbolicLink == false
				}

			let sourceContents = try fm
				.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil)
				.filter {
					let values = try $0.resourceValues(forKeys: [.isSymbolicLinkKey])
					return values.isSymbolicLink == false
				}

			let dups = try await duplicates(
				betweenSourceContent: sourceContents,
				andDestinationContent: destinationContents,
				comparingHashes: compareHashes)
			print("matches: ")
			dups.forEach { print($0.lastPathComponent) }

			guard commit else { return }

			for dup in dups {
				let destinationFileURL = destinationDirectory.appending(component: "\(dup.lastPathComponent)", directoryHint: .notDirectory)
				try fm.trashItem(at: destinationFileURL, resultingItemURL: nil)
				let url = URL(string: destinationFileURL.relativePath(to: dup).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
				try fm.createSymbolicLink(at: destinationFileURL, withDestinationURL: url)
			}
		}

	private static func duplicates(
		betweenSourceContent sourceContents: [URL],
		andDestinationContent destinationContent: [URL],
		comparingHashes: Bool) async throws -> [URL] {

			func key(_ keyValue: String) -> String {
				comparingHashes ? keyValue.lowercased() : keyValue
			}

			let destinationNames = destinationContent.reduce(into: [String: URL](), {
				$0[key($1.lastPathComponent)] = $1
			})
			let matches = sourceContents.filter { destinationNames[key($0.lastPathComponent)] != nil }

			guard comparingHashes else { return matches }

			let hashMatches = try await withThrowingTaskGroup(of: URL?.self) { group in
				for sourceURL in matches {
					guard let destinationURL = destinationNames[key(sourceURL.lastPathComponent)] else { continue }
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
			print()

			return hashMatches
		}
}
