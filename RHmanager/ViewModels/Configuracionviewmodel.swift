import Foundation
import Combine

/// Gestiona la configuración general y notifica a quien esté suscrito
/// (normalmente CalendarioViewModel) cada vez que cambia algo, para que
/// el horario se reajuste automáticamente.
final class ConfiguracionViewModel: ObservableObject {

    @Published var configuracion: ConfiguracionGeneral {
        didSet {
            AlmacenamientoService.shared.guardar(configuracion, en: Almacen.configuracion)
        }
    }

    init() {
        self.configuracion = AlmacenamientoService.shared
            .cargar(ConfiguracionGeneral.self, desde: Almacen.configuracion) ?? ConfiguracionGeneral()
    }

    // MARK: - Gestión de franjas de turno (mañana / tarde / especiales)

    func añadirFranja(_ franja: FranjaTurno) {
        switch franja.categoria {
        case .mañana: configuracion.turnosMañana.append(franja)
        case .tarde: configuracion.turnosTarde.append(franja)
        case .especial: configuracion.turnosEspeciales.append(franja)
        default: break
        }
    }

    func actualizarFranja(_ franja: FranjaTurno) {
        func actualizar(_ lista: inout [FranjaTurno]) {
            if let idx = lista.firstIndex(where: { $0.id == franja.id }) {
                lista[idx] = franja
            }
        }
        switch franja.categoria {
        case .mañana: actualizar(&configuracion.turnosMañana)
        case .tarde: actualizar(&configuracion.turnosTarde)
        case .especial: actualizar(&configuracion.turnosEspeciales)
        default: break
        }
    }

    func eliminarFranja(_ franja: FranjaTurno) {
        switch franja.categoria {
        case .mañana: configuracion.turnosMañana.removeAll { $0.id == franja.id }
        case .tarde: configuracion.turnosTarde.removeAll { $0.id == franja.id }
        case .especial: configuracion.turnosEspeciales.removeAll { $0.id == franja.id }
        default: break
        }
    }

    func restaurarValoresPorDefecto() {
        configuracion = ConfiguracionGeneral()
    }
}