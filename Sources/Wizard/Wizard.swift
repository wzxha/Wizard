import Foundation
import QuartzCore

struct Function {
    let id: String
    let name: String
    let kitName: String

    init?(symbol: String) {
        do {
            let regex = try NSRegularExpression(pattern: #"\s+"#, options: .caseInsensitive)
            var location = 0
            var values: [String] = []
            regex.enumerateMatches(in: symbol, options: .reportProgress, range: NSRange(location: 0, length: symbol.count)) { (result, _, _) in
                guard let result = result else { return }
                if result.range.location > location {
                    values.append((symbol as NSString).substring(with: NSRange(location: location, length: result.range.location - location)))
                    location = result.range.location + result.range.length
                }
            }
            if values.count >= 5 {
                kitName = values[1]
                id = values[2]
                name = values[3]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

typealias FunctionRun = (function: Function, timeInterval: TimeInterval)
typealias FunctionMap = [String: FunctionRun]

public class Wizard {
    static let shared = Wizard()

    private var timer: Timer?
    private var timeOffset: TimeInterval = 0.01
    private var functionMap: FunctionMap = [:]

    public static func fire() {
        shared.fire()
    }

    public static func stop() {
        shared.stop()
    }

    func fire() {
        if timer == nil {
            let timer = Timer(timeInterval: timeOffset, target: self, selector: #selector(updateStackSymbols), userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: .common)
            self.timer = timer
        }
        timer?.fire()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        output()
        functionMap = [:]
    }

    @objc private func updateStackSymbols() {
        let stackSymbols = Thread.callStackSymbols
        let functions = stackSymbols.compactMap { Function(symbol: $0) }
        functions.forEach { merge($0) }
    }

    private func merge(_ function: Function) {
        var timeInterval: TimeInterval = 0
        if let functionRun = functionMap[function.id] {
            timeInterval = functionRun.timeInterval + timeOffset
        }
        self.functionMap[function.id] = (function: function, timeInterval: timeInterval)
    }

    private func output() {
        print("[Wizard]: \n")
        functionMap
            .compactMap({ $0.value })
            .sorted(by: { $0.timeInterval > $1.timeInterval })
            .forEach { functionRun in
                print(" - \(functionRun.function.id)  \(functionRun.function.kitName)       \(functionRun.function.name)  \(functionRun.timeInterval)s")
            }
        print("\n")
    }
}
