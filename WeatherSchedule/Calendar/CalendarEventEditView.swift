#if canImport(EventKitUI) && canImport(UIKit)
import EventKit
import EventKitUI
import SwiftUI
import UIKit

struct CalendarEventEditView: UIViewControllerRepresentable {
    var date: Date
    
    private let eventStore = EKEventStore()
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let event = EKEvent(eventStore: eventStore)
        event.title = "予定"
        event.startDate = defaultStartDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: event.startDate) ?? event.startDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private var defaultStartDate: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }
    
    final class Coordinator: NSObject, EKEventEditViewDelegate {
        private let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            dismiss()
        }
    }
}
#else
import SwiftUI

struct CalendarEventEditView: View {
    var date: Date
    
    var body: some View {
        ContentUnavailableView(
            "予定を追加できません",
            systemImage: "calendar.badge.exclamationmark",
            description: Text("このプラットフォームではカレンダーの編集UIを利用できません。")
        )
    }
}
#endif
