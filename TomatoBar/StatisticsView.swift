// ABOUTME: Statistics view showing work session graphs using SwiftUI Charts
// ABOUTME: Displays hourly, daily, weekly, and monthly work time visualizations

import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var selectedTab = 0
    @State private var sessions: [WorkSession] = []
    private let parser = LogParser()
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Time Period", selection: $selectedTab) {
                Text("Today").tag(0)
                Text("Daily").tag(1)
                Text("Weekly").tag(2)
                Text("Monthly").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Group {
                switch selectedTab {
                case 0:
                    HourlyView(sessions: sessions)
                case 1:
                    DailyView(sessions: sessions)
                case 2:
                    WeeklyView(sessions: sessions)
                case 3:
                    MonthlyView(sessions: sessions)
                default:
                    HourlyView(sessions: sessions)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .frame(width: 600, height: 400)
        .onAppear {
            sessions = parser.parseWorkSessions()
        }
    }
}

struct HourlyView: View {
    let sessions: [WorkSession]
    
    var hourlyData: [(hour: Int, minutes: Double)] {
        let parser = LogParser()
        let data = parser.groupSessionsByHour(sessions: sessions, for: Date())
        return (0...23).map { hour in
            (hour, (data[hour] ?? 0) / 60.0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Today's Work Hours")
                .font(.title2)
                .padding(.horizontal)
            
            Chart(hourlyData, id: \.hour) { item in
                BarMark(
                    x: .value("Hour", "\(item.hour):00"),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("Minutes")
            .padding()
            
            HStack {
                Text("Total: \(String(format: "%.1f", hourlyData.reduce(0) { $0 + $1.minutes } / 60)) hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

struct DailyView: View {
    let sessions: [WorkSession]
    
    var dailyData: [(date: Date, hours: Double)] {
        let parser = LogParser()
        return parser.groupSessionsByDay(sessions: sessions, days: 30).map {
            ($0.date, $0.duration / 3600.0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Daily Work Hours (Last 30 Days)")
                .font(.title2)
                .padding(.horizontal)
            
            Chart(dailyData, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("Hours")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .padding()
            
            HStack {
                Text("Average: \(String(format: "%.1f", dailyData.reduce(0) { $0 + $1.hours } / Double(dailyData.count))) hours/day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

struct WeeklyView: View {
    let sessions: [WorkSession]
    
    var weeklyData: [(weekStart: Date, hours: Double)] {
        let parser = LogParser()
        return parser.groupSessionsByWeek(sessions: sessions, weeks: 12).map {
            ($0.weekStart, $0.duration / 3600.0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Work Hours (Last 12 Weeks)")
                .font(.title2)
                .padding(.horizontal)
            
            Chart(weeklyData, id: \.weekStart) { item in
                BarMark(
                    x: .value("Week", item.weekStart, unit: .weekOfYear),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("Hours")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .padding()
            
            HStack {
                Text("Average: \(String(format: "%.1f", weeklyData.reduce(0) { $0 + $1.hours } / Double(max(weeklyData.count, 1)))) hours/week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

struct MonthlyView: View {
    let sessions: [WorkSession]
    
    var monthlyData: [(monthStart: Date, hours: Double)] {
        let parser = LogParser()
        return parser.groupSessionsByMonth(sessions: sessions, months: 12).map {
            ($0.monthStart, $0.duration / 3600.0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Work Hours (Last 12 Months)")
                .font(.title2)
                .padding(.horizontal)
            
            Chart(monthlyData, id: \.monthStart) { item in
                BarMark(
                    x: .value("Month", item.monthStart, unit: .month),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("Hours")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .padding()
            
            HStack {
                Text("Average: \(String(format: "%.1f", monthlyData.reduce(0) { $0 + $1.hours } / Double(max(monthlyData.count, 1)))) hours/month")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}