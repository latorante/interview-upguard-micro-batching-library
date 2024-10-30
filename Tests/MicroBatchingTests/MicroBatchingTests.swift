import Testing
@testable import MicroBatching

actor MockBatchProcessor: BatchProcessor {
    private var _processedBatches: [[Job]] = []

    var processedBatches: [[Job]] {
        return _processedBatches
    }

    nonisolated func process(batch: [Job]) -> [JobResult] {
        // Start an asynchronous task to process the batch
        Task {
            await addBatch(batch) // Mutate the internal state safely
        }

        return batch.map { _ in JobResult(result: nil, error: nil) } // Simulate success immediately
    }

    private func addBatch(_ batch: [Job]) async {
        _processedBatches.append(batch) // Mutate the internal state safely
    }
}

final class MicroBatchingTests {

    @Test
    func testMicroBatching_SubmitJobs_ProcessesInBatches() async throws {
        let config = MicroBatchingConfig(batchSize: 5, batchFrequency: 0.1)
        let mockProcessor = MockBatchProcessor()
        let microBatching = MicroBatching(config: config, batchProcessor: mockProcessor)

        // Submit 5 jobs
        for i in 1...10 {
            await microBatching.submit {
                return JobResult(result: "Job \(i)", error: nil)
            }
        }

        // Wait for a bit to allow processing
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for 0.5 seconds

        // Access processed batches safely
        let processedBatches = await mockProcessor.processedBatches // Access asynchronously
        
        // Verify that two batches were processed, each with 5 elements inside
        #expect(processedBatches.count == 2)
        #expect(processedBatches[0].count == 5)  // First batch should contain 3 jobs
        #expect(processedBatches[1].count == 5)  // Second batch should contain 2 jobs
    }
}
