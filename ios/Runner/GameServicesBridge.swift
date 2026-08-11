import CryptoKit
import Flutter
import Foundation
import GameKit
import UIKit

// Keep these values in parity with lib/core/leaderboard_limits.dart.
enum GameServicesContract {
  static let methodChannelName = "ban_bua_tuong/game_services/v1"
  static let identityEventChannelName =
    "ban_bua_tuong/game_services/identity_events/v1"

  static let readTimeoutMilliseconds = 10_000
  static let submitTimeoutMilliseconds = 8_000
  static let avatarTimeoutMilliseconds = 5_000

  static let pageSize = 25
  static let maximumRows = 100
  static let maximumAvatarBytes = 256 * 1024
  static let maximumConcurrentAvatarRequests = 4
  static let maximumPendingAvatarRequests = 32
}

enum GameServicesConfigurationError: Error {
  case missingCatalog
  case invalidCatalog
  case applicationIdentifierMismatch
  case unknownArena
}

struct LeaderboardCatalog {
  static let resourceName = "LeaderboardCatalog"
  static let expectedBundleIdentifierKey = "ExpectedBundleIdentifier"
  static let leaderboardsKey = "Leaderboards"

  let expectedBundleIdentifier: String
  let leaderboardIDs: [Int: String]

  init(expectedBundleIdentifier: String, leaderboardIDs: [Int: String]) {
    self.expectedBundleIdentifier = expectedBundleIdentifier
    self.leaderboardIDs = leaderboardIDs
  }

  init(propertyList: [String: Any]) throws {
    guard
      let expectedBundleIdentifier = propertyList[Self.expectedBundleIdentifierKey]
        as? String,
      let rawLeaderboards = propertyList[Self.leaderboardsKey] as? [String: String]
    else {
      throw GameServicesConfigurationError.invalidCatalog
    }

    var parsed: [Int: String] = [:]
    for (rawArenaID, leaderboardID) in rawLeaderboards {
      guard let arenaID = Int(rawArenaID), parsed[arenaID] == nil else {
        throw GameServicesConfigurationError.invalidCatalog
      }
      parsed[arenaID] = leaderboardID
    }
    self.init(
      expectedBundleIdentifier: expectedBundleIdentifier,
      leaderboardIDs: parsed
    )
  }

  static func load(from bundle: Bundle) throws -> LeaderboardCatalog {
    guard
      let url = bundle.url(forResource: resourceName, withExtension: "plist"),
      let data = try? Data(contentsOf: url),
      let root = try? PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      ),
      let propertyList = root as? [String: Any]
    else {
      throw GameServicesConfigurationError.missingCatalog
    }
    return try LeaderboardCatalog(propertyList: propertyList)
  }

  func validate(runtimeBundleIdentifier: String) throws {
    guard
      !Self.isPlaceholder(expectedBundleIdentifier),
      expectedBundleIdentifier == runtimeBundleIdentifier
    else {
      throw GameServicesConfigurationError.applicationIdentifierMismatch
    }

    guard Set(leaderboardIDs.keys) == Set(1...20) else {
      throw GameServicesConfigurationError.invalidCatalog
    }
    let values = leaderboardIDs.values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard
      values.count == 20,
      Set(values).count == 20,
      values.allSatisfy({ !$0.isEmpty && !Self.isPlaceholder($0) })
    else {
      throw GameServicesConfigurationError.invalidCatalog
    }
  }

  func identifier(forArena arenaID: Int) throws -> String {
    guard let identifier = leaderboardIDs[arenaID] else {
      throw GameServicesConfigurationError.unknownArena
    }
    return identifier
  }

  static func isPlaceholder(_ value: String) -> Bool {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized.isEmpty
      || ["replace_with", "placeholder", "changeme", "todo"].contains {
        normalized.contains($0)
      }
  }
}

enum GameServicesNativeError: Error {
  case cancelled
  case restricted
  case friendsConsentUnavailable
  case unauthenticated
  case invalidRequest
  case avatarPayloadTooLarge
  case unsupported
  case retryable
}

enum GameServicesFailureCode: String {
  case cancelled
  case restricted
  case friendsUnavailable = "friends_unavailable"
  case unauthenticated
  case retryable
  case permanent
  case unsupported
}

enum GameServicesFailureMapper {
  static func code(for error: Error) -> GameServicesFailureCode {
    if let native = error as? GameServicesNativeError {
      switch native {
      case .cancelled:
        return .cancelled
      case .restricted:
        return .restricted
      case .friendsConsentUnavailable:
        return .friendsUnavailable
      case .unauthenticated:
        return .unauthenticated
      case .invalidRequest:
        return .permanent
      case .avatarPayloadTooLarge, .retryable:
        return .retryable
      case .unsupported:
        return .unsupported
      }
    }
    if error is GameServicesConfigurationError {
      return .permanent
    }

    let platformError = error as NSError
    guard
      platformError.domain == GKErrorDomain,
      let gameKitCode = GKError.Code(rawValue: platformError.code)
    else {
      return .retryable
    }

    if #available(iOS 14.5, *) {
      switch gameKitCode {
      case .friendListDenied, .friendListRestricted, .friendListDescriptionMissing:
        return .friendsUnavailable
      case .notAuthorized:
        return .restricted
      default:
        break
      }
    }

