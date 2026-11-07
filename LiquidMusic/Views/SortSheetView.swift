import SwiftUI

public struct SortSheetView: View {
    @Binding public var currentOrder: SortOrder
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            List {
                ForEach(SortOrder.allCases) { order in
                    Button {
                        currentOrder = order
                        LibraryStore.shared.updateSettings { $0.sortOrder = order }
                        Task {
                            await LibraryStore.shared.rescanLibrary()
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Text(order.title)
                                .font(.system(size: 16, weight: order == currentOrder ? .semibold : .regular))
                                .foregroundColor(order == currentOrder ? palette.accent : palette.text)
                            
                            Spacer()
                            
                            if order == currentOrder {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(palette.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(palette.accent)
                }
            }
        }
    }
}
