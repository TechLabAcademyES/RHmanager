import SwiftUI

/// Vista mensual: cada columna es una semana del mes. Al ser una vista de
/// "vistazo rápido", cada celda muestra solo un resumen visual compacto
/// (barras de color por día dentro de la semana), no el detalle horario.
struct VistaMensual: View {
    @EnvironmentObject var calendarioVM: CalendarioViewModel
    @EnvironmentObject var personalVM: PersonalViewModel

    private var semanas: [[Date]] { calendarioVM.fechaReferencia.semanasDelMes() }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
                // Cabecera: nombre + una columna por semana
                GridRow {
                    Text("Personal").font(.subheadline.bold()).frame(width: 110, alignment: .leading)
                    ForEach(Array(semanas.enumerated()), id: \.offset) { indice, semana in
                        VStack(spacing: 2) {
                            Text("Sem. \(indice + 1)").font(.caption.bold())
                            if let primero = semana.first, let ultimo = semana.last {
                                Text("\(primero.formateada("d")) – \(ultimo.formateada("d MMM"))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 130)
                    }
                }
                Divider().gridCellColumns(semanas.count + 1)

                ForEach(personalVM.empleados) { empleado in
                    GridRow {
                        Text(empleado.nombre)
                            .font(.subheadline)
                            .frame(width: 110, alignment: .leading)
                            .lineLimit(1)

                        ForEach(Array(semanas.enumerated()), id: \.offset) { _, semana in
                            HStack(spacing: 2) {
                                ForEach(semana, id: \.self) { dia in
                                    let asignacion = calendarioVM.asignacion(empleadoID: empleado.id, fecha: dia)
                                    BarraTurno(asignacion: asignacion, franja: nil, mostrarTexto: false, compacta: true)
                                        .frame(width: 15, height: 20)
                                }
                            }
                            .frame(width: 130, alignment: .leading)
                        }
                    }
                    Divider().gridCellColumns(semanas.count + 1)
                }
            }
            .padding()
        }
    }
}