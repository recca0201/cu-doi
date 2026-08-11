import Foundation
import UIKit
import XCTest
@testable import Runner

final class GameServicesBridgeTests: XCTestCase {
  func testVersionedChannelsAndNativeLimitsMatchDartContract() {
    XCTAssertEqual(GameServicesContract.methodChannelName, "ban_bua_tuong/game_services/v1")
    XCTAssertEqual(
      GameServicesContract.identityEventChannelName,
      "ban_bua_tuong/game_services/identity_events/v1"
    )
    XCTAssertEqual(GameServicesContract.readTimeoutMilliseconds, 10_000)
    XCTAssertEqual(GameServicesContract.submitTimeoutMilliseconds, 8_000)
    XCTAssertEqual(GameServicesContract.avatarTimeoutMilliseconds, 5_000)
    XCTAssertEqual(GameServicesContract.pageSize, 25)
    XCTAssertEqual(GameServicesContract.maximumRows, 100)
    XCTAssertEqual(GameServicesContract.maximumAvatarBytes, 256 * 1024)
    XCTAssertEqual(GameServicesContract.maximumConcurrentAvatarRequests, 4)
    XCTAssertEqual(GameServicesContract.maximumPendingAvatarRequests, 32)
  }

  func testIdentitySessionRequiresExpectedCurrentPlayerAndOpaqueToken() {
    let expected = ExpectedIdentityBinding(playerID: "player-a", sessionToken: "session-a")

    XCTAssertTrue(
      IdentitySessionVerifier.matches(
        expected: expected,
        currentPlayerID: "player-a",
        recordedPlayerID: "player-a",
        currentSessionToken: "session-a"
      )
    )
    XCTAssertFalse(
      IdentitySessionVerifier.matches(
        expected: expected,
        currentPlayerID: "player-b",
        recordedPlayerID: "player-a",
        currentSessionToken: "session-a"
      )
    )
    XCTAssertFalse(
      IdentitySessionVerifier.matches(
        expected: expected,
        currentPlayerID: "player-a",
        recordedPlayerID: "player-a",
        currentSessionToken: "session-b"
      )
    )
  }

  func testValidFixtureHasExactlyTwentyUniqueNonPlaceholderIdentifiers() throws {
    let catalog = validCatalog()

    XCTAssertNoThrow(
      try catalog.validate(runtimeBundleIdentifier: Self.runtimeBundleIdentifier)
    )
    XCTAssertEqual(Set(catalog.leaderboardIDs.keys), Set(1...20))
    XCTAssertEqual(Set(catalog.leaderboardIDs.values).count, 20)
    for arenaID in 1...20 {
      let value = try XCTUnwrap(catalog.leaderboardIDs[arenaID])
      XCTAssertFalse(LeaderboardCatalog.isPlaceholder(value))
      XCTAssertEqual(value, String(format: "com.cudoi.tests.arena.%02d", arenaID))
    }
  }

  func testCatalogRejectsMissingDuplicatePlaceholderAndApplicationMismatch() {
    let valid = validCatalog()
    var missing = valid.leaderboardIDs
    missing.removeValue(forKey: 20)
    var duplicate = valid.leaderboardIDs
    duplicate[20] = duplicate[19]
    var placeholder = valid.leaderboardIDs
    placeholder[20] = "REPLACE_WITH_GAME_CENTER_LEADERBOARD_ID_ARENA_20"

    let invalidCatalogs = [
      LeaderboardCatalog(
        expectedBundleIdentifier: Self.runtimeBundleIdentifier,
        leaderboardIDs: missing
      ),
      LeaderboardCatalog(
        expectedBundleIdentifier: Self.runtimeBundleIdentifier,
        leaderboardIDs: duplicate
      ),
      LeaderboardCatalog(
        expectedBundleIdentifier: Self.runtimeBundleIdentifier,
        leaderboardIDs: placeholder
      ),
      LeaderboardCatalog(
        expectedBundleIdentifier: "REPLACE_WITH_GAME_CENTER_BUNDLE_IDENTIFIER",
        leaderboardIDs: valid.leaderboardIDs
      ),
    ]

    for catalog in invalidCatalogs {
      XCTAssertThrowsError(
        try catalog.validate(runtimeBundleIdentifier: Self.runtimeBundleIdentifier)
      )
    }
    XCTAssertThrowsError(
      try valid.validate(runtimeBundleIdentifier: "com.cudoi.tests.another-app")
    )
    XCTAssertThrowsError(try valid.identifier(forArena: 0))
    XCTAssertThrowsError(try valid.identifier(forArena: 21))
  }

