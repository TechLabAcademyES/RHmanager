import Foundation

/// Representa lo que un empleado tiene asignado en un día concreto:
/// un turno de trabajo (referenciando una FranjaTurno), o bien una ausencia
/// (libre, vacaciones, baja, festivo devuelto). Es el "registro interno"
/// que alimenta las vistas de calendario; las vistas solo pintan la franja
/// visual y el nombre, nunca editan estos datos directamente salvo por
/// edición manual explícita.
struct Asignacion: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var empleadoID: UUID
    var fecha: Date               // normalizada a startOfDay
    var categoria: CategoriaTurno
    var franjaTurnoID: UUID?      // solo relevante si categoria.esTurnoDeTrabajo
    /// Si el usuario ha tocado esta celda a mano, el motor de regeneración
    /// no la sobrescribe automáticamente al recalcular.
    var fijadaManualmente: Bool = false

    static func clave(empleadoID: UUID, fecha: Date) -> String {
        let d = Calendar.current.startOfDay(for: fecha)
        return "\(empleadoID.uuidString)_\(d.timeIntervalSince1970)"
    }

    var claveUnica: String { Asignacion.clave(empleadoID: empleadoID, fecha: fecha) }
}