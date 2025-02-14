import SwiftUI


struct TrackingDayView: View {
    @ObservedObject var viewModel: TrackingDayViewModel

    var body: some View {
        ScrollView {
            DynamicGridView(columnCount: 7, rowCount: 4)
        }
    }
}

struct TrackingDayView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingDayBuilder().build()
    }
}
