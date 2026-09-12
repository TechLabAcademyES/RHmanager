import Foundation

/// Motor de generación/reajuste de horarios.
///
/// IMPORTANTE (léelo antes de tocar el algoritmo): esto es un algoritmo
/// GREEDY (voraz) por semanas, no un solver de optimización combinatoria.
/// Cumple las restricciones de forma "best effort" y es determinista
/// (mismo input -> mismo output), lo cual es clave para que al cambiar
/// una restricción el calendario se recalcule de forma predecible.
/// Si en el futuro quieres reglas más finas (p.ej. reparto perfectamente
/// equitativo de fines de semana), el sitio para ampliarlo es este fichero.
final class MotorHorarios {

    struct Entrada {
        var rango: ClosedRange<Date>
        var configuracion: ConfiguracionGeneral
        var empleados: [Empleado]
        var ausencias: [Ausencia]
        /// Asignaciones ya existentes marcadas como fijadas manualmente:
        /// el motor las respeta y no las sobrescribe.
        var asignacionesFijadasManualmente: [Asignacion]
    }

    private let calendario: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // lunes
        return cal
    }()

    func generar(_ entrada: Entrada) -> [Asignacion] {
        var resultado: [Asignacion] = []

        // 1) Días fijados manualmente: se respetan tal cual.
        let fijadasPorClave = Dictionary(uniqueKeysWithValues:
            entrada.asignacionesFijadasManualmente.map { ($0.claveUnica, $0) })
        resultado.append(contentsOf: entrada.asignacionesFijadasManualmente)

        // 2) Empleados activos, ordenados de forma estable (por nombre) para
        //    que la rotación sea determinista.
        let empleados = entrada.empleados.filter { $0.activo }.sorted { $0.nombre < $1.nombre }
        guard !empleados.isEmpty else { return resultado }

        // 3) Agrupamos los días del rango por semana ISO.
        let dias = diasEnRango(entrada.rango)
        let semanas = Dictionary(grouping: dias) { calendario.component(.weekOfYear, from: $0) }
            .sorted { $0.key < $1.key }

        // 4) Índice de rotación de fin de semana largo: avanza una posición
        //    cada N semanas (frecuenciaRotaFinDeSemanaSemanas).
        let elegiblesRotacion = empleados.filter { $0.participaEnRotaFinDeSemanaLargo && !$0.esTurnoFijo }

        for (indiceSemana, (numeroSemana, diasSemana)) in semanas.enumerated() {
            let diasOrdenados = diasSemana.sorted()

            // Empleado al que le toca fin de semana largo esta semana (si aplica).
            var empleadoRotacion: Empleado? = nil
            if entrada.configuracion.activarRotaFinDeSemanaLargo,
               entrada.configuracion.frecuenciaRotaFinDeSemanaSemanas > 0,
               !elegiblesRotacion.isEmpty,
               numeroSemana % entrada.configuracion.frecuenciaRotaFinDeSemanaSemanas == 0 {
                let idx = (indiceSemana / max(entrada.configuracion.frecuenciaRotaFinDeSemanaSemanas, 1)) % elegiblesRotacion.count
                empleadoRotacion = elegiblesRotacion[idx]
            }

            resultado.append(contentsOf: generarSemana(
                dias: diasOrdenados,
                empleados: empleados,
                configuracion: entrada.configuracion,
                ausencias: entrada.ausencias,
                fijadasPorClave: fijadasPorClave,
                empleadoRotacionFinDeSemana: empleadoRotacion
            ))
        }

        return resultado
    }

    // MARK: - Generación semanal

    private func generarSemana(
        dias: [Date],
        empleados: [Empleado],
        configuracion: ConfiguracionGeneral,
        ausencias: [Ausencia],
        fijadasPorClave: [String: Asignacion],
        empleadoRotacionFinDeSemana: Empleado?
    ) -> [Asignacion] {

        var asignacionesSemana: [Asignacion] = []
        // Contador de libres ya repartidos por empleado esta semana.
        var libresRepartidos: [UUID: Int] = [:]
        // Último turno de trabajo asignado a cada empleado (para respetar descansos).
        var ultimoTurnoPorEmpleado: [UUID: (fecha: Date, franja: FranjaTurno)] = [:]

        for dia in dias {
            let esFinDeSemanaLargo = esSabadoDomingoOLunes(dia)
            var trabajadoresMañana = 0
            var trabajadoresTarde = 0
            var libresHoy = 0

            for (indice, empleado) in empleados.enumerated() {

                let clave = Asignacion.clave(empleadoID: empleado.id, fecha: dia)

                // Respeta lo fijado manualmente.
                if let fijada = fijadasPorClave[clave] {
                    contabiliza(fijada, enMañana: &trabajadoresMañana, enTarde: &trabajadoresTarde,
                                libre: &libresHoy, configuracion: configuracion)
                    continue
                }

                // Respeta ausencias (vacaciones/baja/festivo devuelto) ya registradas.
                if let ausencia = ausencias.first(where: { $0.empleadoID == empleado.id && $0.incluye(dia) }) {
                    asignacionesSemana.append(Asignacion(empleadoID: empleado.id, fecha: dia,
                                                          categoria: ausencia.tipo.categoriaAsociada,
                                                          franjaTurnoID: nil))
                    libresHoy += 1
                    continue
                }

                // Rotación de fin de semana largo: sáb-dom-lun libres para el empleado de turno.
                if esFinDeSemanaLargo, let rot = empleadoRotacionFinDeSemana, rot.id == empleado.id {
                    asignacionesSemana.append(Asignacion(empleadoID: empleado.id, fecha: dia,
                                                          categoria: .libre, franjaTurnoID: nil))
                    libresHoy += 1
                    libresRepartidos[empleado.id, default: 0] += 1
                    continue
                }

                // Turno fijo: siempre su franja, salvo que hoy le toque librar
                // por reparto semanal de días libres.
                let leTocaLibrarHoy = decidirSiLibraHoy(
                    empleado: empleado, indice: indice, dia: dia, diasSemana: dias,
                    configuracion: configuracion, libresRepartidos: libresRepartidos,
                    libresHoy: libresHoy
                )

                if leTocaLibrarHoy {
                    asignacionesSemana.append(Asignacion(empleadoID: empleado.id, fecha: dia,
                                                          categoria: .libre, franjaTurnoID: nil))
                    libresHoy += 1
                    libresRepartidos[empleado.id, default: 0] += 1
                    continue
                }

                // Elegir franja de trabajo.
                let franjaElegida = elegirFranja(
                    para: empleado, dia: dia, configuracion: configuracion,
                    trabajadoresMañana: trabajadoresMañana, trabajadoresTarde: trabajadoresTarde,
                    ultimoTurno: ultimoTurnoPorEmpleado[empleado.id]
                )

                asignacionesSemana.append(Asignacion(empleadoID: empleado.id, fecha: dia,
                                                      categoria: franjaElegida.categoria,
                                                      franjaTurnoID: franjaElegida.id))
                ultimoTurnoPorEmpleado[empleado.id] = (dia, franjaElegida)
                if franjaElegida.categoria == .mañana { trabajadoresMañana += 1 }
                if franjaElegida.categoria == .tarde || franjaElegida.categoria == .especial { trabajadoresTarde += 1 }
            }
        }

        return asignacionesSemana
    }

    // MARK: - Reglas auxiliares

    private func contabiliza(_ asignacion: Asignacion, enMañana: inout Int, enTarde: inout Int,
                              libre: inout Int, configuracion: ConfiguracionGeneral) {
        switch asignacion.categoria {
        case .mañana: enMañana += 1
        case .tarde, .especial: enTarde += 1
        default: libre += 1
        }
    }

    private func esSabadoDomingoOLunes(_ fecha: Date) -> Bool {
        let dow = calendario.component(.weekday, from: fecha) // 1 = domingo en Calendar estándar
        // Con Calendar iso8601 weekday sigue igual mapeo (1=domingo...7=sábado).
        return dow == 7 || dow == 1 || dow == 2 // sábado, domingo, lunes
    }

    /// Decide si un empleado debe librar hoy, repartiendo `diasLibresSemanales`
    /// a lo largo de la semana sin superar `maxPersonasSimultaneasLibres` por día.
    /// Estrategia simple: cada empleado libra en los días (indice + N*offset) % 7
    /// calculados a partir de su posición en la lista, para que los libres no
    /// coincidan todos el mismo día.
    private func decidirSiLibraHoy(
        empleado: Empleado, indice: Int, dia: Date, diasSemana: [Date],
        configuracion: ConfiguracionGeneral, libresRepartidos: [UUID: Int], libresHoy: Int
    ) -> Bool {
        guard let posicionDia = diasSemana.firstIndex(of: dia) else { return false }
        let yaLibrados = libresRepartidos[empleado.id] ?? 0
        guard yaLibrados < configuracion.diasLibresSemanales else { return false }
        guard libresHoy < configuracion.maxPersonasSimultaneasLibres else { return false }

        // Reparte los días libres de cada empleado distribuidos uniformemente
        // en la semana según su índice, evitando que todos libren el mismo día.
        let hueco = max(diasSemana.count / max(configuracion.diasLibresSemanales, 1), 1)
        let offsetPropio = indice % diasSemana.count
        let diaObjetivo = (offsetPropio + (posicionDia == 0 ? 0 : 0)) // base
        let tocaEsteDia = ((posicionDia + offsetPropio) % hueco) == 0
        _ = diaObjetivo
        return tocaEsteDia
    }

    /// Elige la franja de mañana/tarde más adecuada para cubrir mínimos de
    /// apertura/cierre y respetar el descanso mínimo entre turnos.
    private func elegirFranja(
        para empleado: Empleado, dia: Date, configuracion: ConfiguracionGeneral,
        trabajadoresMañana: Int, trabajadoresTarde: Int,
        ultimoTurno: (fecha: Date, franja: FranjaTurno)?
    ) -> FranjaTurno {

        // Turno fijo: se respeta salvo conflicto grave de descanso (best effort).
        if empleado.esTurnoFijo, let fijaID = empleado.franjaFijaID,
           let franjaFija = configuracion.franja(porID: fijaID) {
            return franjaFija
        }

        let necesitaMañana = trabajadoresMañana < configuracion.personalMinimoApertura
        let necesitaTarde = trabajadoresTarde < configuracion.personalMinimoCierre

        let candidatasMañana = configuracion.turnosMañana
        let candidatasTarde = configuracion.turnosTarde

        func cumpleDescanso(_ candidata: FranjaTurno) -> Bool {
            guard let ultimo = ultimoTurno else { return true }
            let horasEntreDias = 24.0 * Double(diasDeDiferencia(ultimo.fecha, dia))
            let finAnterior = ultimo.franja.franja.fin.minutosDesdeMedianoche
            let inicioNuevo = candidata.franja.inicio.minutosDesdeMedianoche
            let descansoHoras = (horasEntreDias) - Double(finAnterior) / 60.0 + Double(inicioNuevo) / 60.0
            return descansoHoras >= configuracion.horasDescansoEntreTurnos
        }

        if necesitaMañana, let elegida = candidatasMañana.first(where: cumpleDescanso) ?? candidatasMañana.first {
            return elegida
        }
        if necesitaTarde, let elegida = candidatasTarde.first(where: cumpleDescanso) ?? candidatasTarde.first {
            return elegida
        }
        // Sin urgencia de mínimos: alterna para repartir carga, priorizando descanso.
        if let elegida = (candidatasMañana + candidatasTarde).first(where: cumpleDescanso) {
            return elegida
        }
        return candidatasMañana.first ?? candidatasTarde.first ?? FranjaTurno(
            nombre: "Sin definir", categoria: .mañana,
            franja: Franja(inicio: HoraSimple(hora: 9, minuto: 0), fin: HoraSimple(hora: 14, minuto: 0)))
    }

    private func diasDeDiferencia(_ a: Date, _ b: Date) -> Int {
        calendario.dateComponents([.day], from: calendario.startOfDay(for: a), to: calendario.startOfDay(for: b)).day ?? 1
    }

    private func diasEnRango(_ rango: ClosedRange<Date>) -> [Date] {
        var dias: [Date] = []
        var actual = calendario.startOfDay(for: rango.lowerBound)
        let fin = calendario.startOfDay(for: rango.upperBound)
        while actual <= fin {
            dias.append(actual)
            guard let siguiente = calendario.date(byAdding: .day, value: 1, to: actual) else { break }
            actual = siguiente
        }
        return dias
    }
}