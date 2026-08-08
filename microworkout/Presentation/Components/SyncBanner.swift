import SwiftUI

/// Contador de categorías ya empezadas, compartido entre el hilo desde el que el
/// caso de uso avisa del progreso y el main actor que pinta el banner.
///
/// Es una clase con cerrojo y no un `var` capturado porque los dos extremos viven
/// en dominios de aislamiento distintos: mutar desde fuera un `var` de un contexto
/// `@MainActor` es una carrera aunque hoy no se note, y con concurrencia estricta
/// ni siquiera compila.
private final class SyncProgressCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    /// Devuelve cuántas categorías se habían completado ANTES de esta, que es lo
    /// que el banner necesita para decir "N de M".
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let current = value
        value += 1
        return current
    }
}

/// Estado de la subida automática que se lanza al iniciar sesión.
///
/// Vive fuera de cualquier pantalla, como `MediaProcessingTracker`: la
/// sincronización arranca al autenticarse y debe seguir (y seguir contándose)
/// aunque el usuario navegue a otra pestaña o cierre la de perfil.
@MainActor
final class SyncTracker: ObservableObject {
    static let shared = SyncTracker()

    enum Phase: Equatable {
        case idle
        /// Subiendo una categoría concreta; `done`/`total` para el progreso.
        case syncing(category: SyncCategory, done: Int, total: Int)
        /// Terminada: se muestra un instante y se oculta sola.
        case finished(uploaded: Int, hasErrors: Bool)
    }

    @Published private(set) var phase: Phase = .idle

    private var task: Task<Void, Never>?

    /// Cuánto se queda visible el resultado antes de esconderse solo.
    ///
    /// Es un parámetro y no una constante porque, si no, un test que compruebe el
    /// estado "terminada" compite contra un reloj de pared: en una máquina cargada
    /// el banner se esconde antes de que llegue la comprobación y el test falla sin
    /// que nada esté roto.
    private let visibleAfterFinish: Duration

    init(visibleAfterFinish: Duration = .seconds(3.5)) {
        self.visibleAfterFinish = visibleAfterFinish
    }

    var isVisible: Bool { phase != .idle }

    /// Lanza la subida si no hay otra en curso. Idempotente: dos logins seguidos
    /// (o dos observadores del mismo cambio de estado) no disparan dos subidas.
    func syncAfterLogin(using useCase: SyncLocalDataUseCaseProtocol) {
        guard task == nil else { return }

        let total = SyncCategory.allCases.count
        phase = .syncing(category: SyncCategory.allCases[0], done: 0, total: total)

        task = Task { [weak self] in
            // El progreso se lleva en un contador propio y no en una variable
            // capturada: el caso de uso llama a `progress` desde el hilo que le toca
            // (lo dice su contrato), así que un `var` de este `Task` —que está
            // aislado al main actor— se estaría mutando desde fuera. Y al leerlo
            // dentro del salto al main actor se leía YA incrementado, de ahí que el
            // banner enseñara siempre una categoría de más ("2 de 6" en la primera).
            let counter = SyncProgressCounter()
            let report = await useCase.sync(progress: { category in
                let done = counter.next()
                Task { @MainActor [weak self] in
                    self?.phase = .syncing(category: category, done: done, total: total)
                }
            })

            guard let self else { return }
            self.phase = .finished(
                uploaded: report.totalUploaded,
                hasErrors: report.hasErrors
            )
            self.task = nil

            // El resultado se deja visible lo justo para poder leerlo: un banner
            // que no se va solo obliga al usuario a echarlo, y esto es informativo.
            try? await Task.sleep(for: self.visibleAfterFinish)
            if case .finished = self.phase { self.phase = .idle }
        }
    }
}

/// Banner superior que informa de la sincronización tras iniciar sesión.
///
/// Va arriba y sin capturar toques: no debe estorbar a lo que el usuario esté
/// haciendo mientras sus datos suben en segundo plano.
struct SyncBanner: View {
    @ObservedObject private var tracker = SyncTracker.shared

    var body: some View {
        VStack {
            if tracker.isVisible {
                content
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.black.opacity(0.88))
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: tracker.phase)
    }

    @ViewBuilder
    private var content: some View {
        switch tracker.phase {
        case .idle:
            EmptyView()

        case .syncing(let category, let done, let total):
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Sincronizando \(category.title.lowercased())…")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("\(min(done + 1, total)) de \(total)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

        case .finished(let uploaded, let hasErrors):
            HStack(spacing: 10) {
                Image(systemName: hasErrors ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(hasErrors ? .orange : .green)
                Text(Self.summary(uploaded: uploaded, hasErrors: hasErrors))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }

    private static func summary(uploaded: Int, hasErrors: Bool) -> String {
        if hasErrors {
            return uploaded > 0
                ? "Subidos \(uploaded); algo quedó pendiente"
                : "No se pudo sincronizar todo"
        }
        if uploaded == 0 { return "Todo estaba ya sincronizado" }
        return uploaded == 1 ? "1 elemento sincronizado" : "\(uploaded) elementos sincronizados"
    }
}
