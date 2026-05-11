import SwiftUI

struct SetMediaThumbnail: View {
    let media: SetMedia
    let imageURL: URL?

    var body: some View {
        ZStack {
            if let url = imageURL, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: media.type == .video ? "video" : "photo")
                            .foregroundColor(.gray)
                    )
            }

            if media.type == .video {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                        if let duration = media.durationSeconds {
                            Text(format(duration: duration))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(4)
                    .background(LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func format(duration: Double) -> String {
        let total = Int(duration.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