    switch gameKitCode {
    case .cancelled, .userDenied:
      return .cancelled
    case .parentalControlsBlocked, .underage:
      return .restricted
    case .notAuthenticated, .invalidCredentials:
      return .unauthenticated
    case .gameUnrecognized, .notSupported, .invalidParameter, .invalidPlayer, .scoreNotSet:
      return .permanent
    default:
      return .retryable
    }
  }
}

protocol NativeAvatarSource: AnyObject {
  func loadSmallPhoto(completion: @escaping (UIImage?, Error?) -> Void)
}

final class GameKitAvatarSource: NativeAvatarSource {
  private let player: GKPlayer

  init(player: GKPlayer) {
    self.player = player
  }

  func loadSmallPhoto(completion: @escaping (UIImage?, Error?) -> Void) {
    player.loadPhoto(for: .small, withCompletionHandler: completion)
  }
}

struct NativePlayer {
  let playerID: String
  let displayName: String
  let avatarSource: NativeAvatarSource?
}

struct ExpectedIdentityBinding: Equatable {
  let playerID: String
  let sessionToken: String
}

enum IdentitySessionVerifier {
  static func matches(
    expected: ExpectedIdentityBinding,
    currentPlayerID: String,
    recordedPlayerID: String?,
    currentSessionToken: String?
  ) -> Bool {
    expected.playerID == currentPlayerID
      && recordedPlayerID == currentPlayerID
      && expected.sessionToken == currentSessionToken
  }
}

struct NativeScoreEntry {
  let rank: Int
  let player: NativePlayer
  let score: Int64
  let isCurrentPlayer: Bool

  init(
    rank: Int,
    player: NativePlayer,
    score: Int64,
    isCurrentPlayer: Bool = false
  ) {
    self.rank = rank
    self.player = player
    self.score = score
    self.isCurrentPlayer = isCurrentPlayer
  }

  func markingCurrentPlayer(_ value: Bool) -> NativeScoreEntry {
    NativeScoreEntry(rank: rank, player: player, score: score, isCurrentPlayer: value)
  }
}

enum NativeLeaderboardScope: Equatable {
  case global
  case friends
}

enum NativeLeaderboardTimeScope: Equatable {
  case allTime
}

struct PlatformLeaderboardPage {
  let topEntries: [NativeScoreEntry]
  let localPlayerEntry: NativeScoreEntry?
}

struct NativeLeaderboardPage {
  let leaders: [NativeScoreEntry]
  let currentPlayer: NativeScoreEntry?
}

protocol GameKitAuthenticationPort: AnyObject {
  var isAuthenticated: Bool { get }
  var currentPlayer: NativePlayer? { get }
  func installAuthenticationHandler(
    _ handler: @escaping (UIViewController?, Error?) -> Void
  )
}

protocol GameKitLeaderboardPort: AnyObject {
  func loadLeaderboard(
    identifier: String,
    scope: NativeLeaderboardScope,
    timeScope: NativeLeaderboardTimeScope,
    range: NSRange,
    completion: @escaping (Result<PlatformLeaderboardPage, Error>) -> Void
  )

  func submitScore(
    _ score: Int64,
    leaderboardIdentifier: String,
    completion: @escaping (Result<Void, Error>) -> Void
  )
}

protocol AuthenticationPresenting: AnyObject {
  @discardableResult
  func presentAuthenticationViewController(_ viewController: UIViewController) -> Bool
}

final class ViewControllerAuthenticationPresenter: AuthenticationPresenting {
  private let provider: () -> UIViewController?

  init(provider: @escaping () -> UIViewController?) {
    self.provider = provider
  }

  @discardableResult
  func presentAuthenticationViewController(_ viewController: UIViewController) -> Bool {
    guard let presenter = Self.topViewController(from: provider()) else { return false }
    presenter.present(viewController, animated: true)
    return true
  }

  private static func topViewController(from root: UIViewController?) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = root as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tabs = root as? UITabBarController {
      return topViewController(from: tabs.selectedViewController)
    }
    return root
  }
}

final class AuthenticationCoordinator {
  private let port: GameKitAuthenticationPort
  private weak var presenter: AuthenticationPresenting?
  private var installed = false
  private var pendingViewController: UIViewController?
  private var lastError: Error?
  private var interactiveCompletions: [(Result<NativePlayer, Error>) -> Void] = []

  var stateDidChange: ((NativePlayer?) -> Void)?

  init(port: GameKitAuthenticationPort, presenter: AuthenticationPresenting) {
    self.port = port
    self.presenter = presenter
  }

  func initializeSilently() {
    guard !installed else { return }
    installed = true
    port.installAuthenticationHandler { [weak self] viewController, error in
      let update = { self?.handleAuthenticationUpdate(viewController: viewController, error: error) }
      if Thread.isMainThread {
        update()
      } else {
        DispatchQueue.main.async(execute: update)
      }
    }
  }

