import SwiftUI

struct DynamicGridView: View {
    @State var columnCount: Int
    @State var rowCount: Int
    @State private var selection: Int = 0

    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .gray, .cyan]

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)
    }

    var body: some View {
        VStack {
            Picker("", selection: $selection) {
                Text("Semanal").tag(0)
                Text("Quincenal").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: selection) { newValue, oldValue in
                switch newValue {
                case 0:
                    columnCount = 7
                    rowCount = 4
                default:
                    columnCount = 14
                    rowCount = 4
                }
            }

            LazyVGrid(columns: gridItems, spacing: 5) {
                ForEach(0..<(columnCount * rowCount), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(colors[index % colors.count])
                        .frame(height: 20)
                }
            }
        }
        .animation(.default, value: columnCount)
        .animation(.default, value: rowCount)
    }
}
