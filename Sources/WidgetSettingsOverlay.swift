import SwiftUI

// MARK: - Widget Settings Overlay

struct WidgetSettingsOverlay: View {
    @Binding var showSettings: Bool
    @ObservedObject var controller: WidgetWindowController

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Widget Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSettings = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.15))

            ScrollView {
                VStack(spacing: 16) {
                    // Position Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Position")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(WidgetWindowController.WidgetPosition.allCases, id: \.self) { position in
                                PositionButton(
                                    position: position,
                                    isSelected: controller.widgetPosition == position
                                ) {
                                    controller.setPosition(position)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 16)

                    // Style Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 16)

                        VStack(spacing: 8) {
                            ForEach(WidgetWindowController.WidgetStyle.allCases, id: \.self) { style in
                                StyleButton(
                                    style: style,
                                    isSelected: controller.widgetStyle == style
                                ) {
                                    controller.setStyle(style)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 16)

                    // Always Show Toggle
                    Toggle(isOn: Binding(
                        get: { controller.alwaysShow },
                        set: { controller.alwaysShow = $0 }
                    )) {
                        Text("Always Show Widget")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Position Button

private struct PositionButton: View {
    let position: WidgetWindowController.WidgetPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))

                Text(shortLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch position {
        case .topLeft: return "arrow.up.left"
        case .topRight: return "arrow.up.right"
        case .bottomLeft: return "arrow.down.left"
        case .bottomRight: return "arrow.down.right"
        case .center: return "circle"
        }
    }

    private var shortLabel: String {
        switch position {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .center: return "Center"
        }
    }
}

// MARK: - Style Button

private struct StyleButton: View {
    let style: WidgetWindowController.WidgetStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .frame(width: 20)

                Text(style.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .white.opacity(0.7))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            }
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch style {
        case .standard: return "square.fill"
        case .compact: return "rectangle.fill"
        case .circular: return "circle.fill"
        case .detailed: return "square.grid.2x2.fill"
        }
    }
}
