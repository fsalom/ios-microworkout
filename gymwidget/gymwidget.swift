//
//  gymwidget.swift
//  gymwidget
//
//  Created by Fernando Salom Carratala on 7/2/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    var usecase: TrainingUseCase

    init() {
        let datasource: TrainingLocalDataSourceProtocol = TrainingLocalDataSource(localStorage: UserDefaultsManager())
        let repository: TrainingRepositoryProtocol = TrainingRepository(local: datasource)
        self.usecase = TrainingUseCase(repository: repository)
    }

    func placeholder(in context: Context) -> TrainingEntry {
        guard let training = usecase.getCurrentTraining() else {
            return TrainingEntry.mock()
        }
        return TrainingEntry.from(entity: training)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrainingEntry) -> ()) {
        guard let training = usecase.getCurrentTraining() else {
            completion(TrainingEntry.mock())
            return
        }
        completion(TrainingEntry.from(entity: training))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TrainingEntry] = []
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct TrainingEntry: TimelineEntry {
    var date: Date
    var id: UUID = UUID()
    var name: String
    var image: String
    var type: TrainingType
    var startedAt: Date?
    var completedAt: Date?
    var sets: [Date] = []
    var numberOfSetsCompleted: Int = 0
    var numberOfSets: Int
    var numberOfReps: Int
    var numberOfMinutesPerSet: Int

    static func from(entity: Training) -> TrainingEntry {
        TrainingEntry(date: entity.sets.last ?? Date(),
                      name: entity.name,
                      image: entity.image,
                      type: entity.type,
                      numberOfSets: entity.numberOfSets,
                      numberOfReps: entity.numberOfReps,
                      numberOfMinutesPerSet: entity.numberOfMinutesPerSet)
    }

    static func mock() -> TrainingEntry {
        TrainingEntry(date: .now,
                      name: "",
                      image: "",
                      type: .cardio,
                      numberOfSets: 0,
                      numberOfReps: 0,
                      numberOfMinutesPerSet: 0)
    }
}

struct gymwidgetEntryView : View {
    var entry: Provider.Entry

    var countdownDate: Date {
        // Cuenta regresiva de 25 minutos
        Calendar.current.date(byAdding: .minute, value: 25, to: entry.date) ?? entry.date
    }

    var body: some View {
        VStack(alignment: .center){
            if entry.sets.isEmpty {
                Text("Ningún entrenamiento en marcha")
                    .font(.footnote)
                    .padding()
                    .foregroundStyle(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                    )
            } else {
                Text("Entrenamiento en marcha")
                    .font(.footnote)
                    .padding()
                    .foregroundStyle(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                    )
                Text("Completa 10 flexiones en los próximos 25 minutos")
                    .font(.footnote)
                    .foregroundStyle(.white)
                Text(countdownDate, style: .timer)
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(alignment: .center)
            }
        }
    }
}

struct gymwidget: Widget {
    let kind: String = "gymwidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                gymwidgetEntryView(entry: entry)
                    .containerBackground(.blue, for: .widget)
            } else {
                gymwidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    gymwidget()
} timeline: {
    TrainingEntry(date: Date(),
                  name: "dto.name",
                  image: "dto.image",
                  type: .cardio,
                  numberOfSets: 0,
                  numberOfReps: 0,
                  numberOfMinutesPerSet: 0)
}