  func restoreIdentity() -> NativePlayer? {
    initializeSilently()
    guard port.isAuthenticated else { return nil }
    return port.currentPlayer
  }

  func authenticate(
    interactive: Bool,
    completion: @escaping (Result<NativePlayer, Error>) -> Void
  ) {
    initializeSilently()
    if port.isAuthenticated, let player = port.currentPlayer {
      completion(.success(player))
      return
    }
    guard interactive else {
      completion(.failure(GameServicesNativeError.unauthenticated))
      return
    }

    interactiveCompletions.append(completion)
    if pendingViewController != nil {
      presentPendingController()
    } else if let error = lastError {
      lastError = nil
      completeInteractiveRequests(with: .failure(error))
    }
  }

  private func handleAuthenticationUpdate(viewController: UIViewController?, error: Error?) {
    if let viewController {
      // GameKit may produce this during silent startup. Keep it pending until a
      // Flutter action explicitly asks for interactive authentication.
      pendingViewController = viewController
      if !interactiveCompletions.isEmpty {
        presentPendingController()
      }
      return
    }

    if port.isAuthenticated, let player = port.currentPlayer {
      pendingViewController = nil
      lastError = nil
      stateDidChange?(player)
      completeInteractiveRequests(with: .success(player))
      return
    }

    let terminalError = error ?? GameServicesNativeError.unauthenticated
    lastError = terminalError
    stateDidChange?(nil)
    if !interactiveCompletions.isEmpty {
      completeInteractiveRequests(with: .failure(terminalError))
    }
  }

  private func presentPendingController() {
    guard let viewController = pendingViewController else { return }
    guard presenter?.presentAuthenticationViewController(viewController) == true else {
      completeInteractiveRequests(with: .failure(GameServicesNativeError.retryable))
      return
    }
    pendingViewController = nil
    lastError = nil
  }

  private func completeInteractiveRequests(with outcome: Result<NativePlayer, Error>) {
    let callbacks = interactiveCompletions
    interactiveCompletions.removeAll()
    callbacks.forEach { $0(outcome) }
  }
}

final class SystemGameKitClient: GameKitAuthenticationPort, GameKitLeaderboardPort {
  private let localPlayer = GKLocalPlayer.local

  var isAuthenticated: Bool { localPlayer.isAuthenticated }

  var currentPlayer: NativePlayer? {
    guard localPlayer.isAuthenticated else { return nil }
    return nativePlayer(localPlayer)
  }

  func installAuthenticationHandler(
    _ handler: @escaping (UIViewController?, Error?) -> Void
  ) {
    localPlayer.authenticateHandler = handler
  }

  func loadLeaderboard(
    identifier: String,
    scope: NativeLeaderboardScope,
    timeScope: NativeLeaderboardTimeScope,
    range: NSRange,
    completion: @escaping (Result<PlatformLeaderboardPage, Error>) -> Void
  ) {
    guard #available(iOS 14.0, *) else {
      completion(.failure(GameServicesNativeError.unsupported))
      return
    }

    let loadEntries = { [weak self] in
      guard let self else {
        completion(.failure(GameServicesNativeError.retryable))
        return
      }
      GKLeaderboard.loadLeaderboards(IDs: [identifier]) { leaderboards, error in
        if let error {
          completion(.failure(error))
          return
        }
        guard
          let leaderboard = leaderboards?.first(where: {
            $0.baseLeaderboardID == identifier
          }) ?? leaderboards?.first
        else {
          completion(.failure(GameServicesConfigurationError.invalidCatalog))
          return
        }
        let playerScope: GKLeaderboard.PlayerScope =
          scope == .global ? .global : .friendsOnly
        leaderboard.loadEntries(
          for: playerScope,
          timeScope: .allTime,
          range: range
        ) { localEntry, entries, _, loadError in
          if let loadError {
            completion(.failure(loadError))
            return
          }
          completion(
            .success(
              PlatformLeaderboardPage(
                topEntries: (entries ?? []).map(self.nativeEntry),
                localPlayerEntry: localEntry.map(self.nativeEntry)
              )
            )
          )
        }
      }
    }

