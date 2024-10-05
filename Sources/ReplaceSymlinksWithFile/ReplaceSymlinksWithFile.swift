// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import ReplaceWithSymlinksCore

@main
struct ReplaceSymlinksWithFile: AsyncParsableCommand {
	@Flag(name: .shortAndLong, help: "Recurse into directories...")
	var recurse = false

	@Flag(name: [.long, .customShort("n", allowingJoined: true)], help: "Dry run - don't actually make changes")
	var dryRun = false

	enum Mode: String {
		case copy
		case move
	}

	@Option(
		name: .shortAndLong,
		help: "Should files be moved or copied. Valid values are `move` or `copy`, no quotes.",
		completion: .list(["move", "copy"]),
		transform: {
			try Mode(rawValue: $0.lowercased()).unwrap("Invalid mode value \($0)")
		})
	var mode: Mode

	@Argument(
		help: "The directory the symlinks are in",
		completion: .directory,
		transform: { URL(fileURLWithPath: $0, relativeTo: .currentDirectory()) })
	var sourceDirectory: URL

	mutating func run() async throws {
		print("Searching for symlinks in \(sourceDirectory.path(percentEncoded: false))")
		if dryRun {
			print("Dry run. No changes will be made...")
		}

		let options: FileManager.DirectoryEnumerationOptions = {
			if recurse {
				[]
			} else {
				.skipsSubdirectoryDescendants
			}
		}()
		let enumerator = try FileManager.default.enumerator(
			at: sourceDirectory,
			includingPropertiesForKeys: [.isSymbolicLinkKey],
			options: options)
			.unwrap("Error creating directory enumerator")

		while let symlinkURL = enumerator.nextObject() as? URL {
			guard
				try symlinkURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true
			else { continue }

			let original = try URL(resolvingAliasFileAt: symlinkURL, options: [])

			let verb: String
			let action: (URL, URL) throws -> Void
			switch mode {
			case .copy:
				verb = "copying"
				action = FileManager.default.copyItem
			case .move:
				verb = "moving"
				action = FileManager.default.moveItem
			}
			print("\(verb) file at \(original.path(percentEncoded: false)) to \(symlinkURL.path(percentEncoded: false))")
			try FileManager.default.trashItem(at: symlinkURL, resultingItemURL: nil)
			try action(original, symlinkURL)
		}

	}
}
