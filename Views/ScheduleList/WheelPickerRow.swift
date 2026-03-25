//
//  WheelPickerRow.swift
//  Flarmo
//

import SwiftUI

struct WheelPickerRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var isPresented = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value) д.")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { isPresented = true }
        .sheet(isPresented: $isPresented) {
            Picker(label, selection: $value) {
                ForEach(range, id: \.self) { n in
                    Text("\(n) д.").tag(n)
                }
            }
            .pickerStyle(.wheel)
            .presentationDetents([.height(220)])
        }
    }
}
