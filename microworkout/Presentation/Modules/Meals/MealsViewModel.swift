//
//  MealsViewModel.swift
//  microworkout
//

import Foundation
import SwiftUI

struct MealsUiState {
    var todayMeals: [Meal] = []
    var todayTotals: NutritionInfo = .zero
    var selectedDate: Date = .init()
    var dailyCalorieTarget: Double? = nil
    var macroTargets: NutritionInfo? = nil
    var isLoading: Bool = false
    var error: String?
    var savedMyMealName: String?   // confirmación tras guardar una sección como "Mi comida"
    var coachInsight: CoachInsight? = nil
    var isLoadingCoach: Bool = false

    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: todayMeals, by: { $0.type })
    }

    var caloriesRemaining: Double {
        guard let target = dailyCalorieTarget else { return 0 }
        return target - todayTotals.calories
    }

    var calorieProgress: Double {
        guard let target = dailyCalorieTarget, target > 0 else { return 0 }
        return min(todayTotals.calories / target, 1.0)
    }
}

final class MealsViewModel: ObservableObject {
    @Published var uiState: MealsUiState = .init()
    private var router: MealsRouter
    private var mealUseCase: MealUseCaseProtocol
    private var userProfileUseCase: UserProfileUseCaseProtocol
    private var coachUseCase: CoachUseCaseProtocol

    init(router: MealsRouter,
         mealUseCase: MealUseCaseProtocol,
         userProfileUseCase: UserProfileUseCaseProtocol,
         coachUseCase: CoachUseCaseProtocol) {
        self.router = router
        self.mealUseCase = mealUseCase
        self.userProfileUseCase = userProfileUseCase
        self.coachUseCase = coachUseCase
        loadProfileTargets()
        loadMeals()
        loadCoach()
    }

    private func loadCoach() {
        uiState.isLoadingCoach = true
        Task { @MainActor in
            self.uiState.coachInsight = await coachUseCase.nutritionInsight()
            self.uiState.isLoadingCoach = false
        }
    }

    func loadMeals() {
        uiState.isLoading = true
        Task {
            do {
                let meals = try await mealUseCase.getMeals(for: uiState.selectedDate)
                let totals = meals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
                let recipeCount = meals.filter { $0.myMealName != nil }.count
                print("[Meals] loadMeals fetched \(meals.count) total, \(recipeCount) recipe(s) for \(uiState.selectedDate)")
                await MainActor.run {
                    self.uiState.todayMeals = meals.sorted { $0.timestamp < $1.timestamp }
                    self.uiState.todayTotals = totals
                    self.uiState.isLoading = false
                }
            } catch {
                print("[Meals] loadMeals error: \(error)")
                await MainActor.run {
                    self.uiState.error = "Error al cargar las comidas"
                    self.uiState.isLoading = false
                }
            }
        }
    }

