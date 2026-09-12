import Foundation

final class AusenciasViewModel: ObservableObject {

    @Published var ausencias: [Ausencia] {
        didSet {
            AlmacenamientoService.shared.guardar(ausencias, en: Almacen.ausencias)
        }
    }

    init() {
        self.ausencias = AlmacenamientoService.shared
            .cargar([Ausencia].self, desde: Almacen.ausencias) ?? []
    }

    func añadir(_ ausencia: Ausencia) {
        ausencias.append(ausencia)
    }

    func actualizar(_ ausencia: Ausencia) {
        guard let idx = ausencias.firstIndex(where: { $0.id == ausencia.id }) else { return }
        ausencias[idx] = ausencia
    }

    func eliminar(_ ausencia: Ausencia) {
        ausencias.removeAll { $0.id == ausencia.id }
    }

    func ausencias(de tipo: TipoAusencia) -> [Ausencia] {
        ausencias.filter { $0.tipo == tipo }
    }

    func ausencias(paraEmpleado id: UUID) -> [Ausencia] {
        ausencias.filter { $0.empleadoID == id }
    }
}