import Foundation

final class PersonalViewModel: ObservableObject {

    @Published var empleados: [Empleado] {
        didSet {
            AlmacenamientoService.shared.guardar(empleados, en: Almacen.empleados)
        }
    }

    init() {
        self.empleados = AlmacenamientoService.shared
            .cargar([Empleado].self, desde: Almacen.empleados) ?? []
    }

    func añadir(_ empleado: Empleado) {
        empleados.append(empleado)
    }

    func actualizar(_ empleado: Empleado) {
        guard let idx = empleados.firstIndex(where: { $0.id == empleado.id }) else { return }
        empleados[idx] = empleado
    }

    func eliminar(at offsets: IndexSet) {
        empleados.remove(atOffsets: offsets)
    }

    func eliminar(_ empleado: Empleado) {
        empleados.removeAll { $0.id == empleado.id }
    }
}