    if scope == .friends, #available(iOS 14.5, *) {
      prepareFriendsAccess(completion: { outcome in
        switch outcome {
        case .success:
          loadEntries()
        case .failure(let error):
          completion(.failure(error))
        }
      })
    } else {
      loadEntries()
    }
  }

  func submitScore(
    _ score: Int64,
    leaderboardIdentifier: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard #available(iOS 14.0, *) else {
      completion(.failure(GameServicesNativeError.unsupported))
      return
    }
    guard let platformScore = Int(exactly: score) else {
      completion(.failure(GameServicesNativeError.invalidRequest))
      return
    }
    GKLeaderboard.submitScore(
      platformScore,
      context: 0,
      player: localPlayer,
      leaderboardIDs: [leaderboardIdentifier]
    ) { error in
      if let error {
        completion(.failure(error))
      } else {
        completion(.success(Void()))
      }
    }
  }

  @available(iOS 14.5, *)
  private func prepareFriendsAccess(
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    localPlayer.loadFriendsAuthorizationStatus { [weak self] status, error in
      if let error {
        completion(.failure(error))
        return
      }
      switch status {
      case .authorized:
        completion(.success(Void()))
      case .notDetermined:
        // Accessing friends here triggers Apple's consent UI. This method is
        // reached only from an explicit Friends leaderboard request.
        self?.localPlayer.loadFriends { _, loadError in
          if let loadError {
            completion(.failure(loadError))
          } else {
            completion(.success(Void()))
          }
        }
      case .denied, .restricted:
        completion(.failure(GameServicesNativeError.friendsConsentUnavailable))
      @unknown default:
        completion(.failure(GameServicesNativeError.friendsConsentUnavailable))
      }
    }
  }

  private func nativePlayer(_ player: GKPlayer) -> NativePlayer {
    NativePlayer(
      playerID: player.gamePlayerID,
      displayName: player.displayName,
      avatarSource: GameKitAvatarSource(player: player)
    )
  }

  @available(iOS 14.0, *)
  private func nativeEntry(_ entry: GKLeaderboard.Entry) -> NativeScoreEntry {
    NativeScoreEntry(
      rank: entry.rank,
      player: nativePlayer(entry.player),
      score: Int64(entry.score)
    )
  }
}

final class GameServicesService {
  private let catalog: LeaderboardCatalog
  private let runtimeBundleIdentifier: String
  private let leaderboardPort: GameKitLeaderboardPort

  init(
    catalog: LeaderboardCatalog,
    runtimeBundleIdentifier: String,
    leaderboardPort: GameKitLeaderboardPort
  ) {
    self.catalog = catalog
    self.runtimeBundleIdentifier = runtimeBundleIdentifier
    self.leaderboardPort = leaderboardPort
  }

  func validateConfiguration() throws {
    try catalog.validate(runtimeBundleIdentifier: runtimeBundleIdentifier)
  }

  func loadLeaderboard(
    arenaID: Int,
    scope: NativeLeaderboardScope,
    limit: Int,
    currentPlayerID: String,
    completion: @escaping (Result<NativeLeaderboardPage, Error>) -> Void
  ) {
    do {
      try validateConfiguration()
      guard (1...GameServicesContract.maximumRows).contains(limit) else {
        throw GameServicesNativeError.invalidRequest
      }
      let identifier = try catalog.identifier(forArena: arenaID)
      leaderboardPort.loadLeaderboard(
        identifier: identifier,
        scope: scope,
        timeScope: .allTime,
        range: NSRange(location: 1, length: limit)
      ) { outcome in
        completion(
          outcome.map { page in
            var seen = Set<String>()
            let leaders = page.topEntries.prefix(limit).compactMap { entry -> NativeScoreEntry? in
              guard seen.insert(entry.player.playerID).inserted else { return nil }
              return entry.markingCurrentPlayer(entry.player.playerID == currentPlayerID)
            }
            let currentPlayer = seen.contains(currentPlayerID)
              ? nil
              : page.localPlayerEntry.flatMap { entry in
                entry.player.playerID == currentPlayerID
                  ? entry.markingCurrentPlayer(true)
                  : nil
              }
            return NativeLeaderboardPage(
              leaders: Array(leaders),
              currentPlayer: currentPlayer
            )
          }
        )
      }
    } catch {
      completion(.failure(error))
    }
  }

  func submitScore(
    arenaID: Int,
    score: Int64,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      try validateConfiguration()
      guard score > 0 else { throw GameServicesNativeError.invalidRequest }
      let identifier = try catalog.identifier(forArena: arenaID)
      leaderboardPort.submitScore(
        score,
        leaderboardIdentifier: identifier,
        completion: completion
      )
    } catch {
      completion(.failure(error))
    }
  }
}

struct AvatarDescriptor {
  let identityEpoch: Int64
  let playerHash: String
  let token: String

  func channelMap() -> [String: Any] {
    [
      "platform": "gameCenter",
      "identityEpoch": identityEpoch,
      "playerHash": playerHash,
      "token": token,
    ]
  }
}

final class AvatarTokenRegistry {
  private struct Record {
    let identityEpoch: Int64
    let playerHash: String
    let source: NativeAvatarSource
  }

  private let lock = NSLock()
  private let tokenFactory: () -> String
  private var records: [String: Record] = [:]
  private var tokenOrder: [String] = []
  private let maximumTokens = 256

  init(tokenFactory: @escaping () -> String = { UUID().uuidString }) {
    self.tokenFactory = tokenFactory
  }

  func register(player: NativePlayer, identityEpoch: Int64) -> AvatarDescriptor? {
    guard let source = player.avatarSource else { return nil }
    let playerHash = Self.sha256(player.playerID)
    let token = tokenFactory()

    lock.lock()
    defer { lock.unlock() }
    if records[token] != nil {
      tokenOrder.removeAll { $0 == token }
    }
    while records.count >= maximumTokens, let evicted = tokenOrder.first {
      tokenOrder.removeFirst()
      records.removeValue(forKey: evicted)
    }
    records[token] = Record(
      identityEpoch: identityEpoch,
      playerHash: playerHash,
      source: source
    )
    tokenOrder.append(token)
    return AvatarDescriptor(
      identityEpoch: identityEpoch,
      playerHash: playerHash,
      token: token
    )
  }

