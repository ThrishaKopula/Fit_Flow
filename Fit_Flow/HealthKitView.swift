import SwiftUI
import HealthKit

struct HealthKitView: View {
    @State private var heartRate: String = "Fetching heart rate..."

    var body: some View {
        VStack {
            Text(heartRate)
                .font(.largeTitle)
                .padding()
        }
        .onAppear {
            HealthManager.shared.fetchHeartRate { rate in
                DispatchQueue.main.async {
                    self.heartRate = "\(Int(rate ?? 0)) bpm"
                }
            }
        }
    }
}