    private func loadProfileTargets() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let profile = try? await self.userProfileUseCase.getProfile()
            self.uiState.dailyCalorieTarget = profile?.todayCalorieTarget
            self.uiState.macroTargets = profile?.todayMacroTargets
        }
    }

    func deleteMeal(id: UUID) {
        Task {
            do {
                try await mealUseCase.deleteMeal(id)
                await MainActor.run {
                    self.loadMeals()
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Error al eliminar la comida"
                }
            }
        }
    }

    /// Cambia la cantidad de un alimento de una comida.
    ///
    /// Se reescribe la comida con `saveMeal`, que es upsert por id. Ya no se borra
    /// antes: no hace falta y era lo que impedía editar una comida que solo existe
    /// en el dispositivo.
    func updateFoodItem(itemId: UUID, mealId: UUID, newQuantity: Double) {
        guard let meal = uiState.todayMeals.first(where: { $0.id == mealId }) else { return }
        guard newQuantity > 0 else { return }

        let updatedItems: [FoodItem] = meal.items.map { item in
            guard item.id == itemId else { return item }
            var copy = item
            copy.quantity = newQuantity
            return copy
        }

        // Se copia la comida y se le cambian los items, en vez de construir una
        // nueva: así no se pierde `myMealName`. Reconstruyéndola se perdía, y editar
        // la cantidad de un alimento dentro de una receta le quitaba el nombre de la
        // receta sin que nada lo dijera.
        var updatedMeal = meal
        updatedMeal.items = updatedItems

        Task {
            do {
                // `saveMeal` a secas, sin borrar antes: es upsert por id en el
                // dispositivo y en el servidor. El `deleteMeal` previo era además la
                // causa de que esto NO funcionara: con una comida que solo existe en
                // local, el servidor devolvía 404 al borrarla, el error se propagaba y
                // la edición no llegaba a ocurrir.
                try await mealUseCase.saveMeal(updatedMeal)
                await MainActor.run { self.loadMeals() }
            } catch {
                await MainActor.run { self.uiState.error = "Error al actualizar" }
            }
        }
    }

    /// Deletes a single food item from a meal. If the meal had only that item,
    /// the entire meal is removed. Otherwise the meal is updated removing the item.
    func deleteFoodItem(itemId: UUID, mealId: UUID) {
        print("[Meals] deleteFoodItem called itemId=\(itemId) mealId=\(mealId)")
        guard let meal = uiState.todayMeals.first(where: { $0.id == mealId }) else {
            print("[Meals] meal not found in todayMeals")
            return
        }
        print("[Meals] meal items count=\(meal.items.count)")

        Task {
            do {
                if meal.items.count > 1 {
                    // Quitar un alimento de una comida con varios es una EDICIÓN, no
                    // un borrado: se reescribe la comida sin él. Borrarla y recrearla
                    // abría una ventana en la que un fallo la dejaba borrada, y con una
                    // comida solo-local el 404 del servidor hacía fallar la operación
                    // entera. Se copia para no perder `myMealName`.
                    var updated = meal
                    updated.items = meal.items.filter { $0.id != itemId }
                    try await mealUseCase.saveMeal(updated)
                    print("[Meals] re-saved meal with \(updated.items.count) items")
                } else {
                    // Era el único alimento: la comida entera se va.
                    try await mealUseCase.deleteMeal(mealId)
                    print("[Meals] meal deleted")
                }
                await MainActor.run {
                    self.loadMeals()
                }
            } catch {
                print("[Meals] delete error: \(error)")
                await MainActor.run {
                    self.uiState.error = "Error al eliminar"
                }
            }
        }
    }

    /// Cambia la hora de una sección entera (p. ej. "la comida fue a las 14:30").
    ///
    /// La hora se edita por SECCIÓN y no por registro porque cada alimento que se
    /// añade crea su propio `Meal`: un desayuno de tres cosas son tres registros con
    /// horas a segundos de distancia, y pedir la hora de cada uno sería absurdo.
    ///
    /// Se DESPLAZAN todas por igual en vez de igualarlas: así la hora elegida es la
    /// del primero y se conserva el orden en que se comieron las cosas.
    func updateSectionTime(type: MealType, to newTime: Date) {
        let meals = (uiState.mealsByType[type] ?? []).sorted { $0.timestamp < $1.timestamp }
        guard !meals.isEmpty else { return }

        let day = uiState.selectedDate
        let timestamps = meals.map(\.timestamp)
        guard MealTime.changes(timestamps, movingEarliestTo: newTime, within: day) else { return }

        let newTimestamps = MealTime.shifted(
            timestamps, anchoringEarliestAt: newTime, within: day
        )

        Task {
            do {
                for (meal, timestamp) in zip(meals, newTimestamps) {
                    var updated = meal
                    updated.timestamp = timestamp
                    // `saveMeal` a secas: es upsert por id tanto en el dispositivo
                    // como en el servidor. Borrar antes —como hacen `updateFoodItem`
                    // y `deleteFoodItem`— abre una ventana en la que un fallo deja
                    // la comida borrada y sin reescribir.
                    try await mealUseCase.saveMeal(updated)
                }
                await MainActor.run { self.loadMeals() }
            } catch {
                await MainActor.run { self.uiState.error = "No se pudo cambiar la hora" }
            }
        }
    }

    /// Guarda todos los alimentos de una sección (p.ej. todo el desayuno) como una
    /// "Mi comida" reutilizable, para poder añadirla luego de una sola vez.
    /// Funciona en local (invitado) o contra el backend (logueado), igual que el
    /// resto de "Mis comidas", y entra en el flujo de subida al iniciar sesión.
    func saveSectionAsMyMeal(type: MealType, name: String) {
        let items = (uiState.mealsByType[type] ?? []).flatMap { $0.items }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !items.isEmpty else { return }
        let finalName = trimmed.isEmpty ? type.rawValue : trimmed
        let myMeal = MyMeal(name: finalName, items: items)
        Task {
            do {
                try await mealUseCase.saveMyMeal(myMeal)
                await MainActor.run { self.uiState.savedMyMealName = finalName }
            } catch {
                await MainActor.run { self.uiState.error = "Error al guardar la comida" }
            }
        }
    }

    func changeDate(to date: Date) {
        uiState.selectedDate = date
        loadProfileTargets()
        loadMeals()
    }

    func goToPreviousDay() {
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: uiState.selectedDate) ?? uiState.selectedDate
        changeDate(to: prev)
    }

    func goToNextDay() {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: uiState.selectedDate) ?? uiState.selectedDate
        changeDate(to: next)
    }

    var canGoToNextDay: Bool { true }

    func goToAddMeal() {
        router.goToAddMeal(prefilledType: nil, date: uiState.selectedDate)
    }

    func goToAddMeal(for type: MealType) {
        router.goToAddMeal(prefilledType: type, date: uiState.selectedDate)
    }

    func goToBarcodeScanner() {
        router.goToBarcodeScanner()
    }

    func goToChat(prompt: String) {
        router.goToChat(prompt: prompt, topic: .nutrition)
    }
}
