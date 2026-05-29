import XCTest
@testable import NewsApp

final class CardViewHintTests: XCTestCase {

    // hintOpacity 計算ロジックをテスト用ヘルパーで検証
    // CardView の private computed property を直接テストできないため
    // 同じ計算式を独立した pure function として抽出してテスト

    private func hintOpacity(offset: CGFloat, threshold: CGFloat) -> Double {
        guard abs(offset) >= 5 else { return 0.0 }
        return min(1.0, abs(offset) / (threshold * 0.5))
    }

    // MARK: - FR-003: 5pt 未満は表示しない

    func testOpacity_belowMinimum_isZero() {
        XCTAssertEqual(hintOpacity(offset: 0, threshold: 200), 0.0)
        XCTAssertEqual(hintOpacity(offset: 4, threshold: 200), 0.0)
        XCTAssertEqual(hintOpacity(offset: -4, threshold: 200), 0.0)
    }

    func testOpacity_atMinimumBoundary_isNonZero() {
        XCTAssertGreaterThan(hintOpacity(offset: 5, threshold: 200), 0.0)
        XCTAssertGreaterThan(hintOpacity(offset: -5, threshold: 200), 0.0)
    }

    // MARK: - FR-006: 距離に応じた不透明度変化

    func testOpacity_atHalfThreshold_isFull() {
        // threshold * 0.5 でちょうど 1.0（完全不透明）
        let threshold: CGFloat = 200
        XCTAssertEqual(hintOpacity(offset: threshold * 0.5, threshold: threshold), 1.0, accuracy: 0.001)
    }

    func testOpacity_beyondHalfThreshold_clampedToOne() {
        let threshold: CGFloat = 200
        XCTAssertEqual(hintOpacity(offset: threshold, threshold: threshold), 1.0)
        XCTAssertEqual(hintOpacity(offset: threshold * 2, threshold: threshold), 1.0)
    }

    func testOpacity_linear_between5ptAndHalfThreshold() {
        let threshold: CGFloat = 200
        let quarter = hintOpacity(offset: threshold * 0.25, threshold: threshold)
        XCTAssertGreaterThan(quarter, 0.0)
        XCTAssertLessThan(quarter, 1.0)
        // 50% のオフセットで 1.0 なので、25% なら約 0.5
        XCTAssertEqual(quarter, 0.5, accuracy: 0.05)
    }

    // MARK: - P2 シナリオ: 75% 以上で完全表示

    func testOpacity_atSeventyFivePercent_isFull() {
        let threshold: CGFloat = 200
        // 閾値75% (150pt) は threshold*0.5(100pt) を超えているので clamp されて 1.0
        XCTAssertEqual(hintOpacity(offset: threshold * 0.75, threshold: threshold), 1.0)
    }
}
