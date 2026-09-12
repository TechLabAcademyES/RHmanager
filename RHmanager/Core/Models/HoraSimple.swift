import Foundation

struct HoraSimple: Codable, Equatable, Hashable, Comparable {
    var hora: Int
    var minuto: Int

    var minutosDesdeMedianoche: Int {
        hora * 60 + minuto
    }

    var textoFormateado: String {
        String(format: "%02d:%02d", hora, minuto)
    }

    static func < (lhs: HoraSimple, rhs: HoraSimple) -> Bool {
        lhs.minutosDesdeMedianoche < rhs.minutosDesdeMedianoche
    }

    init(hora: Int, minuto: Int = 0) {
        self.hora = max(0, min(23, hora))
        self.minuto = max(0, min(59, minuto))
    }

    init?(cadena: String) {
        let partes = cadena.split(separator: ":").compactMap { Int($0) }
        guard partes.count >= 2 else { return nil }
        self.init(hora: partes[0], minuto: partes[1])
    }
}

struct Franja: Codable, Equatable, Hashable {
    var inicio: HoraSimple
    var fin: HoraSimple

    var duracionHoras: Double {
        let diff = fin.minutosDesdeMedianoche - inicio.minutosDesdeMedianoche
        return Double(diff) / 60.0
    }

    func contiene(_ hora: HoraSimple) -> Bool {
        hora.minutosDesdeMedianoche >= inicio.minutosDesdeMedianoche &&
        hora.minutosDesdeMedianoche <= fin.minutosDesdeMedianoche
    }
}