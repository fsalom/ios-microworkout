import SwiftUI

struct AppleWatchWorkoutCard: View {
    let workout: HealthWorkout

    private var isLinked: Bool {
        workout.linkedTrainingID != nil || workout.linkedEntryDate != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            if let parts = workout.dateParts {
                DateBadge(day: parts.day, monthName: parts.monthName)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .foregroundColor(.green)
                    Text(workout.activityTypeName)
                        .fontWeight(.bold)
                    if isLinked {
                        LinkedTag()
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
                .stroke(isLinked ? Color.green.opacity(0.55) : Color.green.opacity(0.25),
                        lineWidth: isLinked ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LinkedTag: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "link")
                .font(.system(size: 9, weight: .bold))
            Text("Vinculado")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.green)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.green.opacity(0.15))
        .clipShape(Capsule())
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