  func testProductionCatalogDeclaresTwentyExplicitPlaceholdersAndFailsValidation() throws {
    let data = try Data(contentsOf: repositoryURL("Runner/LeaderboardCatalog.plist"))
    let root = try XCTUnwrap(
      try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        as? [String: Any]
    )
    let rawLeaderboards = try XCTUnwrap(
      root[LeaderboardCatalog.leaderboardsKey] as? [String: String]
    )
    let catalog = try LeaderboardCatalog(propertyList: root)

    XCTAssertEqual(rawLeaderboards.count, 20)
    XCTAssertEqual(Set(rawLeaderboards.keys), Set((1...20).map(String.init)))
    XCTAssertTrue(rawLeaderboards.values.allSatisfy(LeaderboardCatalog.isPlaceholder))
    XCTAssertThrowsError(
      try catalog.validate(runtimeBundleIdentifier: Self.runtimeBundleIdentifier)
    )
  }

  func testSilentAuthenticationNeverPresentsAndInteractiveActionPresentsPendingController()
    throws
  {
    let port = FakeAuthenticationPort()
    let presenter = FakeAuthenticationPresenter()
    let coordinator = AuthenticationCoordinator(port: port, presenter: presenter)
    coordinator.initializeSilently()

    let platformController = UIViewController()
    port.emit(viewController: platformController, error: nil)

    XCTAssertEqual(port.handlerInstallCount, 1)
    XCTAssertTrue(presenter.presented.isEmpty)
    XCTAssertNil(coordinator.restoreIdentity())

    var silentResult: Result<NativePlayer, Error>?
    coordinator.authenticate(interactive: false) { silentResult = $0 }
    XCTAssertEqual(
      GameServicesFailureMapper.code(for: try XCTUnwrap(silentResult).failure),
      .unauthenticated
    )
    XCTAssertTrue(presenter.presented.isEmpty)

    var interactiveResult: Result<NativePlayer, Error>?
    coordinator.authenticate(interactive: true) { interactiveResult = $0 }
    XCTAssertEqual(presenter.presented.count, 1)
    XCTAssertTrue(presenter.presented.first === platformController)
    XCTAssertNil(interactiveResult)

    port.authenticated = true
    port.player = makePlayer(id: "local-player")
    port.emit(viewController: nil, error: nil)

    XCTAssertEqual(try XCTUnwrap(interactiveResult).get().playerID, "local-player")
  }

  func testGlobalAndFriendsUseAllTimeTopRangePlusLocalPlayerAndPreserveTies() throws {
    let port = FakeLeaderboardPort()
    port.page = PlatformLeaderboardPage(
      topEntries: [
        makeEntry(rank: 1, playerID: "leader-a", score: 9_000),
        makeEntry(rank: 1, playerID: "leader-b", score: 9_000),
        makeEntry(rank: 3, playerID: "leader-c", score: 8_500),
      ],
      localPlayerEntry: makeEntry(rank: 145, playerID: "local-player", score: 1_200)
    )
    let service = GameServicesService(
      catalog: validCatalog(),
      runtimeBundleIdentifier: Self.runtimeBundleIdentifier,
      leaderboardPort: port
    )

    var globalResult: Result<NativeLeaderboardPage, Error>?
    service.loadLeaderboard(
      arenaID: 7,
      scope: .global,
      limit: 100,
      currentPlayerID: "local-player"
    ) { globalResult = $0 }
    let global = try XCTUnwrap(globalResult).get()

    XCTAssertEqual(port.requests.count, 1)
    XCTAssertEqual(port.requests[0].identifier, "com.cudoi.tests.arena.07")
    XCTAssertEqual(port.requests[0].scope, .global)
    XCTAssertEqual(port.requests[0].timeScope, .allTime)
    XCTAssertEqual(port.requests[0].range.location, 1)
    XCTAssertEqual(port.requests[0].range.length, 100)
    XCTAssertEqual(global.leaders.map(\.rank), [1, 1, 3])
    XCTAssertEqual(global.leaders.map(\.score), [9_000, 9_000, 8_500])
    XCTAssertEqual(global.currentPlayer?.rank, 145)
    XCTAssertTrue(global.currentPlayer?.isCurrentPlayer == true)

    var friendsResult: Result<NativeLeaderboardPage, Error>?
    service.loadLeaderboard(
      arenaID: 7,
      scope: .friends,
      limit: 100,
      currentPlayerID: "local-player"
    ) { friendsResult = $0 }
    _ = try XCTUnwrap(friendsResult).get()
    XCTAssertEqual(port.requests.count, 2)
    XCTAssertEqual(port.requests[1].scope, .friends)
    XCTAssertEqual(port.requests[1].timeScope, .allTime)
  }

