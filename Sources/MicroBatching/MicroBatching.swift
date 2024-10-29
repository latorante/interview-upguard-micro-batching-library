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
    public let batchTimeout: TimeInterval
    
    public init(batchSize: Int, batchTimeout: TimeInterval) {
        self.batchSize = batchSize
        self.batchTimeout = batchTimeout
    }
}

// Base Micro Batcher Class
public actor MicroBatching {
    // Array of jobs received by the batcher
    private var jobs: [Job] = []
    
    // Configurable properties for batch size and timeout.
    public let batchSize: Int
    public let batchTimeout: TimeInterval
    
    // A flag to check if we're currently processing jobs.
    private var isProcessing: Bool = false
    
    // A reference to the batch processor we’ll use to handle job processing.
    public let batchProcessor: BatchProcessor

    public init(config: MicroBatchingConfig, batchProcessor: BatchProcessor) {
        self.batchSize = config.batchSize
        self.batchTimeout = config.batchTimeout
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
        while true {
            var currentBatch: [Job] = []
            
            // Collect jobs until we reach batch size or timeout
            let batchReady = await collectBatch(&currentBatch)
            
            // Process the collected batch if we have one
            if !currentBatch.isEmpty {
                let results = batchProcessor.process(batch: currentBatch)
                // Handle the results as needed
                print("Processed batch with results: \(results)")
            }

            // Exit if no jobs are left and we've processed the batch
            if !batchReady && jobs.isEmpty {
                break
            }
        }
        isProcessing = false
    }
    
    /// Collect a batch of jobs.
    private func collectBatch(_ batch: inout [Job]) async -> Bool {
        let startTime = Date()
        while jobs.count > 0 && batch.count < batchSize {
            if let job = jobs.first {
                jobs.removeFirst()
                batch.append(job)
            }
            
            // Check for timeout
            if Date().timeIntervalSince(startTime) >= batchTimeout {
                return !batch.isEmpty // Return true if batch has jobs
            }
        }
        return !batch.isEmpty || batch.count == batchSize
    }
    
    /// Shutdown the batcher, waiting for all jobs to be processed.
    public func shutdown() async {
        while isProcessing || !jobs.isEmpty {
            await Task.yield()
        }
    }
}
