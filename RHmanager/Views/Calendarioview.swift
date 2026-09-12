import SwiftUI

struct CalendarioView: View {
    @EnvironmentObject var calendarioVM: CalendarioViewModel
    @EnvironmentObject var personalVM: PersonalViewModel
    @EnvironmentObject var configuracionVM: ConfiguracionViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("Vista", selection: $calendarioVM.modoVista) {
                    ForEach(ModoVistaCalendario.allCases) { modo in
                        Text(modo.rawValue).tag(modo)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                NavegadorFecha()

                Divider()

                Group {
                    switch calendarioVM.modoVista {
                    case .mensual: VistaMensual()
                    case .semanal: VistaSemanal()
                    case .diaria: VistaDiaria()
                    }
                }
            }
            .navigationTitle("Horario")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        calendarioVM.regenerar()
                    } label: {
                        Label("Reajustar", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}

/// Barra de navegación de fecha (anterior / hoy / siguiente), común a las 3 vistas.
struct NavegadorFecha: View {
    @EnvironmentObject var calendarioVM: CalendarioViewModel

    private var unidad: Calendar.Component {
        switch calendarioVM.modoVista {
        case .mensual: return .month
        case .semanal: return .weekOfYear
        case .diaria: return .day
        }
    }

    private var tituloFecha: String {
        switch calendarioVM.modoVista {
        case .mensual: return calendarioVM.fechaReferencia.formateada("LLLL yyyy").capitalized
        case .semanal:
            let dias = calendarioVM.fechaReferencia.diasDeEstaSemana()
            guard let primero = dias.first, let ultimo = dias.last else { return "" }
            return "\(primero.formateada("d MMM")) – \(ultimo.formateada("d MMM yyyy"))"
        case .diaria: return calendarioVM.fechaReferencia.formateada("EEEE d 'de' MMMM").capitalized
        }
    }

    var body: some View {
        HStack {
            Button { mover(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(tituloFecha).font(.headline)
            Spacer()
            Button { mover(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
        .overlay(alignment: .bottom) {
            Button("Hoy") { calendarioVM.fechaReferencia = Date() }
                .font(.caption)
                .padding(.top, 20)
        }
    }

    private func mover(_ cantidad: Int) {
        if let nueva = Calendar.esLunes.date(byAdding: unidad, value: cantidad, to: calendarioVM.fechaReferencia) {
            calendarioVM.fechaReferencia = nueva
        }
    }
}