  func testCurrentPlayerInTopRangeIsMarkedOnceAndSeparateRowIsRemoved() throws {
    let port = FakeLeaderboardPort()
    port.page = PlatformLeaderboardPage(
      topEntries: [
        makeEntry(rank: 4, playerID: "local-player", score: 7_500),
        makeEntry(rank: 5, playerID: "another-player", score: 7_000),
      ],
      localPlayerEntry: makeEntry(rank: 4, playerID: "local-player", score: 7_500)
    )
    let service = GameServicesService(
      catalog: validCatalog(),
      runtimeBundleIdentifier: Self.runtimeBundleIdentifier,
      leaderboardPort: port
    )
    var outcome: Result<NativeLeaderboardPage, Error>?

    service.loadLeaderboard(
      arenaID: 1,
      scope: .global,
      limit: 100,
      currentPlayerID: "local-player"
    ) { outcome = $0 }
    let page = try XCTUnwrap(outcome).get()

    XCTAssertEqual(page.leaders.filter(\.isCurrentPlayer).count, 1)
    XCTAssertNil(page.currentPlayer)
  }

  func testSubmitUsesArenaCatalogAndRejectsNonPositiveScores() throws {
    let port = FakeLeaderboardPort()
    let service = GameServicesService(
      catalog: validCatalog(),
      runtimeBundleIdentifier: Self.runtimeBundleIdentifier,
      leaderboardPort: port
    )
    var accepted: Result<Void, Error>?
    service.submitScore(arenaID: 12, score: 2_050) { accepted = $0 }

    try XCTUnwrap(accepted).get()
    XCTAssertEqual(port.submissions.count, 1)
    XCTAssertEqual(port.submissions[0].identifier, "com.cudoi.tests.arena.12")
    XCTAssertEqual(port.submissions[0].score, 2_050)

    var rejected: Result<Void, Error>?
    service.submitScore(arenaID: 12, score: 0) { rejected = $0 }
    XCTAssertEqual(
      GameServicesFailureMapper.code(for: try XCTUnwrap(rejected).failure),
      .permanent
    )
  }

  func testAvatarTokenIsOpaqueEpochBoundAndUIImageBytesAreCapped() throws {
    let source = FakeAvatarSource()
    let registry = AvatarTokenRegistry(tokenFactory: { "opaque-token" })
    let descriptor = try XCTUnwrap(
      registry.register(
        player: NativePlayer(
          playerID: "raw-player-id",
          displayName: "Player",
          avatarSource: source
        ),
        identityEpoch: 7
      )
    )

    XCTAssertNotEqual(descriptor.playerHash, "raw-player-id")
    XCTAssertEqual(descriptor.token, "opaque-token")
    XCTAssertTrue(
      registry.resolve(
        token: descriptor.token,
        identityEpoch: 7,
        playerHash: descriptor.playerHash
      ) === source
    )
    XCTAssertNil(
      registry.resolve(
        token: descriptor.token,
        identityEpoch: 8,
        playerHash: descriptor.playerHash
      )
    )

    let atLimit = Data(count: GameServicesContract.maximumAvatarBytes)
    XCTAssertEqual(try BoundedAvatarEncoder.validate(atLimit), atLimit)
    XCTAssertThrowsError(
      try BoundedAvatarEncoder.validate(
        Data(count: GameServicesContract.maximumAvatarBytes + 1)
      )
    )

    let image = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image {
      context in
      UIColor.systemTeal.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
    }
    XCTAssertLessThanOrEqual(
      try BoundedAvatarEncoder.encode(image).count,
      GameServicesContract.maximumAvatarBytes
    )
  }

