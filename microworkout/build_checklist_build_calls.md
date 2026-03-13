## Checklist de call sites con ".build("

Formato: archivo : línea - clasificación (Preview/runtime) - nota

1. microworkout/Presentation/Modules/Home/HomeRouter.swift:13 - runtime - TrainingListV2Builder(component: component).build()
2. microworkout/Presentation/Modules/Home/HomeRouter.swift:17 - runtime - LoggedExercisesBuilder(component: component).build(for: entryDay)
3. microworkout/Presentation/Modules/Home/HomeRouter.swift:21 - runtime - TrainingDetailV2Builder(component: component).build(this: training, and: appState)
4. microworkout/Presentation/Modules/Home/HomeRouter.swift:25 - runtime - HealthWorkoutDetailBuilder(component: component).build(for: workout)

5. microworkout/Modules/PersonalData/Presentation/Screens/Account/AccountView.swift:113 - runtime - VerifyPasswordBuilder().build(isShowingVerifyPasswordSheet: $isShowingVerifyPassword, ...)

6. microworkout/Presentation/Modules/TrainingList/TrainingListRouter.swift:11 - runtime - TrainingDetailBuilder().build(this: training, and: namespace)

7. microworkout/Presentation/Modules/TrainingDetail/TrainingDetailView.swift:45 - Preview - TrainingDetailBuilder().build(this: Training(name: "example", ...))

8. microworkout/Presentation/Modules/TrainingV2List/TrainingListV2Router.swift:11 - runtime - TrainingDetailBuilder().build(this: training, and: namespace)

9. microworkout/Presentation/Modules/Home/HomeView.swift:313 - Preview - HomeBuilder(component: TestAppComponent()).build(appState: AppState())

10. microworkout/Presentation/Modules/Switcher/SwitcherView.swift:15 - runtime - HomeBuilder(component: component).build(appState: appState)
11. microworkout/Presentation/Modules/Switcher/SwitcherView.swift:20 - runtime - CurrentSessionBuilder(component: component).build()
12. microworkout/Presentation/Modules/Switcher/SwitcherView.swift:25 - runtime - MealsBuilder(component: component).build()
13. microworkout/Presentation/Modules/Switcher/SwitcherView.swift:30 - runtime - ProfileBuilder(component: component).build()
14. microworkout/Presentation/Modules/Switcher/SwitcherView.swift:37 - runtime - OnboardingBuilder(component: component).build(appState: appState)

15. microworkout/Presentation/App/RootView.swift:34 - runtime - CurrentTrainingBuilder(component: component).build(appState: appState)
16. microworkout/Presentation/Components/DetailView.swift:22 - Preview - CurrentTrainingBuilder(component: component).build(appState: AppState())

17. microworkout/Presentation/Modules/Training/Tabbar/TabbarView.swift:13 - Preview - HomeBuilder(component: TestAppComponent()).build(appState: AppState())
18. microworkout/Presentation/Modules/Training/Tabbar/TabbarView.swift:18 - runtime - HealthKitBuilder().build()

19. microworkout/Presentation/Modules/Meals/MealsRouter.swift:18 - runtime - AddMealBuilder(component: component).build()
20. microworkout/Presentation/Modules/Meals/AddMeal/AddMealRouter.swift:18 - runtime - BarcodeScannerBuilder(component: component).build(onScanComplete: onScanComplete)

21. microworkout/Presentation/Modules/LoggedExercises/LoggedExercisesView.swift:110 - Preview - LoggedExercisesBuilder(component: TestAppComponent()).build(for: WorkoutEntryByDay(...))
22. microworkout/Presentation/Modules/Meals/MealsView.swift:195 - Preview - MealsBuilder(component: TestAppComponent()).build()
23. microworkout/Presentation/Modules/Meals/BarcodeScanner/BarcodeScannerView.swift:408 - Preview - BarcodeScannerBuilder(component: TestAppComponent()).build(onScanComplete: { _ in })
24. microworkout/Presentation/Modules/Meals/AddMeal/AddMealView.swift:502 - Preview - AddMealBuilder(component: TestAppComponent()).build()

25. microworkout/Presentation/Modules/Training/Home/HomeTrainingView.swift:20 - runtime - NavigationLink(destination: DetailWorkoutBuilder().build(with: $workout))

26. microworkout/Presentation/Modules/TrainingList/TrainingListView.swift:288 - runtime - TrainingListBuilder().build()

27. microworkout/Modules/PersonalData/Presentation/Screens/Account/AccountView.swift:113 - runtime - VerifyPasswordBuilder().build(isShowingVerifyPasswordSheet: $isShowingVerifyPassword, ...)
28. microworkout/Modules/PersonalData/Presentation/Screens/Account/AccountView.swift:117 - runtime - ChangePasswordBuilder().build(needToShowToast: $isShowingToast)
29. microworkout/Modules/PersonalData/Presentation/Screens/Account/AccountView.swift:195 - runtime - UserContactBuilder().build()
30. microworkout/Modules/PersonalData/Presentation/Screens/Account/AccountView.swift:201 - runtime - ChangeEmailBuilder().build()


## Call sites que reintroducen DefaultAppComponent (problema)
- microworkout/Presentation/App/MicroWorkoutApp.swift:11 - entrypoint - DefaultAppComponent() uso correcto en entrypoint
- microworkout/Presentation/Modules/Switcher/SwitcherView.swift:7 - runtime - init(component: AppComponentProtocol = DefaultAppComponent()) - valor por defecto problemático
- microworkout/Presentation/Modules/HealthWorkoutDetail/HealthWorkoutDetailBuilder.swift:3 - runtime - crea let component = DefaultAppComponent() dentro de build
- microworkout/Data/Datasources/WorkoutEntry/Local/UserDefaults/WorkoutEntryLocalDataSource.swift:11 - runtime - init(storage: UserDefaultsManagerProtocol = DefaultAppComponent().makeUserDefaultsManager()) - valor por defecto problemático
- microworkout/Data/Datasources/User/UserLocalDataSource.swift:17 - runtime - init(storage: UserDefaultsManagerProtocol = DefaultAppComponent().makeUserDefaultsManager()) - valor por defecto problemático
- microworkout/Data/Datasources/Meal/Local/MealLocalDataSource.swift:16 - runtime - init(storage: UserDefaultsManagerProtocol = DefaultAppComponent().makeUserDefaultsManager()) - valor por defecto problemático
- gymwidget/gymwidget.swift:15 - runtime - DefaultAppComponent() usado para construir datasource (widget target)



NOTA: Marqué Preview cuando el call site usa TestAppComponent() o está dentro de a PreviewProvider/preview code. Los call sites sin TestAppComponent o dentro de routers/views que se inicializan en runtime los marqué como runtime. Algunos archivos contienen múltiples llamadas; revisarlos para cada línea exacta.

Siguiente paso: Puedo refinar las ubicaciones con número de línea exacto para los archivos marcados con "??" y corregir builders que reciben DefaultAppComponent oculto. Procedo a enumerar líneas exactas para los archivos pendientes.