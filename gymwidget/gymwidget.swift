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
        let datasource: TrainingLocalDataSourceProtocol = TrainingLocalDataSource()
        let repository: TrainingRepositoryProtocol = TrainingRepository(local: datasource)
        self.usecase = TrainingUseCase(repository: repository)
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct gymwidgetEntryView : View {
    var entry: Provider.Entry

    var countdownDate: Date {
           // Cuenta regresiva de 25 minutos
           Calendar.current.date(byAdding: .minute, value: 25, to: entry.date) ?? entry.date
       }

    var body: some View {
        VStack(alignment: .center){
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
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
