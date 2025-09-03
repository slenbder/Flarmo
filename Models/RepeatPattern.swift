//
//  RepeatPattern.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation

enum RepeatPattern: Codable {
    case none
    case daily
    case weekly([Int]) // дни недели, 1 = воскресенье, 7 = суббота
    case custom([Date]) // произвольные даты
    
    // Можно добавить функции для расчёта следующих срабатываний
}
