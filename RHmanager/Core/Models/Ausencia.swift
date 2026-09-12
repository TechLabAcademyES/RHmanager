import Foundation

enum TipoAusencia: String, Codable, CaseIterable, Identifiable {
    case vacaciones
    case baja
    case festivoDevuelto

    var id: String { rawValue }

    var nombreVisible: String {
        switch self {
        case .vacaciones: return "Vacaciones"
        case .baja: return "Baja"
        case .festivoDevuelto: return "Festivo devuelto"
        }
    }

    var categoriaAsociada: CategoriaTurno {
        switch self {
        case .vacaciones: return .vacaciones
        case .baja: return .baja
        case .festivoDevuelto: return .festivoDevuelto
        }
    }
}

/// Un periodo de ausencia (una o varias fechas) para un empleado.
/// El motor de horarios respeta estos periodos como no disponibles para
/// asignar turno y los pinta en el calendario con su categoría específica.
struct Ausencia: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var empleadoID: UUID
    var tipo: TipoAusencia
    var fechaInicio: Date
    var fechaFin: Date
    var comentario: String = ""

    func incluye(_ fecha: Date) -> Bool {
        let cal = Calendar.current
        let d = cal.startOfDay(for: fecha)
        let ini = cal.startOfDay(for: fechaInicio)
        let fin = cal.startOfDay(for: fechaFin)
        return d >= ini && d <= fin
    }
}