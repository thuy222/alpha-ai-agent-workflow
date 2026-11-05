// Giữ máy không ngủ và giữ trạng thái Active (Slack/Teams) bằng cách
// di chuyển chuột / cuộn ngẫu nhiên. Bỏ qua khi người dùng đang tự dùng máy.
//
// Chạy: swift run (ở thư mục gốc alpha-fullstack)        Dừng: Ctrl+C
// Dọn file build: swift package reset

import CoreGraphics
import Foundation
import IOKit.pwr_mgt

// MARK: - Cấu hình

let minInterval: Double = 1      // giây
let maxInterval: Double = 20     // giây, luôn < 60
let minDistance: Double = 50     // pixel
let maxDistance: Double = 250    // pixel
let userIdleThreshold: Double = 10  // giây; có phím/click/cuộn gần hơn mức này => coi là đang dùng máy
let positionTolerance: Double = 2   // pixel; chuột lệch quá mức này so với lần trước => người dùng đã di chuột
let runDuration: Double = 3 * 60 * 60  // giây; tự động dừng sau 3 giờ
let scrollChance: Double = 0.3      // xác suất mỗi lượt sẽ cuộn thay vì di chuột (0 = tắt cuộn)
let minScrollLines: Int = 2         // tổng số dòng cuộn mỗi lượt được random trong khoảng này
let maxScrollLines: Int = 12        // (cuộn xuống rồi cuộn lên lại đúng chừng đó)
let maxLinesPerTick: Int = 3        // mỗi nấc cuộn random 1...maxLinesPerTick dòng

// MARK: - Quyền Accessibility

if !CGPreflightPostEventAccess() {
    CGRequestPostEventAccess()
    print("""
    ⚠️  Chưa có quyền điều khiển chuột.
        Vào System Settings → Privacy & Security → Accessibility,
        bật cho app Terminal bạn đang dùng, rồi chạy lại `swift run`.
    """)
    exit(1)
}

// MARK: - Giữ máy không ngủ

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

// MARK: - Chuột

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

/// Di chuyển mượt (ease-in-out). Trả về false nếu người dùng chen vào giữa chừng.
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

/// Cuộn xuống một số dòng ngẫu nhiên rồi cuộn lên lại đúng chừng đó để nội dung không bị lệch.
/// Mỗi nấc cuộn cũng có số dòng ngẫu nhiên, chiều xuống và chiều lên random độc lập.
/// Dừng lại nếu người dùng di chuột giữa chừng (vẫn cuộn trả lại phần đã cuộn).
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

// MARK: - Phát hiện người dùng đang dùng máy

/// Thời điểm chương trình tự cuộn lần cuối.
var lastOwnScroll = Date.distantPast

/// Số giây kể từ lần cuối người dùng gõ phím / click / cuộn.
/// Cuộn do chương trình tự gửi có thể bị tính vào scrollWheel, nên chỉ coi là
/// người dùng cuộn khi lần cuộn gần nhất mới hơn lần tự cuộn của chương trình.
func secondsSinceUserInput() -> Double {
    let types: [CGEventType] = [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown,
                                .otherMouseDown, .leftMouseDragged]
    var result = types.map { CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: $0) }.min() ?? .infinity
    let scroll = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .scrollWheel)
    if scroll < -lastOwnScroll.timeIntervalSinceNow - 0.5 { result = min(result, scroll) }
    return result
}

// MARK: - Vòng lặp chính

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
