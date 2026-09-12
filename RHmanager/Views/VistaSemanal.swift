import SwiftUI

struct VistaSemanal: View {
    @EnvironmentObject var calendarioVM: CalendarioViewModel
    @EnvironmentObject var personalVM: PersonalViewModel
    @EnvironmentObject var configuracionVM: ConfiguracionViewModel

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 12) {
                // Cabecera de días
                HStack(spacing: 8) {
                    Text("Empleado")
                        .font(.subheadline.bold())
                        .frame(width: 140, alignment: .leading)

                    ForEach(calendarioVM.diasDeLaSemanaActual, id: \.self) { dia in
                        VStack {
                            Text(dia.formateada("EEE"))
                                .font(.caption.bold())
                            Text(dia.formateada("d MMM"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 110)
                    }
                }

                Divider()

                // Filas de empleados
                ForEach(personalVM.empleados) { empleado in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading) {
                            Text(empleado.nombre)
                                .font(.subheadline.bold())
                            Text("\(Int(empleado.horasContratadas))h")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 140, alignment: .leading)

                        ForEach(calendarioVM.diasDeLaSemanaActual, id: \.self) { dia in
                            let asignacion = calendarioVM.asignacion(empleadoID: empleado.id, fecha: dia)
                            let franja = asignacion?.franjaTurnoID.flatMap { configuracionVM.configuracion.franja(porID: $0) }

                            Menu {
                                Button("Libre") {
                                    calendarioVM.fijarAsignacionManual(empleadoID: empleado.id, fecha: dia, categoria: .libre, franjaID: nil)
                                }

                                Divider()

                                ForEach(configuracionVM.configuracion.turnosMañana + configuracionVM.configuracion.turnosTarde + configuracionVM.configuracion.turnosEspeciales) { t in
                                    Button(t.nombre) {
                                        calendarioVM.fijarAsignacionManual(empleadoID: empleado.id, fecha: dia, categoria: t.categoria, franjaID: t.id)
                                    }
                                }
                            } label: {
                                BarraTurno(asignacion: asignacion, franja: franja, mostrarTexto: true, compacta: false)
                                    .frame(width: 110)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}