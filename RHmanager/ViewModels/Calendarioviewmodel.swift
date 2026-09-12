import Foundation
import Combine

/// Vista de calendario disponible.
enum ModoVistaCalendario: String, CaseIterable, Identifiable {
    case mensual = "Mensual"
    case semanal = "Semanal"
    case diaria = "Diaria"
    var id: String { rawValue }
}

/// Orquesta el calendario: guarda las asignaciones, y se suscribe a los
/// cambios de configuración / personal / ausencias para relanzar el motor
/// de horarios automáticamente (con un pequeño debounce para no recalcular
/// en cada pulsación de teclado mientras el usuario edita un campo).
final class CalendarioViewModel: ObservableObject {

    @Published var asignaciones: [Asignacion] {
        didSet {
            AlmacenamientoService.shared.guardar(asignaciones, en: Almacen.asignaciones)
        }
    }

    @Published var modoVista: ModoVistaCalendario = .semanal
    @Published var fechaReferencia: Date = Date()

    private let motor = MotorHorarios()
    private var cancelables = Set<AnyCancellable>()

    private unowned let configuracionVM: ConfiguracionViewModel
    private unowned let personalVM: PersonalViewModel
    private unowned let ausenciasVM: AusenciasViewModel

    /// Rango de fechas que mantenemos generado: 6 meses hacia atrás y 6 hacia
    /// delante desde el momento de arrancar la app. Se puede ajustar.
    private var rangoGeneracion: ClosedRange<Date> {
        let cal = Calendar.current
        let inicio = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let fin = cal.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        return inicio...fin
    }

    init(configuracionVM: ConfiguracionViewModel, personalVM: PersonalViewModel, ausenciasVM: AusenciasViewModel) {
        self.configuracionVM = configuracionVM
        self.personalVM = personalVM
        self.ausenciasVM = ausenciasVM
        self.asignaciones = AlmacenamientoService.shared
            .cargar([Asignacion].self, desde: Almacen.asignaciones) ?? []

        observarCambios()

        if asignaciones.isEmpty {
            regenerar()
        }
    }

    private func observarCambios() {
        Publishers.MergeMany(
            configuracionVM.$configuracion.map { _ in () }.eraseToAnyPublisher(),
            personalVM.$empleados.map { _ in () }.eraseToAnyPublisher(),
            ausenciasVM.$ausencias.map { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.regenerar()
        }
        .store(in: &cancelables)
    }

    /// Relanza el motor de horarios respetando lo fijado manualmente.
    func regenerar() {
        let fijadas = asignaciones.filter { $0.fijadaManualmente }
        let nuevas = motor.generar(.init(
            rango: rangoGeneracion,
            configuracion: configuracionVM.configuracion,
            empleados: personalVM.empleados,
            ausencias: ausenciasVM.ausencias,
            asignacionesFijadasManualmente: fijadas
        ))
        asignaciones = nuevas
    }

    // MARK: - Edición manual de una celda

    func fijarManualmente(empleadoID: UUID, fecha: Date, categoria: CategoriaTurno, franjaTurnoID: UUID?) {
        let clave = Asignacion.clave(empleadoID: empleadoID, fecha: fecha)
        if let idx = asignaciones.firstIndex(where: { $0.claveUnica == clave }) {
            asignaciones[idx].categoria = categoria
            asignaciones[idx].franjaTurnoID = franjaTurnoID
            asignaciones[idx].fijadaManualmente = true
        } else {
            asignaciones.append(Asignacion(empleadoID: empleadoID, fecha: fecha, categoria: categoria,
                                            franjaTurnoID: franjaTurnoID, fijadaManualmente: true))
        }
        regenerar()
    }

    func liberarFijacionManual(empleadoID: UUID, fecha: Date) {
        let clave = Asignacion.clave(empleadoID: empleadoID, fecha: fecha)
        asignaciones.removeAll { $0.claveUnica == clave && $0.fijadaManualmente }
        regenerar()
    }

    // MARK: - Consultas usadas por las vistas

    func asignacion(empleadoID: UUID, fecha: Date) -> Asignacion? {
        let clave = Asignacion.clave(empleadoID: empleadoID, fecha: fecha)
        return asignaciones.first { $0.claveUnica == clave }
    }
}