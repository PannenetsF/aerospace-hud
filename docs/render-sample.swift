// Offscreen renderer for the aerospace-hud README sample image.
// Reuses the exact colors, sizes, corner radii and fonts from
// workspace_indicator.swift so the mockup is faithful to real rendering.
// Uses stock system app icons (no private/desktop content).
import AppKit

let scale: CGFloat = 2 // render @2x for crisp README display
let W = 900, H = 320

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no ctx") }

// --- Backdrop: a muted gruvbox-ish gradient standing in for a wallpaper, with
//     two faint tiled "windows" so the HUD has context to sit on.
let bg = NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.18, alpha: 1),
    NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.13, alpha: 1),
])!
bg.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

func tile(_ r: NSRect, _ c: NSColor) {
    c.setFill()
    NSBezierPath(roundedRect: r, xRadius: 8, yRadius: 8).fill()
    NSColor.white.withAlphaComponent(0.05).setStroke()
    let p = NSBezierPath(roundedRect: r, xRadius: 8, yRadius: 8)
    p.lineWidth = 1
    p.stroke()
}
// Two tiled windows with an 8px gap, echoing the recommended gaps setting.
tile(NSRect(x: 16, y: 16, width: (W - 16 * 2 - 8) / 2, height: H - 32),
     NSColor(calibratedRed: 0.13, green: 0.14, blue: 0.16, alpha: 1))
tile(NSRect(x: 16 + (W - 16 * 2 - 8) / 2 + 8, y: 16, width: (W - 16 * 2 - 8) / 2, height: H - 32),
     NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1))

// --- Floating indicator panel (IndicatorView), top-left with a 12px margin.
let workspaces = ["1", "2", "3", "4", "5"]
let selected = "2"
let iconApps = [
    "/System/Applications/Utilities/Terminal.app",
    "/System/Applications/Notes.app",
    "/System/Applications/Music.app",
    "/System/Applications/Preview.app",
]

// Measure width the same way position(panel:) does.
var wsWidth: CGFloat = 0
for ws in workspaces { wsWidth += (ws.count > 1 ? 30 : 24) }
wsWidth += CGFloat(max(workspaces.count - 1, 0) * 2)
let iconCount = iconApps.count
let iconWidth = CGFloat(iconCount * 20 + max(iconCount - 1, 0) * 2)
let panelW = 12 + wsWidth + (iconCount > 0 ? 5 : 0) + iconWidth
let panelH: CGFloat = 32
let panelX: CGFloat = 16 + 12
let panelY = CGFloat(H) - panelH - 12 - 8

let panelRect = NSRect(x: panelX, y: panelY, width: max(panelW, 76), height: panelH)
NSColor.black.withAlphaComponent(0.16).setFill()
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 10, yRadius: 10)
panelPath.fill()
NSColor.white.withAlphaComponent(0.07).setStroke()
panelPath.lineWidth = 1
panelPath.stroke()

// Workspace chips.
var cx = panelRect.minX + 6
for ws in workspaces {
    let chipW: CGFloat = ws.count > 1 ? 30 : 24
    let chipRect = NSRect(x: cx, y: panelRect.midY - 12, width: chipW, height: 24)
    let isSel = ws == selected
    if isSel {
        NSColor.white.withAlphaComponent(0.16).setFill()
        NSBezierPath(roundedRect: chipRect, xRadius: 8, yRadius: 8).fill()
    }
    let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: isSel ? .semibold : .medium)
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white.withAlphaComponent(isSel ? 0.95 : 0.44),
        .paragraphStyle: para,
    ]
    let s = NSAttributedString(string: ws, attributes: attrs)
    let ts = s.size()
    s.draw(in: NSRect(x: chipRect.midX - ts.width / 2, y: chipRect.midY - ts.height / 2 - 0.5, width: ts.width, height: ts.height))
    cx += chipW + 2
}

// App icons.
cx += 5 - 2
for app in iconApps {
    let icon = NSWorkspace.shared.icon(forFile: app)
    icon.size = NSSize(width: 20, height: 20)
    let r = NSRect(x: cx, y: panelRect.midY - 10, width: 20, height: 20)
    icon.draw(in: r, from: .zero, operation: .sourceOver, fraction: 0.68)
    cx += 20 + 2
}

// --- Center HUD (CenterHudView) shown on a workspace switch.
let hudSize = NSSize(width: 120, height: 120)
let hudRect = NSRect(x: CGFloat(W) / 2 - hudSize.width / 2,
                     y: CGFloat(H) / 2 - hudSize.height / 2,
                     width: hudSize.width, height: hudSize.height)
NSColor.black.withAlphaComponent(0.30).setFill()
let hudPath = NSBezierPath(roundedRect: hudRect, xRadius: 20, yRadius: 20)
hudPath.fill()
NSColor.white.withAlphaComponent(0.10).setStroke()
hudPath.lineWidth = 1
hudPath.stroke()

let hudFont = NSFont.monospacedDigitSystemFont(ofSize: 46, weight: .semibold)
let hpara = NSMutableParagraphStyle(); hpara.alignment = .center
let hattrs: [NSAttributedString.Key: Any] = [
    .font: hudFont,
    .foregroundColor: NSColor.white.withAlphaComponent(0.92),
    .paragraphStyle: hpara,
]
let hs = NSAttributedString(string: selected, attributes: hattrs)
let hts = hs.size()
hs.draw(in: NSRect(x: hudRect.midX - hts.width / 2, y: hudRect.midY - hts.height / 2 - 1, width: hts.width, height: hts.height))

image.unlockFocus()

// --- Encode to PNG at @2x.
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else { fatalError("no tiff") }
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
let out = CommandLine.arguments.dropFirst().first ?? "sample.png"
try! png.write(to: URL(fileURLWithPath: out))
_ = ctx
print("wrote \(out)")
