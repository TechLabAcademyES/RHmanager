import SwiftUI

struct VistaDiaria: View {
    @EnvironmentObject var calendarioVM: CalendarioViewModel
    @EnvironmentObject var personalVM: PersonalViewModel
    @EnvironmentObject var configuracionVM: ConfiguracionViewModel

    var body: some View {
        List {
            Section(header: Text("Fecha: \(calendarioVM.fechaReferencia.formateada("EEEE, d MMMM yyyy"))")) {
                ForEach(personalVM.empleados) { empleado in
                    let asignacion = calendarioVM.asignacion(empleadoID: empleado.id, fecha: calendarioVM.fechaReferencia)
                    let franja = asignacion?.franjaTurnoID.flatMap { configuracionVM.configuracion.franja(porID: $0) }

                    HStack {
                        VStack(alignment: .leading) {
                            Text(empleado.nombre)
                                .font(.headline)
                            if empleado.esTurnoFijo {
                                Text("Turno Fijo")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()

                        BarraTurno(asignacion: asignacion, franja: franja, mostrarTexto: true, compacta: false)
                            .frame(width: 140)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}