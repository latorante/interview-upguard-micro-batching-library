// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// Job is a task to be processed.
// It's a closure that returns a JobResult, which means it does some work and gives us a result back.
public typealias Job = @Sendable () -> JobResult

// Outcome of a processed job.
// It can either contain a successful result or an error if something went wrong.
public struct JobResult {
    public let result: Any?
    public let error: Error?
    
    public init(result: Any?, error: Error?) {
        self.result = result
        self.error = error
    }
}

// BatchProcessor protocol defines how to process a batch of jobs.
public protocol BatchProcessor {
    func process(batch: [Job]) -> [JobResult]
}

// MicroBatchingConfig allows for customizable batching behavior.
public struct MicroBatchingConfig {
    public let batchSize: Int
    public var batchFrequency: TimeInterval // Frequency for processing the batch
    
    public init(batchSize: Int, batchFrequency: TimeInterval) {
        self.batchSize = batchSize
        self.batchFrequency = batchFrequency
    }
}

// Base Micro Batcher Class
public actor MicroBatching {
    // Config for the batcher
    private let config: MicroBatchingConfig
    // Array of jobs received by the batcher
    private var jobs: [Job] = []
    
    // A flag to check if we're currently processing jobs.
    private var isProcessing: Bool = false
    
    // A reference to the batch processor we’ll use to handle job processing.
    public let batchProcessor: BatchProcessor

    public init(config: MicroBatchingConfig, batchProcessor: BatchProcessor) {
        self.config = config
        self.batchProcessor = batchProcessor
    }
    
    /// Submit a job to be processed.
    /// When we get a job, we kick off the processing if we aren't already doing it.
    public func submit(job: @escaping Job) {
        Task {
            await processJob(job)
        }
    }
    
    /// Add job to the queue to be processed.
    private func processJob(_ job: @escaping Job) async {
        jobs.append(job) // Add the job to the queue.
        // If we're not currently processing jobs, start processing.
        if !isProcessing {
            isProcessing = true // Mark that we’re now processing.
            await start() // Start the batch processing.
        }
    }
    
    /// Start processing jobs in batches.
    private func start() async {
        isProcessing = true
        var lastProcessedTime = Date()

        while !jobs.isEmpty {
            var currentBatch: [Job] = []

            // Collect jobs until batch size is reached or the frequency timeout occurs
            while currentBatch.count < config.batchSize {
                guard !jobs.isEmpty else { break }
                let job = await jobs.removeFirst()
                currentBatch.append(job)
            }

            if !currentBatch.isEmpty {
                let results = batchProcessor.process(batch: currentBatch)
                print("Processed batch with results: \(results)")
                lastProcessedTime = Date() // Update the last processed time
            }

            // Wait until the frequency timeout before checking for more jobs
            let elapsedTime = Date().timeIntervalSince(lastProcessedTime)
            if elapsedTime < config.batchFrequency {
                await Task.sleep(UInt64((config.batchFrequency - elapsedTime) * 1_000_000_000)) // Sleep for the remaining time
            }
        }

        isProcessing = false
    }

    
    /// Shutdown the batcher, waiting for all jobs to be processed.
    public func shutdown() async {
        while isProcessing || !jobs.isEmpty {
            await Task.yield()
        }
    }
}
