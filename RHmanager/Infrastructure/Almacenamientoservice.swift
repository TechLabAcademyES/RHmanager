import Foundation

/// Servicio de persistencia simple basado en ficheros JSON dentro del
/// directorio Documents de la app. Es intencionadamente sencillo (sin
/// CoreData/SwiftData) para que sea fácil de leer y extender por un
/// desarrollador que empieza: cada "tabla" es un fichero .json con un array
/// Codable.
final class AlmacenamientoService {

    static let shared = AlmacenamientoService()
    private init() {}

    private var carpetaDocumentos: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func url(_ nombreFichero: String) -> URL {
        carpetaDocumentos.appendingPathComponent(nombreFichero)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func guardar<T: Codable>(_ objeto: T, en nombreFichero: String) {
        do {
            let datos = try encoder.encode(objeto)
            try datos.write(to: url(nombreFichero), options: .atomic)
        } catch {
            print("⚠️ Error guardando \(nombreFichero): \(error)")
        }
    }

    func cargar<T: Codable>(_ tipo: T.Type, desde nombreFichero: String) -> T? {
        let ruta = url(nombreFichero)
        guard FileManager.default.fileExists(atPath: ruta.path) else { return nil }
        do {
            let datos = try Data(contentsOf: ruta)
            return try decoder.decode(T.self, from: datos)
        } catch {
            print("⚠️ Error cargando \(nombreFichero): \(error)")
            return nil
        }
    }
}

/// Nombres de fichero centralizados para evitar strings sueltos repartidos
/// por el código.
enum Almacen {
    static let configuracion = "configuracion.json"
    static let empleados = "empleados.json"
    static let asignaciones = "asignaciones.json"
    static let ausencias = "ausencias.json"
}