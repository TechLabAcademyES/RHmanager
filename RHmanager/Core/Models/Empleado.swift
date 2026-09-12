import Foundation

struct Empleado: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var horasContratadas: Double          // horas semanales contratadas
    var esTurnoFijo: Bool                 // true = siempre el mismo turno
    var franjaFijaID: UUID?               // referencia a FranjaTurno si esTurnoFijo == true
    var fechaAlta: Date = Date()
    var activo: Bool = true

    /// Nº máximo de fines de semana largos (sáb-lun) que puede tener seguidos
    /// antes de "deberle" uno a la rotación; se usa como dato informativo,
    /// el reparto real lo hace el motor de horarios.
    var participaEnRotaFinDeSemanaLargo: Bool = true
}