//
//  MemoryDataSourceError.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 29/7/25.
//


import Foundation

enum MemoryDataSourceError: Error {
    case expired
    case notInitialized
}

final class InstanceStore {
    static var instances: [String: Any] = [:]
}

class MemoryDataSource<T> {
    private var storedValue: T?
    private var timestamp: Date?
    private let cacheTTL: TimeInterval

    static var shared: Self {
        let key = String(describing: self)
        if let instance = InstanceStore.instances[key] as? Self {
            return instance
        } else {
            let newInstance = Self(cacheTTL: 31536000)
            InstanceStore.instances[key] = newInstance
            return newInstance
        }
    }

    static func configureShared(cacheTTL: TimeInterval) {
        let key = String(describing: self)
        let newInstance = Self(cacheTTL: cacheTTL)
        InstanceStore.instances[key] = newInstance
    }

    required init(cacheTTL: TimeInterval = 31536000) {
        self.cacheTTL = cacheTTL
    }

    func get() throws -> T {
        guard let value = storedValue else {
            print("🧠 ❌ Empty \(String(describing: type(of: self)))")
            throw MemoryDataSourceError.notInitialized
        }
        if isExpired() {
        print("🧠 ❌ Expired \(String(describing: type(of: self)))")
            clear()
            throw MemoryDataSourceError.expired
        }
        print("🧠 ✅ Fetching - \(String(describing: type(of: self))) [\(self.getTime())]")
        return value
    }

    func save(value: T) {
        self.timestamp = Date.now
        self.storedValue = value
        print("🧠 💾 Saving - \(String(describing: type(of: self))) [\(Int(self.cacheTTL))s]")
    }

    func clear() {
        self.timestamp = nil
        self.storedValue = nil
    }

    private func isExpired() -> Bool {
        guard let timestamp else { return true }
        return Date().timeIntervalSince(timestamp) > cacheTTL
    }

    private func getTime() -> String {
        guard let timestamp else { return "" }
        return timeIntervalFormatted(from: timestamp)
    }

    private func timeIntervalFormatted(from timestamp: Date) -> String {
        let totalSeconds = Date().timeIntervalSince(timestamp)
        let remainingSeconds = cacheTTL - totalSeconds

        if remainingSeconds >= 86400 {
            let hours = Int(remainingSeconds) / 3600
            return "+ \(hours)h"
        } else if remainingSeconds >= 3600 {
            let hours = Int(remainingSeconds) / 3600
            return "\(hours)h"
        } else if remainingSeconds >= 60 {
            let minutes = Int(remainingSeconds) / 60
            return "\(minutes)m"
        } else {
            let seconds = Int(remainingSeconds)
            return "\(seconds)s"
        }
    }
}
