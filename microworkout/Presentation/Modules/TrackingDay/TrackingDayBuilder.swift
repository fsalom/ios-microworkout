
class TrackingDayBuilder {
    func build() -> TrackingDayView {
        let viewModel = TrackingDayViewModel()
        return TrackingDayView(viewModel: viewModel)
    }
}
