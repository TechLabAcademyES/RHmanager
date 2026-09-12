import SwiftUI

/// Categoría general a la que pertenece un turno o una asignación de día.
enum CategoriaTurno: String, Codable, CaseIterable, Identifiable {
    case mañana
    case tarde
    case especial
    case libre
    case vacaciones
    case baja
    case festivoDevuelto

    var id: String { rawValue }

    var nombreVisible: String {
        switch self {
        case .mañana: return "Mañana"
        case .tarde: return "Tarde"
        case .especial: return "Especial"
        case .libre: return "Libre"
        case .vacaciones: return "Vacaciones"
        case .baja: return "Baja"
        case .festivoDevuelto: return "Festivo devuelto"
        }
    }

    /// Color identificativo para las tablas de calendario.
    var color: Color {
        switch self {
        case .mañana: return .yellow
        case .tarde: return .orange
        case .especial: return .purple
        case .libre: return .gray.opacity(0.35)
        case .vacaciones: return .green
        case .baja: return .red
        case .festivoDevuelto: return .blue
        }
    }

    /// Indica si esta categoría representa un turno de trabajo real
    /// (frente a ausencias como libre, vacaciones, baja, festivo devuelto).
    var esTurnoDeTrabajo: Bool {
        self == .mañana || self == .tarde || self == .especial
    }
}

/// Una franja de turno concreta y editable: p.ej. "Mañana corta 08:00-14:00"
/// dentro de la categoría .mañana, o "Turno partido 10:00-13:00 / 17:00-20:00"
/// como turno especial. Cada franja pertenece a una categoría general y tiene
/// su propio rango horario dentro (o fuera, en el caso especial) del rango
/// general definido para esa categoría.
struct FranjaTurno: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var categoria: CategoriaTurno
    var franja: Franja
    /// Color personalizado opcional (si es nil, se usa el de la categoría).
    var colorHex: String?

    var duracionHoras: Double { franja.duracionHoras }

    var color: Color {
        if let hex = colorHex, let c = Color(hex: hex) { return c }
        return categoria.color
    }
}

// Utilidad para crear Color desde hex y viceversa (usado por colorHex).
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb), hexSanitized.count == 6 else { return nil }
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}