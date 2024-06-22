import Foundation
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    private init() {
        authorizeHealthKit()
    }
    
    func authorizeHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let bpmType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        healthStore.requestAuthorization(toShare: nil, read: [bpmType]) { (success, error) in
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("HealthKit authorization request successful.")
            } else {
                print("HealthKit authorization request denied.")
            }
        }
    }
    
    func fetchHeartRate(completion: @escaping (Double?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Heart Rate Type is no longer available in HealthKit.")
            completion(nil)
            return
        }
        
        let now = Date()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                } else {
                    print("No heart rate data available.")
                }
                completion(nil)
                return
            }
            
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
}
