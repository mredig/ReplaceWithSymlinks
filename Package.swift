// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ReplaceWithSymlinks",
	platforms: [
		.macOS(.v13),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/mredig/SwiftPizzaSnips.git", .upToNextMajor(from: "0.4.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "ReplaceWithSymlinks",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"ReplaceWithSymlinksCore",
			]
		),
		.executableTarget(
			name: "ReplaceSymlinksWithFile",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"ReplaceWithSymlinksCore",
			]
		),
		.target(
			name: "ReplaceWithSymlinksCore",
			dependencies: [
				"SwiftPizzaSnips",
			]
		)
	]
)
