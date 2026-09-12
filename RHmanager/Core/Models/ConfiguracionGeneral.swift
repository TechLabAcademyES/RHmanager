import Foundation

struct ConfiguracionGeneral: Codable, Equatable {
    var horarioGeneralInicio: HoraSimple = HoraSimple(hora: 7, minuto: 0)
    var horarioGeneralFin: HoraSimple = HoraSimple(hora: 22, minuto: 0)

    var aperturaInicio: HoraSimple = HoraSimple(hora: 9, minuto: 0)
    var aperturaFin: HoraSimple = HoraSimple(hora: 21, minuto: 30)

    var personalMinimoApertura: Int = 2
    var personalMinimoCierre: Int = 1

    var horasDescansoEntreTurnos: Double = 12.0
    var diasLibresSemanales: Int = 2
    var maxPersonasSimultaneasLibres: Int = 2

    var activarRotaFinDeSemanaLargo: Bool = true
    var frecuenciaRotaFinDeSemanaSemanas: Int = 3

    var turnosMañana: [FranjaTurno] = [
        FranjaTurno(nombre: "Mañana 40h", categoria: .mañana, franja: Franja(inicio: HoraSimple(hora: 8), fin: HoraSimple(hora: 16))),
        FranjaTurno(nombre: "Mañana 30h", categoria: .mañana, franja: Franja(inicio: HoraSimple(hora: 9), fin: HoraSimple(hora: 15)))
    ]

    var turnosTarde: [FranjaTurno] = [
        FranjaTurno(nombre: "Tarde 40h", categoria: .tarde, franja: Franja(inicio: HoraSimple(hora: 14), fin: HoraSimple(hora: 22))),
        FranjaTurno(nombre: "Tarde 30h", categoria: .tarde, franja: Franja(inicio: HoraSimple(hora: 15), fin: HoraSimple(hora: 21)))
    ]

    var turnosEspeciales: [FranjaTurno] = []

    func franja(porID id: UUID) -> FranjaTurno? {
        (turnosMañana + turnosTarde + turnosEspeciales).first { $0.id == id }
    }
}