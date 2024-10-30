# micro-batching-library

This project is part of an interview, and presents a micro-batching library. 

## Installation


### Automatic

Add the repository url to your project, via Swift package manager in XCode, and select version as "branch" and "main".

### Via  Package.swift file

Add the package as a dependency in your `Package.swift` file:

```swift
// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "micro-batcher",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [
        ...
        .package(url: "https://github.com/latorante/interview-upguard-micro-batching-library", .branch("main"))
    ],
    targets: [
        .executableTarget(
            ...
            dependencies: [
                ...
                .product(name: "MicroBatching", package: "interview-upguard-micro-batching-library")
            ]),
    ]
)
```

## Usage

You need to implement your own `BatchProcessor` first, which follows the `BatchProcessor` protocol defined by this library.

Then you can create a `Batcher` instance, and start adding items to it. The `Batcher` will automatically call the `BatchProcessor` when needed.

```swift
import MicroBatching

let config = MicroBatchingConfig(batchSize: 10, batchFrequency: TimeInterval(1))
let batchProcessor = YourBatchProcessor()
let microBatching = MicroBatching(config: config, batchProcessor: batchProcessor)

let dispatchGroup = DispatchGroup()
dispatchGroup.enter()
Task {
    for i in 1...numberOfJobsToCreate {
        let job: Job = {
            // Simulating some work with sleep
            return JobResult(result: "Job \(i) completed", error: nil) // Return a result
        }
        await microBatching.submit(job: job) 
    }
    await microBatching.shutdown()
    print("micro-batchibg: All jobs have been processed.")
    dispatchGroup.leave() // Leave the dispatch group when done
}
dispatchGroup.wait()

```
