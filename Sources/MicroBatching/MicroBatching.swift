// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// Job represents a task to be processed.
typealias Job = () -> JobResult

// JobResult represents the result of a processed job.
struct JobResult {
    let result: Any?
    let error: Error?
}

// Base Micro Batcher Class
// TODO: Move to protocol - this is base only
class MicroBatching {
    private var jobs: [Job] = []
    private let batchSize: Int
    private let batchTimeout: TimeInterval
    private var isProcessing: Bool = false
    private let processingQueue = DispatchQueue(label: "com.upguard.processing.microbatching")
    private let shutdownSemaphore = DispatchSemaphore(value: 0)
    
    init(batchSize: Int, batchTimeout: TimeInterval) {
        self.batchSize = batchSize
        self.batchTimeout = batchTimeout
        // TODO: max size and max timeout
    }
    
    /// Submit a job to be processed
    func submit(job: @escaping Job) {
        // Implement
    }
    
    /// Start process
    private func start() {
        // Implement
        // NOTE: Swift5 concurrrency
    }
    
    /// Process a batch of jobs.
    private func processBatch() {
        // Implement
    }
    
    /// Shutdown the batcher, waiting for all jobs to be processed
    /// should be accessible from outside
    public func shutdown() {
        
    }
}