  func resolve(token: String, identityEpoch: Int64, playerHash: String) -> NativeAvatarSource? {
    lock.lock()
    defer { lock.unlock() }
    guard
      let record = records[token],
      record.identityEpoch == identityEpoch,
      record.playerHash == playerHash
    else {
      return nil
    }
    tokenOrder.removeAll { $0 == token }
    tokenOrder.append(token)
    return record.source
  }

  func clear() {
    lock.lock()
    records.removeAll()
    tokenOrder.removeAll()
    lock.unlock()
  }

  private static func sha256(_ value: String) -> String {
    SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
  }
}

enum BoundedAvatarEncoder {
  static func validate(
    _ data: Data,
    maximumBytes: Int = GameServicesContract.maximumAvatarBytes
  ) throws -> Data {
    guard data.count <= maximumBytes else {
      throw GameServicesNativeError.avatarPayloadTooLarge
    }
    return data
  }

  static func encode(
    _ image: UIImage,
    maximumBytes: Int = GameServicesContract.maximumAvatarBytes
  ) throws -> Data {
    if let png = image.pngData(), png.count <= maximumBytes {
      return png
    }
    for quality in [0.9, 0.75, 0.6, 0.45, 0.3, 0.2] {
      if let jpeg = image.jpegData(compressionQuality: quality), jpeg.count <= maximumBytes {
        return jpeg
      }
    }
    throw GameServicesNativeError.avatarPayloadTooLarge
  }
}

final class NativeAvatarLoader {
  private final class Job {
    let id = UUID()
    let source: NativeAvatarSource
    let completion: (Result<Data?, Error>) -> Void
    let resultGate = CallbackGate()
    let workerGate = CallbackGate()
    var timeout: DispatchWorkItem?

    init(
      source: NativeAvatarSource,
      completion: @escaping (Result<Data?, Error>) -> Void
    ) {
      self.source = source
      self.completion = completion
    }
  }

  private let lock = NSLock()
  private let maximumConcurrentRequests: Int
  private let maximumPendingRequests: Int
  private let timeoutMilliseconds: Int
  private var activeJobs: [UUID: Job] = [:]
  private var pendingJobs: [Job] = []

  var physicalInFlightCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return activeJobs.count
  }

  var pendingRequestCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return pendingJobs.count
  }

  init(
    maximumConcurrentRequests: Int = GameServicesContract.maximumConcurrentAvatarRequests,
    maximumPendingRequests: Int = GameServicesContract.maximumPendingAvatarRequests,
    timeoutMilliseconds: Int = GameServicesContract.avatarTimeoutMilliseconds
  ) {
    self.maximumConcurrentRequests = maximumConcurrentRequests
    self.maximumPendingRequests = maximumPendingRequests
    self.timeoutMilliseconds = timeoutMilliseconds
  }

  @discardableResult
  func load(
    source: NativeAvatarSource,
    completion: @escaping (Result<Data?, Error>) -> Void
  ) -> () -> Void {
    let job = Job(source: source, completion: completion)
    var startNow = false
    var rejected = false
    lock.lock()
    if activeJobs.count < maximumConcurrentRequests {
      activeJobs[job.id] = job
      startNow = true
    } else if pendingJobs.count < maximumPendingRequests {
      pendingJobs.append(job)
    } else {
      rejected = true
    }
    lock.unlock()

    if rejected {
      job.resultGate.run { completion(.failure(GameServicesNativeError.retryable)) }
    } else if startNow {
      start(job)
    }
    return { [weak self, weak job] in
      guard let self, let job else { return }
      self.cancel(job)
    }
  }

  func cancelAll() {
    let jobs: [Job]
    lock.lock()
    jobs = Array(activeJobs.values) + pendingJobs
    pendingJobs.removeAll()
    lock.unlock()
    jobs.forEach {
      completeLogically($0, with: .failure(GameServicesNativeError.retryable))
    }
  }

  private func start(_ job: Job) {
    let timeout = DispatchWorkItem { [weak self, weak job] in
      guard let self, let job else { return }
      self.completeLogically(job, with: .failure(GameServicesNativeError.retryable))
    }
    job.timeout = timeout
    DispatchQueue.main.asyncAfter(
      deadline: .now() + .milliseconds(timeoutMilliseconds),
      execute: timeout
    )
    job.source.loadSmallPhoto { [weak self, weak job] image, error in
      guard let self, let job else { return }
      self.nativeCallbackReturned(job, image: image, error: error)
    }
  }

  private func cancel(_ job: Job) {
    var wasPending = false
    var isActive = false
    lock.lock()
    if let index = pendingJobs.firstIndex(where: { $0.id == job.id }) {
      pendingJobs.remove(at: index)
      wasPending = true
    } else {
      isActive = activeJobs[job.id] != nil
    }
    lock.unlock()
    if wasPending || isActive {
      completeLogically(job, with: .failure(GameServicesNativeError.retryable))
    }
  }

  private func completeLogically(_ job: Job, with outcome: Result<Data?, Error>) {
    job.timeout?.cancel()
    job.resultGate.run {
      job.completion(outcome)
    }
  }

  private func nativeCallbackReturned(
    _ job: Job,
    image: UIImage?,
    error: Error?
  ) {
    job.timeout?.cancel()
    job.resultGate.run {
      if let error {
        job.completion(.failure(error))
      } else if let image {
        job.completion(
          Result<Data?, Error> { try BoundedAvatarEncoder.encode(image) }
        )
      } else {
        job.completion(.success(nil))
      }
    }
    job.workerGate.run { [weak self] in
      self?.releasePhysicalWorker(job)
    }
  }

  private func releasePhysicalWorker(_ job: Job) {
    var next: Job?
    lock.lock()
    guard activeJobs.removeValue(forKey: job.id) != nil else {
      lock.unlock()
      return
    }
    if !pendingJobs.isEmpty {
      let candidate = pendingJobs.removeFirst()
      activeJobs[candidate.id] = candidate
      next = candidate
    }
    lock.unlock()
    if let next { start(next) }
  }
}

