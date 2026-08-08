import SwiftUI

/// Salidas del perfil hacia otros módulos.
///
/// Existe para que `ProfileView` no reciba el `AppComponentProtocol`. Antes el
/// builder le pasaba el contenedor entero a la vista y era ella quien construía
/// `AIChatBuilder`, `WeightProgressBuilder` y `UserReportBuilder` en su cuerpo:
/// la única pantalla de la app que se saltaba MVVM + Router + Builder, y de paso
/// la única cuyo `body` conocía el grafo de dependencias completo.
///
/// Las sub-páginas del propio perfil (editar datos, sincronización) siguen siendo
/// `NavigationLink` en la vista: comparten el mismo `ProfileViewModel` y no
/// necesitan construir nada, así que no tienen por qué pasar por aquí.
/// Las salidas, como protocolo, para que `ProfileViewModel` se pueda construir en
/// un test sin un `AppComponentProtocol` entero detrás.
protocol ProfileRouterProtocol {
    func goToChat()
    func goToWeightProgress()
    func goToUserReport()
}

class ProfileRouter: ProfileRouterProtocol {
    private let navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToChat() {
        navigator.push(to: AIChatBuilder(component: component).build())
    }

    func goToWeightProgress() {
        navigator.push(to: WeightProgressBuilder(component: component).build())
    }

    func goToUserReport() {
        navigator.push(to: UserReportBuilder(component: component).build())
    }
}