  func testAvatarLoaderStartsAtMostFourRequests() {
    let loader = NativeAvatarLoader(maximumConcurrentRequests: 4)
    let sources = (0..<5).map { _ in FakeAvatarSource() }
    for source in sources {
      loader.load(source: source) { _ in }
    }

    XCTAssertEqual(sources.prefix(4).map(\.startCount), [1, 1, 1, 1])
    XCTAssertEqual(sources[4].startCount, 0)
    XCTAssertEqual(loader.physicalInFlightCount, 4)

    sources[0].finish(image: nil, error: nil)
    XCTAssertEqual(sources[4].startCount, 1)
    XCTAssertEqual(loader.physicalInFlightCount, 4)
  }

  func testAvatarTimeoutKeepsPhysicalWorkersBoundedUntilNativeCallbacksReturn() {
    let tracker = AvatarInFlightTracker()
    let loader = NativeAvatarLoader(
      maximumConcurrentRequests: 4,
      maximumPendingRequests: 4,
      timeoutMilliseconds: 20
    )
    let sources = (0..<9).map { _ in FakeAvatarSource(tracker: tracker) }
    let initialTimeouts = expectation(description: "initial logical timeouts")
    initialTimeouts.expectedFulfillmentCount = 4
    let queueRejected = expectation(description: "bounded queue rejection")
    let replacementTimeout = expectation(description: "replacement logical timeout")
    var callbacks = [Int](repeating: 0, count: sources.count)

    for (index, source) in sources.enumerated() {
      loader.load(source: source) { _ in
        callbacks[index] += 1
        if index < 4 {
          initialTimeouts.fulfill()
        } else if index == 4 {
          replacementTimeout.fulfill()
        } else if index == 8 {
          queueRejected.fulfill()
        }
      }
    }

    wait(for: [initialTimeouts, queueRejected], timeout: 1)
    XCTAssertEqual(loader.physicalInFlightCount, 4)
    XCTAssertEqual(loader.pendingRequestCount, 4)
    XCTAssertEqual(tracker.inFlight, 4)
    XCTAssertEqual(tracker.maximumInFlight, 4)
    XCTAssertEqual(sources.prefix(4).map(\.startCount), [1, 1, 1, 1])
    XCTAssertTrue(sources[4...].allSatisfy { $0.startCount == 0 })

    // A timed-out native request still owns its physical worker. Only its
    // eventual GameKit callback may release that slot and start one queued job.
    sources[0].finish(image: nil, error: nil)
    XCTAssertEqual(sources[4].startCount, 1)
    XCTAssertEqual(loader.physicalInFlightCount, 4)
    XCTAssertEqual(tracker.inFlight, 4)
    XCTAssertEqual(tracker.maximumInFlight, 4)

    wait(for: [replacementTimeout], timeout: 1)
    XCTAssertEqual(loader.physicalInFlightCount, 4)
    XCTAssertEqual(sources[5].startCount, 0)

    sources[4].finish(image: nil, error: nil)
    XCTAssertEqual(sources[5].startCount, 1)
    XCTAssertEqual(loader.physicalInFlightCount, 4)
    XCTAssertEqual(tracker.maximumInFlight, 4)
    let startsAfterFirstLateCallback = sources.map(\.startCount)
    sources[4].finish(image: nil, error: nil)
    XCTAssertEqual(sources.map(\.startCount), startsAfterFirstLateCallback)
    XCTAssertEqual(callbacks[0], 1)
    XCTAssertEqual(callbacks[4], 1)
    loader.cancelAll()
  }