private final class CallbackGate {
  private let lock = NSLock()
  private var completed = false

  @discardableResult
  func run(_ action: () -> Void) -> Bool {
    lock.lock()
    guard !completed else {
      lock.unlock()
      return false
    }
    completed = true
    lock.unlock()
    action()
    return true
  }
}

final class GameServicesBridge: NSObject, FlutterStreamHandler {
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let catalogResult: Result<LeaderboardCatalog, Error>
  private let runtimeBundleIdentifier: String
  private let authenticationCoordinator: AuthenticationCoordinator
  private let leaderboardPort: GameKitLeaderboardPort
  private let avatarRegistry = AvatarTokenRegistry()
  private let avatarLoader = NativeAvatarLoader()

  private var eventSink: FlutterEventSink?
  private var lastPlayerID: String?
  private var identitySessionToken: String?
  private var lastIdentityPayload: [String: Any]?
  private var identityEpoch: Int64 = 0

  convenience init(
    messenger: FlutterBinaryMessenger,
    bundle: Bundle = .main,
    presenterProvider: @escaping () -> UIViewController?
  ) {
    let client = SystemGameKitClient()
    self.init(
      messenger: messenger,
      catalogResult: Result { try LeaderboardCatalog.load(from: bundle) },
      runtimeBundleIdentifier: bundle.bundleIdentifier ?? "",
      authenticationPort: client,
      leaderboardPort: client,
      presenter: ViewControllerAuthenticationPresenter(provider: presenterProvider)
    )
  }

