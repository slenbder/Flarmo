//
//  NotificationDebug.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/9/25.
//

import UserNotifications

enum NotificationDebug {
    static func dumpPendingIDs() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs.map(\.identifier).sorted()
            print("[Pending] \(ids.count) → \(ids.joined(separator: ", "))")
        }
    }
}
