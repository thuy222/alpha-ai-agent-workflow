// Keeps the Mac awake and the Active status (Slack/Teams) on by moving the
// mouse / scrolling at random. Does nothing while the user is using the Mac.
//
// Run: swift run (from the alpha-fullstack root)        Stop: Ctrl+C
// Clean build files: swift package reset

import CoreGraphics
import Foundation
import IOKit.pwr_mgt

// MARK: - Settings

let minInterval: Double = 1      // seconds
let maxInterval: Double = 20     // seconds, always < 60
let minDistance: Double = 50     // pixel
let maxDistance: Double = 250    // pixel
let userIdleThreshold: Double = 10  // seconds; a key/click/scroll more recent than this => the user is active
let positionTolerance: Double = 2   // pixels; the mouse moved more than this since last time => the user moved it
let runDuration: Double = 3 * 60 * 60  // seconds; stops on its own after 3 hours
let scrollChance: Double = 0.3      // chance that a turn scrolls instead of moving the mouse (0 = no scrolling)
let minScrollLines: Int = 2         // total lines scrolled per turn, random within this range
let maxScrollLines: Int = 12        // (scrolls down, then back up by the same amount)
let maxLinesPerTick: Int = 3        // each scroll tick moves a random 1...maxLinesPerTick lines

// MARK: - Accessibility permission

if !CGPreflightPostEventAccess() {
    CGRequestPostEventAccess()
    print("""
    ⚠️  No permission to control the mouse.
        Go to System Settings → Privacy & Security → Accessibility,
        enable it for the terminal app you are using, then run `swift run` again.
    """)
    exit(1)
}

// MARK: - Keep awake

var assertionID: IOPMAssertionID = 0
let assertionOK = IOPMAssertionCreateWithName(
    kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
    IOPMAssertionLevel(kIOPMAssertionLevelOn),
    "CodingMover keep awake" as CFString,
    &assertionID
) == kIOReturnSuccess

func cleanupAndExit() -> Never {
    if assertionOK { IOPMAssertionRelease(assertionID) }
    exit(0)
}

signal(SIGINT, SIG_IGN)
let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigint.setEventHandler { cleanupAndExit() }
sigint.resume()

DispatchQueue.main.asyncAfter(wallDeadline: .now() + runDuration) { cleanupAndExit() }

// MARK: - Mouse

func currentPosition() -> CGPoint {
    CGEvent(source: nil)?.location ?? .zero
}

func screenBounds(containing p: CGPoint) -> CGRect {
    var ids = [CGDirectDisplayID](repeating: 0, count: 16)
    var count: UInt32 = 0
    CGGetDisplaysWithPoint(p, 16, &ids, &count)
    return CGDisplayBounds(count > 0 ? ids[0] : CGMainDisplayID())
}

func post(_ p: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
            mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
}

/// Smooth move (ease-in-out). Returns false if the user takes over midway.
func smoothMove(from a: CGPoint, to b: CGPoint) -> Bool {
    let duration = Double.random(in: 0.2...0.6)
    let steps = max(15, Int(duration * 60))
    var last = a
    for i in 1...steps {
        if distance(currentPosition(), last) > positionTolerance { return false }
        let t = Double(i) / Double(steps)
        let e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        last = CGPoint(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e)
        post(last)
        usleep(useconds_t(duration / Double(steps) * 1_000_000))
    }
    return true
}

func randomTarget(from p: CGPoint) -> CGPoint {
    let r = screenBounds(containing: p).insetBy(dx: 5, dy: 5)
    let angle = Double.random(in: 0..<(2 * .pi))
    let dist = Double.random(in: minDistance...maxDistance)
    return CGPoint(x: min(max(p.x + cos(angle) * dist, r.minX), r.maxX),
                   y: min(max(p.y + sin(angle) * dist, r.minY), r.maxY))
}

/// Scrolls down a random number of lines, then back up by the same amount so the content doesn't shift.
/// Each tick also scrolls a random number of lines, down and up chosen independently.
/// Stops if the user moves the mouse midway (still scrolls back what was scrolled).
func smoothScroll() {
    let total = Int.random(in: minScrollLines...maxScrollLines)
    let start = currentPosition()
    func tick(_ dy: Int32) {
        CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1,
                wheel1: dy, wheel2: 0, wheel3: 0)?.post(tap: .cghidEventTap)
        lastOwnScroll = Date()
        usleep(useconds_t(Double.random(in: 0.04...0.12) * 1_000_000))
    }
    var done = 0
    while done < total && distance(currentPosition(), start) <= positionTolerance {
        let n = min(Int.random(in: 1...maxLinesPerTick), total - done)
        tick(Int32(-n))
        done += n
    }
    usleep(useconds_t(Double.random(in: 0.15...0.4) * 1_000_000))
    while done > 0 {
        let n = min(Int.random(in: 1...maxLinesPerTick), done)
        tick(Int32(n))
        done -= n
    }
}

func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
    hypot(a.x - b.x, a.y - b.y)
}

// MARK: - Detecting that the user is active

/// When the program last scrolled by itself.
var lastOwnScroll = Date.distantPast

/// Seconds since the user last typed / clicked / scrolled.
/// The program's own scrolls may count as scrollWheel events, so a scroll counts
/// as the user's only when it is newer than the program's last scroll.
func secondsSinceUserInput() -> Double {
    let types: [CGEventType] = [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown,
                                .otherMouseDown, .leftMouseDragged]
    var result = types.map { CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: $0) }.min() ?? .infinity
    let scroll = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .scrollWheel)
    if scroll < -lastOwnScroll.timeIntervalSinceNow - 0.5 { result = min(result, scroll) }
    return result
}

// MARK: - Main loop

DispatchQueue.global().async {
    var lastPosition = currentPosition()
    while true {
        Thread.sleep(forTimeInterval: Double.random(in: minInterval...maxInterval))

        let now = currentPosition()
        let userMoved = distance(now, lastPosition) > positionTolerance
        if !userMoved && secondsSinceUserInput() >= userIdleThreshold {
            if Double.random(in: 0..<1) < scrollChance {
                smoothScroll()
            } else {
                _ = smoothMove(from: now, to: randomTarget(from: now))
            }
        }
        lastPosition = currentPosition()
    }
}

dispatchMain()
