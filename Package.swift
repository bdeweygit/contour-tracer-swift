// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ContourTracer",
  products: [
    .library(name: "ContourTracer", targets: ["ContourTracer"])
  ],
  targets: [
    .target(name: "ContourTracer"),
    .testTarget(name: "ContourTracerTests", dependencies: ["ContourTracer"]),
  ]
)
