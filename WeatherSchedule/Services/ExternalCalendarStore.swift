import Foundation
import Observation

#if canImport(EventKit)
import EventKit

struct ExternalCalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

@MainActor
@Observable
final class ExternalCalendarStore {
    enum AccessState: Equatable {
        case notRequested
        case requesting
        case granted
        case denied
        case unavailable
    }
    
    private(set) var accessState: AccessState = .notRequested
    private(set) var eventsByDate: [Date: [ExternalCalendarEvent]] = [:]
    
    private let eventStore = EKEventStore()
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
        updateAccessState()
    }
    
    func events(for date: Date) -> [ExternalCalendarEvent] {
        eventsByDate[calendar.startOfDay(for: date), default: []]
    }
    
    func refresh(months: [CalendarMonth]) async {
        guard await ensureFullAccess() else { return }
        guard let start = months.first?.firstDay, let lastMonth = months.last?.firstDay else { return }
        let end = calendar.date(byAdding: DateComponents(month: 1, day: 1), to: lastMonth) ?? lastMonth
        fetchEvents(start: start, end: end)
    }
    
    private func updateAccessState() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            switch status {
            case .fullAccess:
                accessState = .granted
            case .denied, .restricted, .writeOnly:
                accessState = .denied
            case .notDetermined:
                accessState = .notRequested
            @unknown default:
                accessState = .unavailable
            }
        } else {
            switch status {
            case .authorized:
                accessState = .granted
            case .denied, .restricted:
                accessState = .denied
            case .notDetermined:
                accessState = .notRequested
            @unknown default:
                accessState = .unavailable
            }
        }
    }
    
    private func ensureFullAccess() async -> Bool {
        updateAccessState()
        if accessState == .granted { return true }
        guard accessState == .notRequested else { return false }
        
        accessState = .requesting
        let granted: Bool
        do {
            if #available(iOS 17.0, *) {
                granted = try await requestFullAccessToEvents()
            } else {
                granted = try await requestLegacyAccessToEvents()
            }
        } catch {
            granted = false
        }
        
        accessState = granted ? .granted : .denied
        return granted
    }
    
    @available(iOS 17.0, *)
    private func requestFullAccessToEvents() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private func requestLegacyAccessToEvents() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private func fetchEvents(start: Date, end: Date) {
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let fetchedEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
        
        eventsByDate = Dictionary(grouping: fetchedEvents.map(makeCalendarEvent)) { event in
            calendar.startOfDay(for: event.startDate)
        }
    }
    
    private func makeCalendarEvent(from event: EKEvent) -> ExternalCalendarEvent {
        ExternalCalendarEvent(
            id: event.eventIdentifier ?? "\(event.startDate.timeIntervalSince1970)-\(event.title ?? "")",
            title: event.title?.isEmpty == false ? event.title : "予定",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay
        )
    }
}

#else

struct ExternalCalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

@MainActor
@Observable
final class ExternalCalendarStore {
    enum AccessState: Equatable {
        case notRequested
        case requesting
        case granted
        case denied
        case unavailable
    }
    
    private(set) var accessState: AccessState = .unavailable
    private(set) var eventsByDate: [Date: [ExternalCalendarEvent]] = [:]
    
    func events(for date: Date) -> [ExternalCalendarEvent] { [] }
    func refresh(months: [CalendarMonth]) async {}
}

#endif
