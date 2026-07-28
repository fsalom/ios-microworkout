import SwiftUI
import AuthenticationServices

// MARK: - Profile hub (pantalla inicial)

/// Pantalla inicial del perfil: información básica de un vistazo + navegación a
/// las secciones (editar datos, sincronización, salud, IA, apariencia). El
/// contenido pesado (formulario y panel de sincronización) vive en sub-páginas
/// que se abren con push y comparten el mismo `ProfileViewModel`.
struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @EnvironmentObject var authSession: AuthSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance_preference") private var appearanceRaw: String = AppearancePreference.system.rawValue
    let component: AppComponentProtocol

    @State private var toastText: String?
    @State private var toastIsError = false
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        hubView
        .pinnedTabHeader(subtitle: "AJUSTES", title: "Perfil")
        .background(Color(.systemGroupedBackground))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { viewModel.loadHealthKitStatus() }
        }
        .onChange(of: authSession.state) { _, newState in
            // Al iniciar o cerrar sesión, recarga el perfil (servidor⇄local) y,
            // si hay sesión, el estado de sincronización — así el hub refleja los
            // datos correctos sin reiniciar la app.
            viewModel.loadProfile()
            if newState.isAuthenticated { viewModel.loadSyncStatus() }
        }
        // Feedback como toast (no como alert): un toast es una vista en la jerarquía,
        // así que se muestra de forma fiable aunque el VC de Google/Apple se esté
        // cerrando (un .alert no llega a presentarse en ese instante).
        .overlay(alignment: .bottom) {
            if let toastText {
                AuthToastBanner(message: toastText, isError: toastIsError)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toastText)
        .onChange(of: viewModel.uiState.authError) { _, err in
            if let err { showAuthToast(err, isError: true); viewModel.dismissAuthError() }
        }
        .onChange(of: viewModel.uiState.authSuccessMessage) { _, msg in
            if let msg { showAuthToast(msg, isError: false); viewModel.dismissAuthSuccess() }
        }
    }

    // MARK: Hub

    private var hubView: some View {
        List {
            profileHeaderSection

            accountSection

            Section("Ajustes") {
                NavigationLink {
                    ProfileEditView(viewModel: viewModel)
                } label: {
                    hubRowLabel(icon: "square.and.pencil", title: "Editar datos y objetivos")
                }

                if authSession.state.isAuthenticated {
                    NavigationLink {
                        ProfileSyncView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: 12) {
                            hubRowLabel(icon: "arrow.triangle.2.circlepath", title: "Sincronización")
                            if viewModel.uiState.syncReport.totalPending > 0 {
                                Text("\(viewModel.uiState.syncReport.totalPending)")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                            }
                        }
                    }
                }

                NavigationLink {
                    AIChatBuilder(component: component).build()
                } label: {
                    hubRowLabel(icon: "sparkles", title: "Asistente IA", iconColor: .purple)
                }
            }

            if viewModel.uiState.isHealthDataAvailable { healthSection }

            appearanceSection

            if authSession.state.isAuthenticated {
                Section {
                    Button(role: .destructive, action: { viewModel.signOut() }) {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .onAppear {
            // Carga el estado de sincronización una vez para poder mostrar el
            // badge de pendientes en la fila de "Sincronización".
            if authSession.state.isAuthenticated, !viewModel.uiState.hasLoadedSyncStatus {
                viewModel.loadSyncStatus()
            }
        }
    }

    /// Cabecera adaptativa: si hay perfil, tarjeta con datos + tiles; si no, un
    /// CTA para completarlo (editar SIEMPRE va detrás de un tap, nunca inline).
    @ViewBuilder
    private var profileHeaderSection: some View {
        if viewModel.uiState.hasProfile {
            Section { headerCard }
            Section { statTiles }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
        } else {
            Section {
                NavigationLink {
                    ProfileEditView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Completa tu perfil")
                                .font(.headline)
                            Text("Datos físicos y objetivos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.green)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.uiState.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Label("\(Int(viewModel.uiState.dailyCalorieTarget)) kcal/día objetivo", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var statTiles: some View {
        HStack(spacing: 12) {
            ProfileStatTile(icon: "scalemass", value: String(format: "%.0f", viewModel.uiState.weight), unit: "kg", label: "Peso")
            ProfileStatTile(icon: "ruler", value: String(format: "%.0f", viewModel.uiState.height), unit: "cm", label: "Altura")
            ProfileStatTile(icon: "calendar", value: "\(viewModel.uiState.age)", unit: "años", label: "Edad")
        }
    }

    private func hubRowLabel(icon: String, title: String, iconColor: Color = .green) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
        }
    }

    private var healthSection: some View {
        Section("Salud") {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(viewModel.uiState.healthKitStatus == .authorized ? .green : .secondary)
                    .frame(width: 24)
                Text("HealthKit")
                Spacer()
                switch viewModel.uiState.healthKitStatus {
                case .authorized:
                    Text("Activado").foregroundColor(.green)
                case .notDetermined:
                    Button("Activar") { viewModel.requestHealthKit() }.tint(.green)
                case .denied:
                    Button("Abrir Salud") { viewModel.openHealthApp() }.tint(.green)
                }
            }
            if viewModel.uiState.healthKitStatus == .denied {
                Text("Activa los permisos en Salud > Perfil > Apps y servicios > microworkout")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var appearanceSection: some View {
        Section("Apariencia") {
            Picker(selection: $appearanceRaw) {
                ForEach(AppearancePreference.allCases) { option in
                    Text(option.label).tag(option.rawValue)
                }
            } label: {
                hubRowLabel(icon: "moon.circle", title: "Modo")
            }
        }
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        switch authSession.state {
        case .unknown:
            EmptyView()
        case .guest:
            Section("Cuenta") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Inicia sesión para sincronizar tus datos en la nube y desbloquear el escáner de códigos y el coach IA.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        viewModel.handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 44)
                    .disabled(viewModel.uiState.isSigningIn)
                    .opacity(viewModel.uiState.isSigningIn ? 0.5 : 1)

                    #if canImport(GoogleSignIn)
                    Button {
                        viewModel.handleGoogleSignIn()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                            Text("Continuar con Google").fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundColor(.primary)
                        .background(Color(.secondarySystemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4)))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(viewModel.uiState.isSigningIn)
                    .opacity(viewModel.uiState.isSigningIn ? 0.5 : 1)
                    #endif
                }
                .padding(.vertical, 4)
            }
        case .authenticated(let user):
            Section("Cuenta") {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullname.isEmpty ? "Cuenta vinculada" : user.fullname)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Toast

    private func showAuthToast(_ text: String, isError: Bool) {
        toastTask?.cancel()
        toastText = text
        toastIsError = isError
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled { await MainActor.run { toastText = nil } }
        }
    }
}

// MARK: - Edit page (formulario)

/// Página de edición del perfil (datos físicos, actividad, objetivo, macros y
/// cycling). Se abre con push desde el hub y comparte el `ProfileViewModel`.
/// Cuando aún no hay perfil, `ProfileView` la muestra directamente como onboarding.
struct ProfileEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Nombre") {
                TextField("Tu nombre", text: $viewModel.uiState.name)
            }

            Section("Datos físicos") {
                Picker("Sexo", selection: $viewModel.uiState.gender) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(.segmented)

                Stepper("Edad: \(viewModel.uiState.age) años", value: $viewModel.uiState.age, in: 10...100)

                VStack(alignment: .leading) {
                    Text("Peso: \(String(format: "%.1f", viewModel.uiState.weight)) kg")
                    Slider(value: $viewModel.uiState.weight, in: 30...200, step: 0.5)
                }

                VStack(alignment: .leading) {
                    Text("Altura: \(String(format: "%.0f", viewModel.uiState.height)) cm")
                    Slider(value: $viewModel.uiState.height, in: 100...220, step: 1)
                }
            }

            Section("Nivel de actividad") {
                Picker("Actividad", selection: $viewModel.uiState.activityLevel) {
                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section("Objetivo físico") {
                Picker("Objetivo", selection: $viewModel.uiState.fitnessGoal) {
                    ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
            }

            Section("Perfil de macros") {
                Picker("Macros", selection: $viewModel.uiState.macroProfile) {
                    ForEach(UserProfile.MacroProfile.allCases, id: \.self) { profile in
                        Text(profile.rawValue).tag(profile)
                    }
                }
            }

            Section("Cycling semanal") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Días libres (max 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        ForEach(cyclingDayLabels, id: \.weekday) { item in
                            let isSelected = viewModel.uiState.freeDays.contains(item.weekday)
                            Button {
                                if isSelected {
                                    viewModel.uiState.freeDays.remove(item.weekday)
                                } else if viewModel.uiState.freeDays.count < 3 {
                                    viewModel.uiState.freeDays.insert(item.weekday)
                                }
                            } label: {
                                Text(item.label)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 36, height: 36)
                                    .background(isSelected ? Color.green.opacity(0.3) : Color(.systemGray5))
                                    .foregroundColor(isSelected ? .green : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !viewModel.uiState.freeDays.isEmpty {
                    Stepper("Extra: +\(Int(viewModel.uiState.freeDayExtraCalories)) kcal",
                            value: $viewModel.uiState.freeDayExtraCalories,
                            in: 200...1000,
                            step: 50)
                }
            }

            Section {
                ProfileActionButton(title: "Guardar", systemImage: "checkmark") {
                    viewModel.save()
                    dismiss()
                }

                if viewModel.uiState.hasProfile {
                    Button(action: { viewModel.cancelEditing(); dismiss() }) {
                        Text("Cancelar")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Editar perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sync page

/// Página de sincronización con la cuenta: estado por categoría (al día /
/// pendiente / error) y acción para subir lo que falta. La copia local nunca se
/// borra (modelo espejo), así que el dispositivo conserva siempre un respaldo.
struct ProfileSyncView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var bannerText: String?
    @State private var bannerIsError = false
    @State private var bannerTask: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                ForEach(viewModel.uiState.syncReport.statuses) { status in
                    HStack(spacing: 12) {
                        Image(systemName: status.category.icon)
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text(status.category.title)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        syncBadge(for: status)
                    }
                }
            } footer: {
                Text("La copia local se conserva siempre como respaldo en el dispositivo.")
            }

            Section {
                ProfileActionButton(title: syncButtonTitle, systemImage: "arrow.triangle.2.circlepath", isLoading: viewModel.uiState.isSyncing) {
                    viewModel.sync()
                }
            }
        }
        .navigationTitle("Sincronización")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let bannerText {
                AuthToastBanner(message: bannerText, isError: bannerIsError)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: bannerText)
        .onChange(of: viewModel.uiState.lastSyncMessage) { _, msg in
            guard let msg else { return }
            let report = viewModel.uiState.syncReport
            showBanner(msg, isError: report.hasErrors)
            viewModel.uiState.lastSyncMessage = nil   // consumido: permite re-disparar el mismo texto
        }
        .onAppear { viewModel.loadSyncStatus() }
    }

    /// Muestra un toast en la parte inferior y lo oculta solo tras unos segundos.
    private func showBanner(_ text: String, isError: Bool) {
        bannerTask?.cancel()
        bannerText = text
        bannerIsError = isError
        bannerTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if !Task.isCancelled { await MainActor.run { bannerText = nil } }
        }
    }

    private var syncButtonTitle: String {
        if viewModel.uiState.isSyncing { return "Sincronizando…" }
        let report = viewModel.uiState.syncReport
        if report.totalPending > 0 { return "Sincronizar (\(report.totalPending))" }
        if report.hasErrors { return "Reintentar" }
        if viewModel.uiState.hasLoadedSyncStatus { return "Sincronizar de nuevo" }
        return "Sincronizar"
    }

    /// Badge compacto (icono + texto corto, sin wrap) por categoría.
    @ViewBuilder
    private func syncBadge(for status: SyncCategoryStatus) -> some View {
        Group {
            if !viewModel.uiState.hasLoadedSyncStatus {
                ProgressView()
            } else if status.error != nil {
                Label("Error", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            } else if status.pending == 0 {
                Label("Al día", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Label("\(status.pending)", systemImage: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
        .labelStyle(.titleAndIcon)
        .fixedSize()
    }
}

// MARK: - Reusable pieces

private let cyclingDayLabels: [(weekday: Int, label: String)] = [
    (2, "L"), (3, "M"), (4, "X"), (5, "J"), (6, "V"), (7, "S"), (1, "D")
]

/// Botón de acción principal: relleno, ancho completo y legible tanto en claro
/// como en oscuro. Fuerza su propio `tint` para no depender del tint global.
struct ProfileActionButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = .green
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
        .disabled(isLoading)
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

/// Tarjeta compacta de estadística para la cabecera del perfil.
private struct ProfileStatTile: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title3).fontWeight(.bold)
                Text(unit).font(.caption2).foregroundColor(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

/// Banner de feedback (éxito verde / error rojo) para el inicio de sesión.
private struct AuthToastBanner: View {
    let message: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isError ? Color.red : Color.green)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ProfileBuilder(component: DefaultAppComponent.preview).build()
}
