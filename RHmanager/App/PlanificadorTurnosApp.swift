import SwiftUI

@main
struct PlanificadorTurnosApp: App {
    @StateObject private var configuracionVM = ConfiguracionViewModel()
    @StateObject private var personalVM = PersonalViewModel()
    @StateObject private var ausenciasVM = AusenciasViewModel()
    @StateObject private var calendarioVM: CalendarioViewModel

    init() {
        let config = ConfiguracionViewModel()
        let personal = PersonalViewModel()
        let ausencias = AusenciasViewModel()

        _configuracionVM = StateObject(wrappedValue: config)
        _personalVM = StateObject(wrappedValue: personal)
        _ausenciasVM = StateObject(wrappedValue: ausencias)
        _calendarioVM = StateObject(wrappedValue: CalendarioViewModel(
            configuracionVM: config,
            personalVM: personal,
            ausenciasVM: ausencias
        ))
    }

    var body: some Scene {
        WindowGroup {
            CalendarioView()
                .environmentObject(configuracionVM)
                .environmentObject(personalVM)
                .environmentObject(ausenciasVM)
                .environmentObject(calendarioVM)
        }
    }
}