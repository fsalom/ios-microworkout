//
//  ExerciseTabView.swift
//  microworkout
//

import SwiftUI

struct ExerciseTabView: View {
    @StateObject var viewModel: ExerciseTabViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        scrollContent
            .pinnedTabHeader(subtitle: "AGENDA", title: "Ejercicio")
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                CalendarSection(
                    weeks: $viewModel.uiState.weeks,
                    selectedDate: viewModel.uiState.selectedDay.date,
                    onSelectDay: { viewModel.selectDay($0) }
                )
                .padding(.horizontal, 16)

                SelectedDayCard(day: viewModel.uiState.selectedDay)
                    .padding(.horizontal, 16)

                CoachInsightCard(
                    insight: viewModel.uiState.coachInsight,
                    isLoading: viewModel.uiState.isLoadingCoach,
                    onOpenChat: { prompt in viewModel.goToChat(prompt: prompt) }
                )
                .padding(.horizontal, 16)

                DayWorkoutsSection(
                    items: viewModel.workoutsForSelectedDay,
                    onTapEntry: { viewModel.goTo(entryDay: $0) },
                    onTapWorkout: { viewModel.goTo(workout: $0) },
                    onTapLinked: { entry, watch in viewModel.goToLinked(entry: entry, watch: watch) },
                    onTapLog: { viewModel.goTo(log: $0) },
                    onTapLinkedLog: { log, _ in viewModel.goTo(log: log) }
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        .onAppear {
            // Load on every appear (first time, after navigation pop, etc.) so
            // newly linked workouts or fresh Apple Watch data show up immediately.
            viewModel.load()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.load()
            }
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            // ExerciseTab is index 1; refresh when the user comes back to it.
            if newTab == 1 {
                viewModel.load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            viewModel.load()
        }
    }
}

// MARK: - Header

// MARK: - Calendar Section

private struct CalendarSection: View {
    @Binding var weeks: [[HealthDay]]
    var selectedDate: Date? = nil
    let onSelectDay: (HealthDay) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progresión")
                .font(.title2)
                .fontWeight(.bold)
            HealthWeeksView(
                weeks: $weeks,
                selectedDate: selectedDate
            ) { day in
                onSelectDay(day)
            }
        }
    }
}

// MARK: - Selected Day Card

private struct SelectedDayCard: View {
    let day: HealthDay

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(0.5)

            HStack(spacing: 12) {
                StatBlock(value: formatNumber(day.steps), label: "Pasos")
                StatBlock(value: "\(day.minutesOfExercise)", label: "Min. ejercicio")
                StatBlock(value: "\(day.minutesStanding)", label: "Min. de pie")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(day.date) { return "HOY" }
        if cal.isDateInYesterday(day.date) { return "AYER" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: day.date).uppercased()
    }

    private func formatNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Day Workouts Section

private struct DayWorkoutsSection: View {
    let items: [DisplayWorkoutItem]
    let onTapEntry: (WorkoutEntryByDay) -> Void
    let onTapWorkout: (HealthWorkout) -> Void
    let onTapLinked: (WorkoutEntryByDay, HealthWorkout) -> Void
    let onTapLog: (WorkoutLog) -> Void
    let onTapLinkedLog: (WorkoutLog, HealthWorkout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entrenamientos del día")
                .font(.title2)
                .fontWeight(.bold)

            if items.isEmpty {
                EmptyDayState()
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        WorkoutItemRow(
                            item: item,
                            onTapEntry: onTapEntry,
                            onTapWorkout: onTapWorkout,
                            onTapLinked: onTapLinked,
                            onTapLog: onTapLog,
                            onTapLinkedLog: onTapLinkedLog
                        )
                    }
                }
            }
        }
    }
}

private struct EmptyDayState: View {
    var body: some View {
        Text("Sin entrenamientos este día")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

private struct WorkoutItemRow: View {
    let item: DisplayWorkoutItem
    let onTapEntry: (WorkoutEntryByDay) -> Void
    let onTapWorkout: (HealthWorkout) -> Void
    let onTapLinked: (WorkoutEntryByDay, HealthWorkout) -> Void
    let onTapLog: (WorkoutLog) -> Void
    let onTapLinkedLog: (WorkoutLog, HealthWorkout) -> Void

    var body: some View {
        switch item {
        case .manual(let entry):
            ManualEntryCard(entry: entry)
                .onTapGesture { onTapEntry(entry) }
        case .appleWatch(let workout):
            AppleWatchWorkoutCard(workout: workout)
                .onTapGesture { onTapWorkout(workout) }
        case .linked(let entry, let watch):
            LinkedWorkoutCard(
                entry: entry,
                watch: watch,
                onTap: { onTapLinked(entry, watch) }
            )
        case .log(let log):
            WorkoutLogCard(log: log)
                .onTapGesture { onTapLog(log) }
        case .linkedLog(let log, let watch):
            LinkedLogCard(
                log: log,
                watch: watch,
                onTap: { onTapLinkedLog(log, watch) }
            )
        }
    }
}

// MARK: - WorkoutLog cards

private struct WorkoutLogCard: View {
    let log: WorkoutLog

    var body: some View {
        HStack(spacing: 10) {
            if let parts = dateParts {
                DateBadge(day: parts.day, monthName: parts.monthName)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                    Text(log.sessionName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                Text("\(log.exercises.count) ej. · \(log.totalSets) series" + (log.endedAt != nil ? " · \(log.durationFormatted)" : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dateParts: DateParts? {
        let cal = Calendar(identifier: .gregorian)
        let day = cal.component(.day, from: log.startedAt)
        let month = cal.component(.month, from: log.startedAt)
        let year = cal.component(.year, from: log.startedAt)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let monthName = formatter.monthSymbols[month - 1]
        return DateParts(day: day, month: month, year: year, monthName: monthName)
    }
}

private struct LinkedLogCard: View {
    let log: WorkoutLog
    let watch: HealthWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                if let parts = watch.dateParts {
                    DateBadge(day: parts.day, monthName: parts.monthName)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 28, height: 28)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(watch.activityTypeName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(watch.timeRangeFormatted) · \(watch.durationFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                        Text("Vinculado")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                            .tracking(0.5)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.sessionName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text("\(log.exercises.count) ej. · \(log.totalSets) series")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.45), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Linked card

private struct LinkedWorkoutCard: View {
    let entry: WorkoutEntryByDay
    let watch: HealthWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                if let parts = watch.dateParts {
                    DateBadge(day: parts.day, monthName: parts.monthName)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(watch.activityTypeName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("\(watch.timeRangeFormatted) · \(watch.durationFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                        HStack(spacing: 6) {
                            if let cal = watch.caloriesFormatted {
                                MiniChip(text: cal, icon: "flame.fill", color: .orange)
                            }
                            if let hr = watch.heartRateFormatted {
                                MiniChip(text: hr, icon: "heart.fill", color: .red)
                            }
                        }
                    }
                    .padding(.vertical, 10)

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                        Text("Vinculado")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                            .tracking(0.5)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.exercisesFormatted)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("\(entry.totalSeriesFormatted) · \(entry.durationFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.45), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct MiniChip: View {
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

private struct ManualEntryCard: View {
    let entry: WorkoutEntryByDay

    var body: some View {
        HStack(spacing: 10) {
            if let parts = entry.dateParts {
                DateBadge(day: parts.day, monthName: parts.monthName)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                    Text(entry.exercisesFormatted)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                Text("\(entry.totalSeriesFormatted) · \(entry.durationFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

