import Foundation

class CalcBPM {
    func findNearbyValues(dictionary: [String: Int], input: Int) -> [String: Int] {
        let lowerBound = input - 5
        let upperBound = input + 5
        
        let result = dictionary.filter { (key, value) in
            return value >= lowerBound && value <= upperBound
        }
        
        return result
    }
}

// Example usage
//let dictionary = ["a": 66, "b": 68, "c": 73, "d": 76, "e": 120, "f": 126, "g": 129, "h": 131, "i": 205, "j": 210]
//let calcBPM = CalcBPM()
//let result = calcBPM.groupNumbersByStdDev(dictionary)
//print(result)