  func testAvatarClearCancelsActiveAndPendingExactlyOnce() {
    let loader = NativeAvatarLoader(
      maximumConcurrentRequests: 1,
      maximumPendingRequests: 2,
      timeoutMilliseconds: 5_000
    )
    let sources = (0..<3).map { _ in FakeAvatarSource() }
    let cancelled = expectation(description: "clear callbacks")
    cancelled.expectedFulfillmentCount = 2
    var callbacks = 0
    for source in sources.prefix(2) {
      loader.load(source: source) { _ in
        callbacks += 1
        cancelled.fulfill()
      }
    }

    loader.cancelAll()
    wait(for: [cancelled], timeout: 1)
    XCTAssertEqual(loader.physicalInFlightCount, 1)
    XCTAssertEqual(loader.pendingRequestCount, 0)
    XCTAssertEqual(sources[1].startCount, 0)

    let replacement = expectation(description: "replacement callback")
    loader.load(source: sources[2]) { _ in
      callbacks += 1
      replacement.fulfill()
    }
    XCTAssertEqual(sources[2].startCount, 0)
    XCTAssertEqual(loader.pendingRequestCount, 1)

    sources[0].finish(image: nil, error: nil)
    XCTAssertEqual(sources[2].startCount, 1)
    XCTAssertEqual(loader.physicalInFlightCount, 1)
    sources[0].finish(image: nil, error: nil)
    XCTAssertEqual(sources[2].startCount, 1)
    sources[2].finish(image: nil, error: nil)
    wait(for: [replacement], timeout: 1)
    XCTAssertEqual(loader.physicalInFlightCount, 0)
    XCTAssertEqual(callbacks, 3)
  }

  func testCancelRestrictedConsentRetryableAndPermanentErrorsMapToStableCodes() {
    let cases: [(Error, GameServicesFailureCode)] = [
      (GameServicesNativeError.cancelled, .cancelled),
      (GameServicesNativeError.restricted, .restricted),
      (GameServicesNativeError.friendsConsentUnavailable, .friendsUnavailable),
      (GameServicesNativeError.retryable, .retryable),
      (GameServicesNativeError.invalidRequest, .permanent),
      (GameServicesConfigurationError.invalidCatalog, .permanent),
    ]

    for (error, expected) in cases {
      XCTAssertEqual(GameServicesFailureMapper.code(for: error), expected)
    }
  }

  func testProjectWiresCapabilityResourcesLocalizationAndNeverNativeLeaderboardUI()
    throws
  {
    let project = try String(
      contentsOf: repositoryURL("Runner.xcodeproj/project.pbxproj"),
      encoding: .utf8
    )
    let bridge = try String(
      contentsOf: repositoryURL("Runner/GameServicesBridge.swift"),
      encoding: .utf8
    )
    let entitlementsData = try Data(contentsOf: repositoryURL("Runner/Runner.entitlements"))
    let entitlements = try XCTUnwrap(
      try PropertyListSerialization.propertyList(
        from: entitlementsData,
        options: [],
        format: nil
      ) as? [String: Any]
    )
    let infoData = try Data(contentsOf: repositoryURL("Runner/Info.plist"))
    let info = try XCTUnwrap(
      try PropertyListSerialization.propertyList(from: infoData, options: [], format: nil)
        as? [String: Any]
    )

    XCTAssertTrue(project.contains("GameServicesBridge.swift in Sources"))
    XCTAssertTrue(project.contains("GameServicesBridgeTests.swift in Sources"))
    XCTAssertTrue(project.contains("LeaderboardCatalog.plist in Resources"))
    XCTAssertTrue(project.contains("InfoPlist.strings in Resources"))
    XCTAssertTrue(project.contains("GameKit.framework in Frameworks"))
    XCTAssertTrue(project.contains("com.apple.GameCenter"))
    XCTAssertTrue(project.contains("Validate Game Center Configuration"))
    XCTAssertEqual(entitlements["com.apple.developer.game-center"] as? Bool, true)
    XCTAssertEqual(
      entitlements["com.apple.developer.applesignin"] as? [String],
      ["Default"]
    )
    XCTAssertNotNil(info["NSGKFriendListUsageDescription"] as? String)
    for locale in ["en", "vi"] {
      let localized = try String(
        contentsOf: repositoryURL("Runner/\(locale).lproj/InfoPlist.strings"),
        encoding: .utf8
      )
      XCTAssertTrue(localized.contains("NSGKFriendListUsageDescription"))
    }
    XCTAssertFalse(bridge.contains("GKGameCenterViewController"))
    XCTAssertFalse(bridge.contains("GKLeaderboardViewController"))
  }

