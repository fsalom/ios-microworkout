//
//  microworkoutUITests.swift
//  microworkoutUITests
//

import XCTest

/// Humo de arranque: la app abre y enseña una de sus dos pantallas iniciales.
///
/// La app decide en el init entre onboarding (primera vez) y el tab bar (resto),
/// y el simulador conserva UserDefaults entre ejecuciones, así que el test acepta
/// las dos en vez de suponer un estado limpio. Lo que caza es la regresión gorda:
/// un crash al arrancar o una raíz que no pinta nada.
final class microworkoutUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesToOnboardingOrHome() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        let onboarding = app.staticTexts["Bienvenido"]

        // La que llegue primero: tab bar (usuario con perfil) u onboarding.
        let deadline = Date().addingTimeInterval(15)
        var launched = false
        while Date() < deadline {
            if tabBar.exists || onboarding.exists { launched = true; break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTAssertTrue(launched, "ni el tab bar ni el onboarding aparecieron")

        // Si hay tab bar, las cinco pestañas deben existir y Perfil debe abrir.
        if tabBar.exists {
            for name in ["Inicio", "Ejercicios", "Entrenos", "Comidas", "Perfil"] {
                XCTAssertTrue(tabBar.buttons[name].exists, "falta la pestaña \(name)")
            }
            tabBar.buttons["Perfil"].tap()
            XCTAssertTrue(
                app.staticTexts["Perfil"].waitForExistence(timeout: 5)
                    || app.staticTexts["PERFIL"].waitForExistence(timeout: 2),
                "la pestaña Perfil no pintó su cabecera"
            )
        }
    }
}
