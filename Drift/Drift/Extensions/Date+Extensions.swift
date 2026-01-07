//
//  Date+Extensions.swift
//  Drift
//
//  Date utilities and extensions
//

import Foundation

extension Date {
    /// Returns a relative time string (e.g., "2 hours ago", "Yesterday")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns true if the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if the date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Returns true if the date is within the last week
    var isWithinLastWeek: Bool {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return false
        }
        return self > weekAgo
    }
    
    /// Smart formatted string based on recency
    var smartFormatted: String {
        if isToday {
            return formatted(date: .omitted, time: .shortened)
        } else if isYesterday {
            return "Yesterday"
        } else if isWithinLastWeek {
            return formatted(.dateTime.weekday(.wide))
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }
}
