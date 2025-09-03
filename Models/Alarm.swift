//
//  Alarm.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation

struct Alarm: Identifiable, Codable {
    let id: UUID
    var time: Date
    var label: String
    var repeatPattern: RepeatPattern?
    var isActive: Bool
    
    init(time: Date, label: String = "", repeatPattern: RepeatPattern? = nil, isActive: Bool = true) {
        self.id = UUID()
        self.time = time
        self.label = label
        self.repeatPattern = repeatPattern
        self.isActive = isActive
    }
}
