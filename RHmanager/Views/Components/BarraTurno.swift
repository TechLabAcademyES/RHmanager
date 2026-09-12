import SwiftUI

struct BarraTurno: View {
    let asignacion: Asignacion?
    let franja: FranjaTurno?
    var mostrarTexto: Bool = true
    var compacta: Bool = false

    private var categoria: CategoriaTurno {
        asignacion?.categoria ?? .libre
    }

    private var titulo: String {
        if let franja = franja {
            return franja.nombre
        }
        return categoria.nombreVisible
    }

    private var subtitulo: String {
        if let franja = franja {
            return "\(franja.franja.inicio.textoFormateado) - \(franja.franja.fin.textoFormateado)"
        }
        return ""
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compacta ? 4 : 8)
                .fill(categoria.color.opacity(0.85))

            if asignacion?.fijadaManualmente == true {
                RoundedRectangle(cornerRadius: compacta ? 4 : 8)
                    .stroke(Color.primary.opacity(0.6), lineWidth: compacta ? 1 : 1.5)
            }

            if mostrarTexto && !compacta {
                VStack(spacing: 2) {
                    Text(titulo)
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .lineLimit(1)

                    if !subtitulo.isEmpty {
                        Text(subtitulo)
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxHeight: compacta ? 20 : 44)
    }
}