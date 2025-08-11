import XCTest
@testable import Dirt

final class MentionsServiceTests: XCTestCase {
    func testExtractMentions_basic() {
        let text = "Hey @User_one and @second.user check this out! @a @toolongusernamebecauseitistoobig"
        let mentions = MentionsService.shared.extractMentions(from: text)
        XCTAssertEqual(mentions, ["user_one", "second.user", "a"]) // filters invalid/too long
    }

    func testExtractMentions_none() {
        XCTAssertTrue(MentionsService.shared.extractMentions(from: "no mentions here").isEmpty)
    }
}
