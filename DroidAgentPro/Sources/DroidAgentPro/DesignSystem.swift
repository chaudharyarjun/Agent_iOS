import SwiftUI

// MARK: - Colors
extension Color {
    static let bg       = Color(hex: "07090d")
    static let bg2      = Color(hex: "0b0e14")
    static let bg3      = Color(hex: "0f1318")
    static let border   = Color(hex: "151e2a")
    static let border2  = Color(hex: "1e2d3d")
    static let textMuted = Color(hex: "3a4a5a")
    static let textDim   = Color(hex: "1e2a38")
    static let accent    = Color(hex: "00ff88")
    static let accentBlue = Color(hex: "00aaff")
}

// MARK: - Section Title
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(.textMuted)
            .kerning(2.5)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.border).frame(height: 1)
            }
    }
}

// MARK: - Card
struct AppCard<Content: View>: View {
    var accent: Color? = nil
    var padding: CGFloat = 14
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .background(Color.bg2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent ?? Color.border, lineWidth: accent != nil ? 1 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - AppButton
struct AppButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyle2 = .green
    var isSmall: Bool = false
    var isFullWidth: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum ButtonStyle2 { case green, red, blue, dim }

    private var fg: Color {
        switch style {
        case .green: return .accent
        case .red:   return Color(hex: "ff2d55")
        case .blue:  return Color(hex: "00aaff")
        case .dim:   return .textMuted
        }
    }
    private var bg: Color {
        switch style {
        case .green: return Color(hex: "00ff88").opacity(0.1)
        case .red:   return Color(hex: "ff2d55").opacity(0.1)
        case .blue:  return Color(hex: "00aaff").opacity(0.1)
        case .dim:   return Color.clear
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon { Text(icon).font(.system(size: isSmall ? 11 : 13)) }
                Text(title.uppercased())
                    .font(.system(size: isSmall ? 10 : 11, weight: .bold, design: .monospaced))
                    .kerning(1)
            }
            .foregroundColor(isDisabled ? .textMuted : fg)
            .padding(.vertical, isSmall ? 7 : 10)
            .padding(.horizontal, isSmall ? 12 : 16)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(fg.opacity(isDisabled ? 0.2 : 0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isDisabled ? 0.5 : 1)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Severity Badge
struct SeverityBadge: View {
    let severity: Severity
    var body: some View {
        Text(severity.rawValue)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(severity.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(severity.color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Tag
struct TagView: View {
    let text: String
    var color: Color = .accent
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.25), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: Int
    let label: String
    let color: Color
    var size: StatBoxSize = .large
    enum StatBoxSize { case large, small }

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: size == .large ? 28 : 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.textMuted)
                .kerning(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, size == .large ? 14 : 12)
        .background(Color.bg3)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    let text: String
    var color: Color = .accent
    var animate: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color)
                .frame(width: 5, height: 5)
                .opacity(animate ? 1 : 1)
                .animation(animate ? .easeInOut(duration: 0.6).repeatForever() : .default, value: animate)
            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .kerning(0.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(Capsule())
    }
}

// MARK: - LabeledField
struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.textMuted)
                .kerning(2)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.primary)
            .padding(11)
            .background(Color.white.opacity(0.03))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border2, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.border)
                RoundedRectangle(cornerRadius: 2).fill(color)
                    .frame(width: g.size.width * max(0, min(1, value)))
                    .animation(.easeOut, value: value)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Event Badge
struct EventBadge: View {
    let type: String
    var color: Color {
        switch type {
        case "http":    return Color(hex: "00aaff")
        case "intent":  return Color(hex: "aa44ff")
        case "crypto":  return Color(hex: "ffcc00")
        case "file":    return Color(hex: "00ff88")
        case "auth":    return Color(hex: "ff2d55")
        default:        return Color(hex: "8888aa")
        }
    }
    var body: some View {
        Text(type.uppercased())
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