  init(
    messenger: FlutterBinaryMessenger,
    catalogResult: Result<LeaderboardCatalog, Error>,
    runtimeBundleIdentifier: String,
    authenticationPort: GameKitAuthenticationPort,
    leaderboardPort: GameKitLeaderboardPort,
    presenter: AuthenticationPresenting
  ) {
    methodChannel = FlutterMethodChannel(
      name: GameServicesContract.methodChannelName,
      binaryMessenger: messenger
    )
    eventChannel = FlutterEventChannel(
      name: GameServicesContract.identityEventChannelName,
      binaryMessenger: messenger
    )
    self.catalogResult = catalogResult
    self.runtimeBundleIdentifier = runtimeBundleIdentifier
    self.leaderboardPort = leaderboardPort
    authenticationCoordinator = AuthenticationCoordinator(
      port: authenticationPort,
      presenter: presenter
    )
    super.init()

    authenticationCoordinator.stateDidChange = { [weak self] player in
      if let player {
        _ = self?.recordPlayer(player)
      } else {
        self?.recordSignedOut()
      }
    }
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: GameServicesFailureCode.retryable.rawValue,
            message: nil,
            details: nil
          )
        )
        return
      }
      self.handle(call, result: result)
    }
    eventChannel.setStreamHandler(self)
  }

  func initializeSilently() {
    authenticationCoordinator.initializeSilently()
  }

  func dispose() {
    methodChannel.setMethodCallHandler(nil)
    eventChannel.setStreamHandler(nil)
    eventSink = nil
    avatarRegistry.clear()
    avatarLoader.cancelAll()
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    if let identity = lastIdentityPayload {
      events([
        "kind": "authenticated",
        "epoch": identityEpoch,
        "identity": identity,
      ])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "validateConfiguration":
      do {
        try service().validateConfiguration()
        result(nil)
      } catch {
        replyError(result, error)
      }
    case "restoreIdentity":
      let player = authenticationCoordinator.restoreIdentity()
      result(player.map(recordPlayer))
    case "authenticate":
      handleAuthenticate(call, result: result)
    case "loadLeaderboard":
      handleLoadLeaderboard(call, result: result)
    case "submitScore":
      handleSubmitScore(call, result: result)
    case "loadAvatar":
      handleLoadAvatar(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleAuthenticate(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let interactive = (call.arguments as? [String: Any])?["interactive"] as? Bool ?? false
    runOperation(
      timeoutMilliseconds: GameServicesContract.readTimeoutMilliseconds,
      result: result,
      encode: { [weak self] player in self?.recordPlayer(player) ?? NSNull() }
    ) { [authenticationCoordinator] completion in
      authenticationCoordinator.authenticate(interactive: interactive, completion: completion)
      return nil
    }
  }

  private func handleLoadLeaderboard(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    do {
      let arguments = try requiredArguments(call)
      let expectedIdentity = try requiredIdentityBinding(arguments)
      let arenaID = try requiredInt(arguments, "arenaId")
      let limit = try requiredInt(arguments, "limit")
      let scope: NativeLeaderboardScope
      switch arguments["scope"] as? String {
      case "global": scope = .global
      case "friends": scope = .friends
      default: throw GameServicesNativeError.invalidRequest
      }
      let player = try verifyIdentity(expectedIdentity)
      let service = try service()
      runOperation(
        timeoutMilliseconds: GameServicesContract.readTimeoutMilliseconds,
        result: result,
        verifyBeforeReply: { [weak self] in
          guard let self else { throw GameServicesNativeError.retryable }
          _ = try self.verifyIdentity(expectedIdentity)
        },
        encode: { [weak self] page in self?.encode(page) ?? [:] }
      ) { completion in
        service.loadLeaderboard(
          arenaID: arenaID,
          scope: scope,
          limit: limit,
          currentPlayerID: player.playerID,
          completion: completion
        )
        return nil
      }
    } catch {
      replyError(result, error)
    }
  }

  private func handleSubmitScore(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    do {
      let arguments = try requiredArguments(call)
      let expectedIdentity = try requiredIdentityBinding(arguments)
      let arenaID = try requiredInt(arguments, "arenaId")
      let score = try requiredInt64(arguments, "score")
      _ = try verifyIdentity(expectedIdentity)
      let service = try service()
      runOperation(
        timeoutMilliseconds: GameServicesContract.submitTimeoutMilliseconds,
        result: result,
        verifyBeforeReply: { [weak self] in
          guard let self else { throw GameServicesNativeError.retryable }
          _ = try self.verifyIdentity(expectedIdentity)
        },
        encode: { _ in nil }
      ) { completion in
        service.submitScore(arenaID: arenaID, score: score, completion: completion)
        return nil
      }
    } catch {
      replyError(result, error)
    }
  }

  private func handleLoadAvatar(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    do {
      let arguments = try requiredArguments(call)
      let expectedIdentity = try requiredIdentityBinding(arguments)
      _ = try verifyIdentity(expectedIdentity)
      guard arguments["platform"] as? String == "gameCenter" else {
        throw GameServicesNativeError.invalidRequest
      }
      let epoch = try requiredInt64(arguments, "identityEpoch")
      guard
        let playerHash = arguments["playerHash"] as? String,
        !playerHash.isEmpty,
        let token = arguments["token"] as? String,
        !token.isEmpty
      else {
        throw GameServicesNativeError.invalidRequest
      }
      guard
        let source = avatarRegistry.resolve(
          token: token,
          identityEpoch: epoch,
          playerHash: playerHash
        )
      else {
        result(nil)
        return
      }
      runOperation(
        timeoutMilliseconds: GameServicesContract.avatarTimeoutMilliseconds,
        result: result,
        verifyBeforeReply: { [weak self] in
          guard let self else { throw GameServicesNativeError.retryable }
          _ = try self.verifyIdentity(expectedIdentity)
        },
        encode: { data in
          data.map { FlutterStandardTypedData(bytes: $0) }
        }
      ) { [avatarLoader] completion in
        let cancel = avatarLoader.load(source: source, completion: completion)
        return cancel
      }
    } catch {
      replyError(result, error)
    }
  }

  private func service() throws -> GameServicesService {
    GameServicesService(
      catalog: try catalogResult.get(),
      runtimeBundleIdentifier: runtimeBundleIdentifier,
      leaderboardPort: leaderboardPort
    )
  }

  private func recordPlayer(_ player: NativePlayer) -> [String: Any] {
    let previousPlayerID = lastPlayerID
    let kind: String
    if previousPlayerID == nil {
      identityEpoch += 1
      identitySessionToken = UUID().uuidString
      kind = "authenticated"
    } else if previousPlayerID != player.playerID {
      identityEpoch += 1
      identitySessionToken = UUID().uuidString
      avatarRegistry.clear()
      avatarLoader.cancelAll()
      kind = "accountChanged"
    } else {
      kind = "authenticated"
    }

    lastPlayerID = player.playerID
    let payload = encode(player)
    lastIdentityPayload = payload
    if previousPlayerID != player.playerID {
      eventSink?([
        "kind": kind,
        "epoch": identityEpoch,
        "identity": payload,
      ])
    }
    return payload
  }

  private func recordSignedOut() {
    guard lastPlayerID != nil else { return }
    lastPlayerID = nil
    identitySessionToken = nil
    lastIdentityPayload = nil
    identityEpoch += 1
    avatarRegistry.clear()
    avatarLoader.cancelAll()
    eventSink?([
      "kind": "signedOut",
      "epoch": identityEpoch,
    ])
  }

  private func encode(_ player: NativePlayer) -> [String: Any] {
    [
      "platform": "gameCenter",
      "playerId": player.playerID,
      "displayName": player.displayName,
      "sessionToken": identitySessionToken ?? "",
      "avatar": avatarRegistry.register(
        player: player,
        identityEpoch: identityEpoch
      )?.channelMap() ?? NSNull(),
    ]
  }

  private func encode(_ entry: NativeScoreEntry) -> [String: Any] {
    [
      "rank": entry.rank,
      "playerId": entry.player.playerID,
      "displayName": entry.player.displayName,
      "score": entry.score,
      "isCurrentPlayer": entry.isCurrentPlayer,
      "avatar": avatarRegistry.register(
        player: entry.player,
        identityEpoch: identityEpoch
      )?.channelMap() ?? NSNull(),
    ]
  }

  private func encode(_ page: NativeLeaderboardPage) -> [String: Any] {
    [
      "leaders": page.leaders.map(encode),
      "currentPlayer": page.currentPlayer.map(encode) ?? NSNull(),
    ]
  }

  private func requiredIdentityBinding(
    _ arguments: [String: Any]
  ) throws -> ExpectedIdentityBinding {
    guard
      let playerID = arguments["expectedPlayerId"] as? String,
      !playerID.isEmpty,
      let sessionToken = arguments["identitySessionToken"] as? String,
      !sessionToken.isEmpty
    else {
      throw GameServicesNativeError.unauthenticated
    }
    return ExpectedIdentityBinding(playerID: playerID, sessionToken: sessionToken)
  }

  private func verifyIdentity(
    _ expected: ExpectedIdentityBinding
  ) throws -> NativePlayer {
    guard let player = authenticationCoordinator.restoreIdentity() else {
      recordSignedOut()
      throw GameServicesNativeError.unauthenticated
    }
    guard
      IdentitySessionVerifier.matches(
        expected: expected,
        currentPlayerID: player.playerID,
        recordedPlayerID: lastPlayerID,
        currentSessionToken: identitySessionToken
      )
    else {
      recordIdentityMismatch(player)
      throw GameServicesNativeError.unauthenticated
    }
    return player
  }

  private func recordIdentityMismatch(_ player: NativePlayer) {
    identityEpoch += 1
    identitySessionToken = UUID().uuidString
    avatarRegistry.clear()
    avatarLoader.cancelAll()
    lastPlayerID = player.playerID
    let payload = encode(player)
    lastIdentityPayload = payload
    eventSink?([
      "kind": "accountChanged",
      "epoch": identityEpoch,
      "identity": payload,
    ])
  }

  private func runOperation<T>(
    timeoutMilliseconds: Int,
    result: @escaping FlutterResult,
    verifyBeforeReply: (() throws -> Void)? = nil,
    encode: @escaping (T) throws -> Any?,
    start: (@escaping (Result<T, Error>) -> Void) -> (() -> Void)?
  ) {
    let gate = CallbackGate()
    var cancellation: (() -> Void)?
    let timeout = DispatchWorkItem {
      gate.run {
        cancellation?()
        result(
          FlutterError(
            code: GameServicesFailureCode.retryable.rawValue,
            message: nil,
            details: nil
          )
        )
      }
    }
    DispatchQueue.main.asyncAfter(
      deadline: .now() + .milliseconds(timeoutMilliseconds),
      execute: timeout
    )

    let completion: (Result<T, Error>) -> Void = { [weak self] outcome in
      DispatchQueue.main.async {
        gate.run {
          timeout.cancel()
          guard let self else {
            result(
              FlutterError(
                code: GameServicesFailureCode.retryable.rawValue,
                message: nil,
                details: nil
              )
            )
            return
          }
          switch outcome {
          case .success(let value):
            do {
              try verifyBeforeReply?()
              result(try encode(value))
            } catch {
              self.replyError(result, error)
            }
          case .failure(let error):
            self.replyError(result, error)
          }
        }
      }
    }
    cancellation = start(completion)
  }

  private func replyError(_ result: @escaping FlutterResult, _ error: Error) {
    result(
      FlutterError(
        code: GameServicesFailureMapper.code(for: error).rawValue,
        message: nil,
        details: nil
      )
    )
  }

  private func requiredArguments(_ call: FlutterMethodCall) throws -> [String: Any] {
    guard let arguments = call.arguments as? [String: Any] else {
      throw GameServicesNativeError.invalidRequest
    }
    return arguments
  }

  private func requiredInt(_ arguments: [String: Any], _ key: String) throws -> Int {
    guard let value = arguments[key] as? NSNumber else {
      throw GameServicesNativeError.invalidRequest
    }
    let raw = value.int64Value
    guard let exact = Int(exactly: raw) else {
      throw GameServicesNativeError.invalidRequest
    }
    return exact
  }

  private func requiredInt64(_ arguments: [String: Any], _ key: String) throws -> Int64 {
    guard let value = arguments[key] as? NSNumber else {
      throw GameServicesNativeError.invalidRequest
    }
    return value.int64Value
  }
}
