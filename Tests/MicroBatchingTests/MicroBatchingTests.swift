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
    func testMicroBatching_VariousBatchSizes() async throws {
        
        // Iteratae over test cases
        let testCases: [(batchSize: Int, totalJobs: Int)] = [
            (batchSize: 10, totalJobs: 20),
            (batchSize: 5, totalJobs: 20),
            (batchSize: 2, totalJobs: 10)
        ]
        
        for testCase in testCases {
            let config = MicroBatchingConfig(batchSize: testCase.batchSize, batchFrequency: 0.1)
            let mockProcessor = MockBatchProcessor()
            let microBatching = MicroBatching(config: config, batchProcessor: mockProcessor)

            // Submit jobs
            for i in 1...testCase.totalJobs {
                await microBatching.submit {
                    return JobResult(result: "Job \(i)", error: nil)
                }
            }

            // Wait for a bit to allow processing
            try await Task.sleep(nanoseconds: 500_000_000) // Wait for 0.5 seconds

            // Access processed batches safely
            let processedBatches = await mockProcessor.processedBatches // Access asynchronously
            
            // Calculate the expected number of batches
            let expectedBatches = (testCase.totalJobs + testCase.batchSize - 1) / testCase.batchSize
            
            // Verify the number of batches processed
            #expect(processedBatches.count == expectedBatches)
            #expect(processedBatches.allSatisfy { $0.count == min(testCase.batchSize, testCase.totalJobs % testCase.batchSize) || $0.count == testCase.batchSize })
        }
    }
}
