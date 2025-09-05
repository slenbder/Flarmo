//
//  Color+Id.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import SwiftUI

extension Color {
    init(_ colorId: Int) {
        // Простая палитра по индексам. Подставьте свою.
        let palette: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .teal, .indigo, .brown, .gray]
        self = palette[abs(colorId) % palette.count]
    }
}
