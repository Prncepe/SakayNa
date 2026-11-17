import SwiftUI

struct PillField: View {
    @Environment(\.palette) private var palette
    var label: String?
    var placeholder: String = ""
    var prefix: String?
    var systemImage: String?
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    @Binding var text: String
    var error: String? = nil
    var trailing: (() -> AnyView)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.muted)
                    .padding(.leading, 8)
            }
            HStack(spacing: 12) {
                if let prefix {
                    Text(prefix)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.text.opacity(0.8))
                }
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(palette.muted)
                        .frame(width: 18)
                }
                Group {
                    if isSecure {
                        SecureField("", text: $text, prompt: prompt)
                    } else {
                        TextField("", text: $text, prompt: prompt)
                            .keyboardType(keyboard)
                            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                            .autocorrectionDisabled(keyboard == .emailAddress || keyboard == .phonePad)
                    }
                }
                .font(.system(size: 15))
                .foregroundStyle(palette.text)
                if let trailing {
                    trailing()
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(palette.fieldFill)
            .overlay(Capsule().stroke(error == nil ? palette.border : palette.danger, lineWidth: 1))
            .clipShape(Capsule())

            if let error, !error.isEmpty {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.danger)
                    .padding(.leading, 8)
            }
        }
    }

    private var prompt: Text {
        Text(placeholder)
            .font(.system(size: 15))
            .foregroundColor(palette.placeholder)
    }
}
