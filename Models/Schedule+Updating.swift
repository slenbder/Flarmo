//
//  Schedule+Updating.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

extension Schedule {
    func updating(name: String? = nil,
                  colorId: Int? = nil,
                  type: ScheduleType? = nil,
                  isActive: Bool? = nil) -> Schedule {
        Schedule(
            id: id,
            name: name ?? self.name,
            colorId: colorId ?? self.colorId,
            toneId: toneId,
            type: type ?? self.type,
            isActive: isActive ?? self.isActive
        )
    }
}
