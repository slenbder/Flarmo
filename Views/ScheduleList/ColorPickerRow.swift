//
//  ColorPickerRow.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import SwiftUI

struct ColorPickerRow: View {
    @Binding var selectedId: Int
    private let ids = Array(0..<10)

    var body: some View {
        HStack {
            Text("Цвет")
            Spacer()
            HStack(spacing: 8) {
                ForEach(ids, id: \.self) { id in
                    Circle()
                        .fill(Color(id))
                        .frame(width: 22, height: 22)
                        .overlay {
                            if id == selectedId {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture { selectedId = id }
                }
            }
        }
    }
}