  private func validCatalog() -> LeaderboardCatalog {
    LeaderboardCatalog(
      expectedBundleIdentifier: Self.runtimeBundleIdentifier,
      leaderboardIDs: Dictionary(
        uniqueKeysWithValues: (1...20).map {
          ($0, String(format: "com.cudoi.tests.arena.%02d", $0))
        }
      )
    )
  }

  private func repositoryURL(_ relativePath: String) -> URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent(relativePath)
  }

  private func makePlayer(id: String) -> NativePlayer {
    NativePlayer(playerID: id, displayName: "Player \(id)", avatarSource: nil)
  }

  private func makeEntry(rank: Int, playerID: String, score: Int64) -> NativeScoreEntry {
    NativeScoreEntry(rank: rank, player: makePlayer(id: playerID), score: score)
  }

  private static let runtimeBundleIdentifier = "com.cudoi.tests"
}

private extension Result {
  var failure: Failure {
    switch self {
    case .success:
      XCTFail("Expected failure")
      fatalError("Expected failure")
    case .failure(let error):
      return error
    }
  }
}

private final class FakeAuthenticationPort: GameKitAuthenticationPort {
  var authenticated = false
  var player: NativePlayer?
  var handlerInstallCount = 0
  private var handler: ((UIViewController?, Error?) -> Void)?

  var isAuthenticated: Bool { authenticated }
  var currentPlayer: NativePlayer? { player }

  func installAuthenticationHandler(
    _ handler: @escaping (UIViewController?, Error?) -> Void
  ) {
    handlerInstallCount += 1
    self.handler = handler
  }

  func emit(viewController: UIViewController?, error: Error?) {
    handler?(viewController, error)
  }
}

private final class FakeAuthenticationPresenter: AuthenticationPresenting {
  var presented: [UIViewController] = []

  func presentAuthenticationViewController(_ viewController: UIViewController) -> Bool {
    presented.append(viewController)
    return true
  }
}

private final class FakeLeaderboardPort: GameKitLeaderboardPort {
  struct Request {
    let identifier: String
    let scope: NativeLeaderboardScope
    let timeScope: NativeLeaderboardTimeScope
    let range: NSRange
  }

  struct Submission {
    let identifier: String
    let score: Int64
  }

  var page = PlatformLeaderboardPage(topEntries: [], localPlayerEntry: nil)
  var requests: [Request] = []
  var submissions: [Submission] = []

  func loadLeaderboard(
    identifier: String,
    scope: NativeLeaderboardScope,
    timeScope: NativeLeaderboardTimeScope,
    range: NSRange,
    completion: @escaping (Result<PlatformLeaderboardPage, Error>) -> Void
  ) {
    requests.append(
      Request(identifier: identifier, scope: scope, timeScope: timeScope, range: range)
    )
    completion(.success(page))
  }

  func submitScore(
    _ score: Int64,
    leaderboardIdentifier: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    submissions.append(Submission(identifier: leaderboardIdentifier, score: score))
    completion(.success(Void()))
  }
}

private final class AvatarInFlightTracker {
  private(set) var inFlight = 0
  private(set) var maximumInFlight = 0

  func started() {
    inFlight += 1
    maximumInFlight = max(maximumInFlight, inFlight)
  }

  func finished() {
    inFlight -= 1
  }
}

private final class FakeAvatarSource: NativeAvatarSource {
  init(tracker: AvatarInFlightTracker? = nil) {
    self.tracker = tracker
  }

  private let tracker: AvatarInFlightTracker?
  var startCount = 0
  private var callbacks: [((UIImage?, Error?) -> Void)] = []

  func loadSmallPhoto(completion: @escaping (UIImage?, Error?) -> Void) {
    startCount += 1
    tracker?.started()
    callbacks.append(completion)
  }

  func finish(image: UIImage?, error: Error?) {
    guard !callbacks.isEmpty else { return }
    tracker?.finished()
    callbacks.removeFirst()(image, error)
  }
}
