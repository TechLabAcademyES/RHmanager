import Foundation

extension Calendar {
    /// Calendario compartido con semana empezando en lunes (convención española).
    static var esLunes: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "es_ES")
        return cal
    }
}

extension Date {
    func inicioDeSemana(_ cal: Calendar = .esLunes) -> Date {
        let componentes = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: componentes) ?? self
    }

    func diasDeEstaSemana(_ cal: Calendar = .esLunes) -> [Date] {
        let inicio = inicioDeSemana(cal)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: inicio) }
    }

    /// Todas las semanas (como array de 7 fechas) que tocan el mes de `self`.
    func semanasDelMes(_ cal: Calendar = .esLunes) -> [[Date]] {
        guard let rangoMes = cal.range(of: .day, in: .month, for: self),
              let primerDiaMes = cal.date(from: cal.dateComponents([.year, .month], from: self)) else { return [] }
        let ultimoDiaMes = cal.date(byAdding: .day, value: rangoMes.count - 1, to: primerDiaMes)!

        var semanas: [[Date]] = []
        var cursor = primerDiaMes.inicioDeSemana(cal)
        while cursor <= ultimoDiaMes {
            semanas.append(cursor.diasDeEstaSemana(cal))
            cursor = cal.date(byAdding: .day, value: 7, to: cursor)!
        }
        return semanas
    }

    func esMismoDia(que otra: Date, cal: Calendar = .esLunes) -> Bool {
        cal.isDate(self, inSameDayAs: otra)
    }

    func esMismoMes(que otra: Date, cal: Calendar = .esLunes) -> Bool {
        cal.isDate(self, equalTo: otra, toGranularity: .month)
    }

    func formateada(_ formato: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = formato
        return f.string(from: self)
    }
}