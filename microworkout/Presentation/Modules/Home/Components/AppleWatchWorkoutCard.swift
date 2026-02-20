import SwiftUI

struct AppleWatchWorkoutCard: View {
    let workout: HealthWorkout

    var body: some View {
        HStack(spacing: 10) {
            if let parts = workout.dateParts {
                DateBadge(day: parts.day, monthName: parts.monthName)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "applewatch")
                        .foregroundColor(.green)
                    Text(workout.activityTypeName)
                        .fontWeight(.bold)
                    if workout.linkedTrainingID != nil {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Text(workout.durationFormatted)
                    .font(.subheadline)

                HStack(spacing: 8) {
                    if let cal = workout.caloriesFormatted {
                        ChipView(text: cal, icon: "flame.fill", color: .orange)
                    }
                    if let dist = workout.distanceFormatted {
                        ChipView(text: dist, icon: "figure.run", color: .blue)
                    }
                    if let hr = workout.heartRateFormatted {
                        ChipView(text: hr, icon: "heart.fill", color: .red)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ChipView: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}
