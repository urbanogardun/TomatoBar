// ABOUTME: Parses TomatoBar.log file to extract work session data
// ABOUTME: Converts state transitions into work session durations for statistics

import Foundation

struct WorkSession {
    let startTime: Date
    let endTime: Date
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}

struct LogEntry: Decodable {
    let type: String
    let timestamp: Double
    let event: String?
    let fromState: String?
    let toState: String?
}

class LogParser {
    private let logURL: URL
    
    init() {
        self.logURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("TomatoBar")
            .appendingPathComponent("TomatoBar.log")
    }
    
    func parseWorkSessions() -> [WorkSession] {
        guard let logData = try? String(contentsOf: logURL) else {
            return []
        }
        
        let lines = logData.components(separatedBy: .newlines)
        let decoder = JSONDecoder()
        var entries: [LogEntry] = []
        
        for line in lines where !line.isEmpty {
            if let data = line.data(using: .utf8),
               let entry = try? decoder.decode(LogEntry.self, from: data) {
                entries.append(entry)
            }
        }
        
        var sessions: [WorkSession] = []
        var workStartTime: Date?
        
        for entry in entries {
            guard entry.type == "transition" else { continue }
            
            let timestamp = Date(timeIntervalSince1970: entry.timestamp)
            
            if entry.toState == "work" {
                workStartTime = timestamp
            } else if entry.fromState == "work" && workStartTime != nil {
                sessions.append(WorkSession(startTime: workStartTime!, endTime: timestamp))
                workStartTime = nil
            }
        }
        
        return sessions
    }
    
    func groupSessionsByHour(sessions: [WorkSession], for date: Date) -> [Int: TimeInterval] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let todaySessions = sessions.filter { session in
            session.startTime >= startOfDay && session.startTime < endOfDay
        }
        
        var hourlyData: [Int: TimeInterval] = [:]
        
        for session in todaySessions {
            let hour = calendar.component(.hour, from: session.startTime)
            hourlyData[hour, default: 0] += session.duration
        }
        
        return hourlyData
    }
    
    func groupSessionsByDay(sessions: [WorkSession], days: Int) -> [(date: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let relevantSessions = sessions.filter { session in
            session.startTime >= startDate && session.startTime <= Date()
        }
        
        var dailyData: [Date: TimeInterval] = [:]
        
        for session in relevantSessions {
            let day = calendar.startOfDay(for: session.startTime)
            dailyData[day, default: 0] += session.duration
        }
        
        var result: [(Date, TimeInterval)] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            result.append((currentDate, dailyData[currentDate] ?? 0))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
    
    func groupSessionsByWeek(sessions: [WorkSession], weeks: Int) -> [(weekStart: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: endDate)!
        
        let relevantSessions = sessions.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
        
        var weeklyData: [Date: TimeInterval] = [:]
        
        for session in relevantSessions {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.startTime)!.start
            weeklyData[weekStart, default: 0] += session.duration
        }
        
        return weeklyData.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    
    func groupSessionsByMonth(sessions: [WorkSession], months: Int) -> [(monthStart: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -months, to: endDate)!
        
        let relevantSessions = sessions.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
        
        var monthlyData: [Date: TimeInterval] = [:]
        
        for session in relevantSessions {
            let monthStart = calendar.dateInterval(of: .month, for: session.startTime)!.start
            monthlyData[monthStart, default: 0] += session.duration
        }
        
        return monthlyData.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}