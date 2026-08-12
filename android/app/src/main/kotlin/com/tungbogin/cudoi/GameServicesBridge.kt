package com.tungbogin.cudoi

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.games.AuthenticationResult
import com.google.android.gms.games.FriendsResolutionRequiredException
import com.google.android.gms.games.GamesClientStatusCodes
import com.google.android.gms.games.GamesSignInClient
import com.google.android.gms.games.LeaderboardsClient
import com.google.android.gms.games.PageDirection
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.Player
import com.google.android.gms.games.PlayersClient
import com.google.android.gms.games.leaderboard.LeaderboardScore
import com.google.android.gms.games.leaderboard.LeaderboardVariant
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result as FlutterResult
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.LinkedHashMap
import java.util.UUID
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

internal object GameServicesContract {
    const val METHOD_CHANNEL = "ban_bua_tuong/game_services/v1"
    const val IDENTITY_EVENT_CHANNEL = "ban_bua_tuong/game_services/identity_events/v1"

    const val READ_TIMEOUT_MILLIS = 10_000L
    const val SUBMIT_TIMEOUT_MILLIS = 8_000L
    const val AVATAR_TIMEOUT_MILLIS = 5_000L

    const val PAGE_SIZE = 25
    const val MAX_ROWS = 100
    const val MAX_AVATAR_BYTES = 256 * 1024
    const val MAX_AVATAR_REQUESTS = 4
    const val MAX_PENDING_AVATAR_REQUESTS = 32
}

internal class GameServicesConfigurationException(message: String) :
    IllegalStateException(message)

internal data class LeaderboardCatalog(
    val gameServicesProjectId: String,
    val configuredApplicationId: String,
    val leaderboardIds: Map<Int, String>,
) {
    fun validate(runtimeApplicationId: String) {
        if (isPlaceholder(gameServicesProjectId) ||
            !gameServicesProjectId.matches(Regex("[0-9]{6,}"))
        ) {
            throw GameServicesConfigurationException("Invalid Play Games project ID")
        }
        if (isPlaceholder(configuredApplicationId) ||
            configuredApplicationId != runtimeApplicationId
        ) {
            throw GameServicesConfigurationException("Play Games application ID mismatch")
        }
        if (leaderboardIds.keys != (1..20).toSet()) {
            throw GameServicesConfigurationException("Exactly arenas 1 through 20 are required")
        }
        val values = leaderboardIds.values
        if (values.any(::isPlaceholder) || values.toSet().size != 20) {
            throw GameServicesConfigurationException(
                "Leaderboard IDs must be unique production values",
            )
        }
    }

    fun idForArena(arenaId: Int): String = leaderboardIds[arenaId]
        ?: throw GameServicesConfigurationException("Unknown arena ID")

    companion object {
        fun fromResources(context: Context): LeaderboardCatalog {
            val resourceIds = intArrayOf(
                R.string.leaderboard_arena_1,
                R.string.leaderboard_arena_2,
                R.string.leaderboard_arena_3,
                R.string.leaderboard_arena_4,
                R.string.leaderboard_arena_5,
                R.string.leaderboard_arena_6,
                R.string.leaderboard_arena_7,
                R.string.leaderboard_arena_8,
                R.string.leaderboard_arena_9,
                R.string.leaderboard_arena_10,
                R.string.leaderboard_arena_11,
                R.string.leaderboard_arena_12,
                R.string.leaderboard_arena_13,
                R.string.leaderboard_arena_14,
                R.string.leaderboard_arena_15,
                R.string.leaderboard_arena_16,
                R.string.leaderboard_arena_17,
                R.string.leaderboard_arena_18,
                R.string.leaderboard_arena_19,
                R.string.leaderboard_arena_20,
            )
            return LeaderboardCatalog(
                gameServicesProjectId = context.getString(R.string.game_services_project_id),
                configuredApplicationId =
                    context.getString(R.string.play_games_android_application_id),
                leaderboardIds = resourceIds.mapIndexed { index, resourceId ->
                    index + 1 to context.getString(resourceId)
                }.toMap(),
            )
        }

        private fun isPlaceholder(value: String): Boolean {
            val normalized = value.trim().lowercase()
            return normalized.isEmpty() ||
                listOf("replace_with", "placeholder", "todo", "changeme").any {
                    normalized.contains(it)
                }
        }
    }
}

internal data class NativePlayer(
    val playerId: String,
    val displayName: String,
    val avatarUri: String?,
)

internal data class ExpectedIdentityBinding(
    val playerId: String,
    val sessionToken: String,
)

internal object IdentitySessionVerifier {
    fun matches(
        expected: ExpectedIdentityBinding,
        currentPlayerId: String,
        recordedPlayerId: String?,
        currentSessionToken: String?,
    ): Boolean =
        expected.playerId == currentPlayerId &&
            recordedPlayerId == currentPlayerId &&
            expected.sessionToken == currentSessionToken
}

internal interface AuthenticationPort {
    fun isAuthenticated(callback: (Result<Boolean>) -> Unit)
    fun signIn(callback: (Result<Boolean>) -> Unit)
    fun loadCurrentPlayer(callback: (Result<NativePlayer>) -> Unit)
}

internal class AuthenticationCoordinator(
    private val port: AuthenticationPort,
) {
    fun restoreIdentity(callback: (Result<NativePlayer?>) -> Unit) {
        port.isAuthenticated { authentication ->
            authentication.fold(
                onSuccess = { authenticated ->
                    if (!authenticated) {
                        callback(Result.success(null))
                    } else {
                        port.loadCurrentPlayer { player ->
                            callback(player.map { it })
                        }
                    }
                },
                onFailure = { callback(Result.failure(it)) },
            )
        }
    }

    fun authenticate(
        interactive: Boolean,
        callback: (Result<NativePlayer>) -> Unit,
    ) {
        val authenticationCallback: (Result<Boolean>) -> Unit = { authentication ->
            authentication.fold(
                onSuccess = { authenticated ->
                    if (!authenticated) {
                        callback(Result.failure(GameServicesUnauthenticatedException()))
                    } else {
                        port.loadCurrentPlayer(callback)
                    }
                },
                onFailure = { callback(Result.failure(it)) },
            )
        }
        if (interactive) {
            port.signIn(authenticationCallback)
        } else {
            port.isAuthenticated(authenticationCallback)
        }
    }
}

internal class GameServicesUnauthenticatedException : IllegalStateException()

private class PlayGamesAuthenticationPort(activity: Activity) : AuthenticationPort {
    private val signInClient: GamesSignInClient = PlayGames.getGamesSignInClient(activity)
    private val playersClient: PlayersClient = PlayGames.getPlayersClient(activity)

    override fun isAuthenticated(callback: (Result<Boolean>) -> Unit) {
        signInClient.isAuthenticated().addOnCompleteListener { task ->
            completeTask(task.exception, task.isSuccessful) {
                callback(Result.success(task.result?.isAuthenticated == true))
            }.onFailure { callback(Result.failure(it)) }
        }
    }

    override fun signIn(callback: (Result<Boolean>) -> Unit) {
        signInClient.signIn().addOnCompleteListener { task ->
            completeTask(task.exception, task.isSuccessful) {
                callback(Result.success(task.result?.isAuthenticated == true))
            }.onFailure { callback(Result.failure(it)) }
        }
    }

    override fun loadCurrentPlayer(callback: (Result<NativePlayer>) -> Unit) {
        playersClient.currentPlayer.addOnCompleteListener { task ->
            completeTask(task.exception, task.isSuccessful) {
                callback(Result.success(task.result.toNativePlayer()))
            }.onFailure { callback(Result.failure(it)) }
        }
    }

    private inline fun completeTask(
        exception: Exception?,
        successful: Boolean,
        success: () -> Unit,
    ): Result<Unit> = if (successful) {
        runCatching { success() }
    } else {
        Result.failure(exception ?: IllegalStateException("Play Games task failed"))
    }
}

internal enum class NativeLeaderboardScope { GLOBAL, FRIENDS }

internal data class NativeScoreEntry(
    val rank: Long,
    val playerId: String,
    val displayName: String,
    val score: Long,
    val avatarUri: String?,
    val isCurrentPlayer: Boolean = false,
)

internal data class NativeLeaderboardPage(
    val leaders: List<NativeScoreEntry>,
    val currentPlayer: NativeScoreEntry?,
)

internal interface ReleasableScorePage {
    val rows: List<NativeScoreEntry>
    fun release()
}

internal interface LeaderboardPort {
    fun loadTopScores(
        leaderboardId: String,
        scope: NativeLeaderboardScope,
        pageSize: Int,
        callback: (Result<ReleasableScorePage>) -> Unit,
    )

    fun loadMoreScores(
        previousPage: ReleasableScorePage,
        pageSize: Int,
        callback: (Result<ReleasableScorePage>) -> Unit,
    )

    fun loadCurrentPlayerScore(
        leaderboardId: String,
        scope: NativeLeaderboardScope,
        callback: (Result<NativeScoreEntry?>) -> Unit,
    )

    fun submitScoreImmediate(
        leaderboardId: String,
        score: Long,
        callback: (Result<Unit>) -> Unit,
    )
}

internal fun interface Cancellable {
    fun cancel()
}

internal class LeaderboardPageLoader(
    private val port: LeaderboardPort,
) {
    fun load(
        leaderboardId: String,
        scope: NativeLeaderboardScope,
        requestedLimit: Int,
        currentPlayerId: String,
        callback: (Result<NativeLeaderboardPage>) -> Unit,
    ): Cancellable {
        require(requestedLimit in 1..GameServicesContract.MAX_ROWS)
        return LoadOperation(
            port = port,
            leaderboardId = leaderboardId,
            scope = scope,
            requestedLimit = requestedLimit,
            currentPlayerId = currentPlayerId,
            callback = callback,
        ).also { it.start() }
    }

    private class LoadOperation(
        private val port: LeaderboardPort,
        private val leaderboardId: String,
        private val scope: NativeLeaderboardScope,
        private val requestedLimit: Int,
        private val currentPlayerId: String,
        private val callback: (Result<NativeLeaderboardPage>) -> Unit,
    ) : Cancellable {
        private val lock = Any()
        private val leadersByPlayer = LinkedHashMap<String, NativeScoreEntry>()
        private val maxPages =
            (requestedLimit + GameServicesContract.PAGE_SIZE - 1) /
                GameServicesContract.PAGE_SIZE
        private var pageCount = 0
        private var activePage: ReleasableScorePage? = null
        private var finished = false

        fun start() {
            try {
                port.loadTopScores(
                    leaderboardId,
                    scope,
                    minOf(GameServicesContract.PAGE_SIZE, requestedLimit),
                    ::acceptPageResult,
                )
            } catch (error: Throwable) {
                finish(Result.failure(error))
            }
        }

        override fun cancel() {
            val page = synchronized(lock) {
                if (finished) return
                finished = true
                activePage.also { activePage = null }
            }
            page?.release()
        }

        private fun acceptPageResult(outcome: Result<ReleasableScorePage>) {
            outcome.fold(::acceptPage) { finish(Result.failure(it)) }
        }

        private fun acceptPage(page: ReleasableScorePage) {
            val shouldRelease = synchronized(lock) {
                if (finished) {
                    true
                } else {
                    activePage = page
                    false
                }
            }
            if (shouldRelease) {
                page.release()
                return
            }

            try {
                pageCount++
                for (row in page.rows) {
                    if (leadersByPlayer.size >= requestedLimit) break
                    leadersByPlayer.putIfAbsent(
                        row.playerId,
                        row.copy(isCurrentPlayer = row.playerId == currentPlayerId),
                    )
                }
                val needsAnotherPage =
                    pageCount < maxPages &&
                        page.rows.isNotEmpty() &&
                        leadersByPlayer.size < requestedLimit
                if (needsAnotherPage) {
                    try {
                        port.loadMoreScores(
                            page,
                            minOf(
                                GameServicesContract.PAGE_SIZE,
                                requestedLimit - leadersByPlayer.size,
                            ).coerceAtLeast(1),
                        ) { next ->
                            releaseOwned(page)
                            acceptPageResult(next)
                        }
                    } catch (error: Throwable) {
                        releaseOwned(page)
                        finish(Result.failure(error))
                    }
                } else {
                    releaseOwned(page)
                    loadCurrentPlayerIfNeeded()
                }
            } catch (error: Throwable) {
                releaseOwned(page)
                finish(Result.failure(error))
            }
        }

        private fun loadCurrentPlayerIfNeeded() {
            if (leadersByPlayer.containsKey(currentPlayerId)) {
                finish(
                    Result.success(
                        NativeLeaderboardPage(
                            leaders = leadersByPlayer.values.toList(),
                            currentPlayer = null,
                        ),
                    ),
                )
                return
            }
            try {
                port.loadCurrentPlayerScore(leaderboardId, scope) { current ->
                    current.fold(
                        onSuccess = { row ->
                            val separate = row
                                ?.takeIf { it.playerId == currentPlayerId }
                                ?.copy(isCurrentPlayer = true)
                            finish(
                                Result.success(
                                    NativeLeaderboardPage(
                                        leaders = leadersByPlayer.values.toList(),
                                        currentPlayer = separate,
                                    ),
                                ),
                            )
                        },
                        onFailure = { finish(Result.failure(it)) },
                    )
                }
            } catch (error: Throwable) {
                finish(Result.failure(error))
            }
        }

        private fun releaseOwned(page: ReleasableScorePage) {
            synchronized(lock) {
                if (activePage === page) activePage = null
            }
            page.release()
        }

        private fun finish(result: Result<NativeLeaderboardPage>) {
            val page = synchronized(lock) {
                if (finished) return
                finished = true
                activePage.also { activePage = null }
            }
            page?.release()
            callback(result)
        }
    }
}

private class PlayGamesLeaderboardPort(activity: Activity) : LeaderboardPort {
    private val client: LeaderboardsClient = PlayGames.getLeaderboardsClient(activity)

    override fun loadTopScores(
        leaderboardId: String,
        scope: NativeLeaderboardScope,
        pageSize: Int,
        callback: (Result<ReleasableScorePage>) -> Unit,
    ) {
        client.loadTopScores(
            leaderboardId,
            LeaderboardVariant.TIME_SPAN_ALL_TIME,
            scope.collection,
            pageSize,
        ).addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                callback(Result.failure(task.exception ?: taskFailure()))
                return@addOnCompleteListener
            }
            callback(
                runCatching {
                    PlayGamesScorePage(requireNotNull(task.result.get()))
                },
            )
        }
    }

    override fun loadMoreScores(
        previousPage: ReleasableScorePage,
        pageSize: Int,
        callback: (Result<ReleasableScorePage>) -> Unit,
    ) {
        val page = previousPage as? PlayGamesScorePage
            ?: run {
                callback(Result.failure(IllegalArgumentException("Invalid score page")))
                return
            }
        client.loadMoreScores(
            page.raw.scores,
            pageSize,
            PageDirection.NEXT,
        ).addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                callback(Result.failure(task.exception ?: taskFailure()))
                return@addOnCompleteListener
            }
            callback(
                runCatching {
                    PlayGamesScorePage(requireNotNull(task.result.get()))
                },
            )
        }
    }

    override fun loadCurrentPlayerScore(
        leaderboardId: String,
        scope: NativeLeaderboardScope,
        callback: (Result<NativeScoreEntry?>) -> Unit,
    ) {
        client.loadCurrentPlayerLeaderboardScore(
            leaderboardId,
            LeaderboardVariant.TIME_SPAN_ALL_TIME,
            scope.collection,
        ).addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                callback(Result.failure(task.exception ?: taskFailure()))
                return@addOnCompleteListener
            }
            callback(runCatching { task.result.get()?.toNativeScoreEntry() })
        }
    }

    override fun submitScoreImmediate(
        leaderboardId: String,
        score: Long,
        callback: (Result<Unit>) -> Unit,
    ) {
        client.submitScoreImmediate(leaderboardId, score).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                callback(Result.success(Unit))
            } else {
                callback(Result.failure(task.exception ?: taskFailure()))
            }
        }
    }

    private class PlayGamesScorePage(
        val raw: LeaderboardsClient.LeaderboardScores,
    ) : ReleasableScorePage {
        private val released = AtomicBoolean(false)
        override val rows: List<NativeScoreEntry> = buildList {
            val scores = raw.scores
            for (index in 0 until scores.count) {
                add(scores[index].toNativeScoreEntry())
            }
        }

        override fun release() {
            if (released.compareAndSet(false, true)) raw.release()
        }
    }

    private val NativeLeaderboardScope.collection: Int
        get() = when (this) {
            NativeLeaderboardScope.GLOBAL -> LeaderboardVariant.COLLECTION_PUBLIC
            NativeLeaderboardScope.FRIENDS -> LeaderboardVariant.COLLECTION_FRIENDS
        }

    private fun taskFailure(): Throwable = IllegalStateException("Play Games task failed")
}

internal class GameServicesService(
    private val catalog: LeaderboardCatalog,
    private val runtimeApplicationId: String,
    private val leaderboardPort: LeaderboardPort,
) {
    fun submitScore(
        arenaId: Int,
        score: Long,
        callback: (Result<Unit>) -> Unit,
    ) {
        require(score > 0L)
        catalog.validate(runtimeApplicationId)
        leaderboardPort.submitScoreImmediate(catalog.idForArena(arenaId), score, callback)
    }
}

internal enum class GameServicesFailureCode(val channelCode: String) {
    CANCELLED("cancelled"),
    RESTRICTED("restricted"),
    FRIENDS_UNAVAILABLE("friends_unavailable"),
    UNAUTHENTICATED("unauthenticated"),
    RETRYABLE("retryable"),
    PERMANENT("permanent"),
}

internal object GameServicesFailureMapper {
    fun fromThrowable(error: Throwable): GameServicesFailureCode {
        var current: Throwable? = error
        while (current != null) {
            if (current is FriendsResolutionRequiredException) {
                return GameServicesFailureCode.FRIENDS_UNAVAILABLE
            }
            if (current is GameServicesUnauthenticatedException) {
                return GameServicesFailureCode.UNAUTHENTICATED
            }
            if (current is GameServicesConfigurationException ||
                current is IllegalArgumentException
            ) {
                return GameServicesFailureCode.PERMANENT
            }
            if (current is ApiException) return fromStatus(current.statusCode)
            current = current.cause
        }
        return GameServicesFailureCode.RETRYABLE
    }

    fun fromStatus(
        statusCode: Int,
        friendsResolutionRequired: Boolean = false,
    ): GameServicesFailureCode {
        if (friendsResolutionRequired || statusCode == GamesClientStatusCodes.CONSENT_REQUIRED) {
            return GameServicesFailureCode.FRIENDS_UNAVAILABLE
        }
        return when (statusCode) {
            CommonStatusCodes.CANCELED -> GameServicesFailureCode.CANCELLED
            CommonStatusCodes.INVALID_ACCOUNT -> GameServicesFailureCode.RESTRICTED
            CommonStatusCodes.SIGN_IN_REQUIRED -> GameServicesFailureCode.UNAUTHENTICATED
            GamesClientStatusCodes.APP_MISCONFIGURED,
            GamesClientStatusCodes.LICENSE_CHECK_FAILED,
            GamesClientStatusCodes.GAME_NOT_FOUND,
            CommonStatusCodes.DEVELOPER_ERROR,
            -> GameServicesFailureCode.PERMANENT
            else -> GameServicesFailureCode.RETRYABLE
        }
    }
}

internal data class AvatarDescriptor(
    val platform: String,
    val identityEpoch: Long,
    val playerHash: String,
    val token: String,
) {
    fun toChannelMap(): Map<String, Any> = mapOf(
        "platform" to platform,
        "identityEpoch" to identityEpoch,
        "playerHash" to playerHash,
        "token" to token,
    )
}

internal class AvatarTokenRegistry(
    private val tokenFactory: () -> String = { UUID.randomUUID().toString() },
) {
    private data class Record(
        val epoch: Long,
        val playerHash: String,
        val uri: String,
    )

    private val records = object : LinkedHashMap<String, Record>(256, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Record>?): Boolean =
            size > MAX_TOKENS
    }

    @Synchronized
    fun register(
        playerId: String,
        imageUri: String?,
        identityEpoch: Long,
    ): AvatarDescriptor? {
        if (imageUri.isNullOrBlank()) return null
        val playerHash = sha256(playerId)
        val token = tokenFactory()
        records[token] = Record(identityEpoch, playerHash, imageUri)
        return AvatarDescriptor("playGames", identityEpoch, playerHash, token)
    }

    @Synchronized
    fun resolve(token: String, identityEpoch: Long, playerHash: String): String? {
        val record = records[token] ?: return null
        return record.uri.takeIf {
            record.epoch == identityEpoch && record.playerHash == playerHash
        }
    }

    @Synchronized
    fun clear() {
        records.clear()
    }

    private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray(Charsets.UTF_8))
        .joinToString("") { byte -> "%02x".format(byte) }

    private companion object {
        const val MAX_TOKENS = 256
    }
}

internal class AvatarPayloadTooLargeException : IllegalStateException()
internal class AvatarRequestTimeoutException : IllegalStateException()

internal object BoundedAvatarReader {
    fun read(
        input: InputStream,
        maximumBytes: Int = GameServicesContract.MAX_AVATAR_BYTES,
    ): ByteArray {
        val output = ByteArrayOutputStream(minOf(maximumBytes, 16 * 1024))
        val buffer = ByteArray(8 * 1024)
        var total = 0
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            total += read
            if (total > maximumBytes) throw AvatarPayloadTooLargeException()
            output.write(buffer, 0, read)
        }
        return output.toByteArray()
    }
}

internal class NativeAvatarLoader(
    private val registry: AvatarTokenRegistry,
    private val readAvatar: (String) -> ByteArray,
    private val executor: ThreadPoolExecutor = ThreadPoolExecutor(
        GameServicesContract.MAX_AVATAR_REQUESTS,
        GameServicesContract.MAX_AVATAR_REQUESTS,
        0L,
        TimeUnit.MILLISECONDS,
        ArrayBlockingQueue(GameServicesContract.MAX_PENDING_AVATAR_REQUESTS),
        ThreadPoolExecutor.AbortPolicy(),
    ),
    private val timeoutScheduler: ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor(),
    private val timeoutMillis: Long = GameServicesContract.AVATAR_TIMEOUT_MILLIS,
) {
    private val jobLock = Any()
    private val activeOperations = mutableSetOf<Cancellable>()

    constructor(
        context: Context,
        registry: AvatarTokenRegistry,
    ) : this(
        registry = registry,
        readAvatar = { rawUri -> readUri(context, Uri.parse(rawUri)) },
    )

    fun load(
        token: String,
        identityEpoch: Long,
        playerHash: String,
        callback: (Result<ByteArray?>) -> Unit,
    ): Cancellable {
        val rawUri = registry.resolve(token, identityEpoch, playerHash)
        if (rawUri == null) {
            callback(Result.success(null))
            return Cancellable {}
        }

        val completed = AtomicBoolean(false)
        val task = AtomicReference<java.util.concurrent.Future<*>?>()
        val deadline = AtomicReference<ScheduledFuture<*>?>()
        lateinit var operation: Cancellable
        fun finish(outcome: Result<ByteArray?>) {
            if (!completed.compareAndSet(false, true)) return
            deadline.getAndSet(null)?.cancel(false)
            synchronized(jobLock) { activeOperations.remove(operation) }
            callback(outcome)
        }

        operation = Cancellable {
            task.get()?.cancel(true)
            executor.purge()
            finish(Result.failure(AvatarRequestTimeoutException()))
        }
        synchronized(jobLock) { activeOperations.add(operation) }

        try {
            task.set(
                executor.submit {
                    finish(runCatching { readAvatar(rawUri) })
                },
            )
        } catch (error: RejectedExecutionException) {
            finish(Result.failure(error))
        }
        if (!completed.get()) {
            deadline.set(
                timeoutScheduler.schedule(
                    {
                        task.get()?.cancel(true)
                        executor.purge()
                        finish(Result.failure(AvatarRequestTimeoutException()))
                    },
                    timeoutMillis,
                    TimeUnit.MILLISECONDS,
                ),
            )
            if (completed.get()) deadline.getAndSet(null)?.cancel(false)
        }
        return operation
    }

    fun cancelAll() {
        val operations = synchronized(jobLock) { activeOperations.toList() }
        operations.forEach(Cancellable::cancel)
    }

    fun dispose() {
        cancelAll()
        executor.shutdownNow()
        timeoutScheduler.shutdownNow()
    }

    private companion object {
        fun readUri(context: Context, uri: Uri): ByteArray {
            return when (uri.scheme?.lowercase()) {
                "https" -> readHttps(uri)
                "content" -> context.contentResolver.openInputStream(uri)?.use {
                    BoundedAvatarReader.read(it)
                } ?: throw IllegalStateException("Avatar unavailable")
                else -> throw IllegalArgumentException("Unsupported avatar URI")
            }
        }

        fun readHttps(uri: Uri): ByteArray {
            val connection = URL(uri.toString()).openConnection() as HttpURLConnection
            connection.connectTimeout = GameServicesContract.AVATAR_TIMEOUT_MILLIS.toInt()
            connection.readTimeout = GameServicesContract.AVATAR_TIMEOUT_MILLIS.toInt()
            connection.instanceFollowRedirects = true
            try {
                val length = connection.contentLengthLong
                if (length > GameServicesContract.MAX_AVATAR_BYTES) {
                    throw AvatarPayloadTooLargeException()
                }
                return connection.inputStream.use(BoundedAvatarReader::read)
            } finally {
                connection.disconnect()
            }
        }
    }
}

class GameServicesBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, GameServicesContract.METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, GameServicesContract.IDENTITY_EVENT_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val catalog by lazy { LeaderboardCatalog.fromResources(activity) }
    private val avatarRegistry = AvatarTokenRegistry()
    private val avatarLoader = NativeAvatarLoader(activity.applicationContext, avatarRegistry)

    private var eventSink: EventChannel.EventSink? = null
    private var lastPlayerId: String? = null
    private var identitySessionToken: String? = null
    private var lastIdentityPayload: Map<String, Any?>? = null
    private var identityEpoch = 0L
    private var disposed = false

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: FlutterResult) {
        if (disposed) {
            result.error(GameServicesFailureCode.RETRYABLE.channelCode, null, null)
            return
        }
        try {
            when (call.method) {
                "validateConfiguration" -> validateConfiguration(result)
                "restoreIdentity" -> restoreIdentity(result)
                "authenticate" -> authenticate(call, result)
                "loadLeaderboard" -> loadLeaderboard(call, result)
                "submitScore" -> submitScore(call, result)
                "loadAvatar" -> loadAvatar(call, result)
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            replyError(result, error)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        lastIdentityPayload?.let { payload ->
            events.success(
                mapOf(
                    "kind" to "authenticated",
                    "epoch" to identityEpoch,
                    "identity" to payload,
                ),
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun refreshIdentitySilently() {
        if (disposed || runCatching { requireConfiguration() }.isFailure) return
        AuthenticationCoordinator(PlayGamesAuthenticationPort(activity)).restoreIdentity { outcome ->
            mainHandler.post {
                if (disposed) return@post
                outcome.onSuccess { player ->
                    if (player == null) recordSignedOut() else recordPlayer(player)
                }
            }
        }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        avatarRegistry.clear()
        avatarLoader.dispose()
        mainHandler.removeCallbacksAndMessages(null)
    }

    private fun validateConfiguration(result: FlutterResult) {
        runCatching { requireConfiguration() }.fold(
            onSuccess = { result.success(null) },
            onFailure = { replyError(result, it) },
        )
    }

    private fun restoreIdentity(result: FlutterResult) {
        runOperation(
            timeoutMillis = GameServicesContract.READ_TIMEOUT_MILLIS,
            result = result,
            encode = { player: NativePlayer? -> player?.let(::recordPlayer) },
        ) { callback ->
            requireConfiguration()
            AuthenticationCoordinator(PlayGamesAuthenticationPort(activity))
                .restoreIdentity { outcome ->
                    if (outcome.getOrNull() == null && outcome.isSuccess) {
                        mainHandler.post(::recordSignedOut)
                    }
                    callback(outcome)
                }
            null
        }
    }

    private fun authenticate(call: MethodCall, result: FlutterResult) {
        val interactive = call.argument<Boolean>("interactive") ?: false
        runOperation(
            timeoutMillis = GameServicesContract.READ_TIMEOUT_MILLIS,
            result = result,
            encode = { player: NativePlayer -> recordPlayer(player) },
        ) { callback ->
            requireConfiguration()
            AuthenticationCoordinator(PlayGamesAuthenticationPort(activity))
                .authenticate(interactive, callback)
            null
        }
    }

    private fun loadLeaderboard(call: MethodCall, result: FlutterResult) {
        val expectedIdentity = requiredIdentityBinding(call)
        val arenaId = requiredInt(call, "arenaId")
        val limit = requiredInt(call, "limit")
        val scope = when (call.argument<String>("scope")) {
            "global" -> NativeLeaderboardScope.GLOBAL
            "friends" -> NativeLeaderboardScope.FRIENDS
            else -> throwOrReply(result, IllegalArgumentException("Invalid scope")) ?: return
        }
        if (limit !in 1..GameServicesContract.MAX_ROWS) {
            replyError(result, IllegalArgumentException("Invalid limit"))
            return
        }

        val composite = CompositeCancellable()
        runOperation(
            timeoutMillis = GameServicesContract.READ_TIMEOUT_MILLIS,
            result = result,
            encode = ::encodeLeaderboardPage,
        ) { callback ->
            requireConfiguration()
            val leaderboardId = catalog.idForArena(arenaId)
            verifyIdentity(expectedIdentity) { identity ->
                identity.fold(
                    onSuccess = { player ->
                        val loader = LeaderboardPageLoader(PlayGamesLeaderboardPort(activity))
                        val operation = loader.load(
                            leaderboardId = leaderboardId,
                            scope = scope,
                            requestedLimit = limit,
                            currentPlayerId = player.playerId,
                            callback = { outcome ->
                                outcome.fold(
                                    onSuccess = { page ->
                                        verifyIdentity(expectedIdentity) { verified ->
                                            verified.fold(
                                                onSuccess = {
                                                    callback(Result.success(page))
                                                },
                                                onFailure = {
                                                    callback(Result.failure(it))
                                                },
                                            )
                                        }
                                    },
                                    onFailure = { callback(Result.failure(it)) },
                                )
                            },
                        )
                        composite.set(operation)
                    },
                    onFailure = { callback(Result.failure(it)) },
                )
            }
            composite
        }
    }

    private fun submitScore(call: MethodCall, result: FlutterResult) {
        val expectedIdentity = requiredIdentityBinding(call)
        val arenaId = requiredInt(call, "arenaId")
        val score = requiredLong(call, "score")
        runOperation(
            timeoutMillis = GameServicesContract.SUBMIT_TIMEOUT_MILLIS,
            result = result,
            encode = { _: Unit -> null },
        ) { callback ->
            requireConfiguration()
            verifyIdentity(expectedIdentity) { identity ->
                identity.fold(
                    onSuccess = {
                        GameServicesService(
                            catalog,
                            activity.packageName,
                            PlayGamesLeaderboardPort(activity),
                        ).submitScore(arenaId, score) { outcome ->
                            outcome.fold(
                                onSuccess = {
                                    verifyIdentity(expectedIdentity) { verified ->
                                        verified.fold(
                                            onSuccess = {
                                                callback(Result.success(Unit))
                                            },
                                            onFailure = {
                                                callback(Result.failure(it))
                                            },
                                        )
                                    }
                                },
                                onFailure = { callback(Result.failure(it)) },
                            )
                        }
                    },
                    onFailure = { callback(Result.failure(it)) },
                )
            }
            null
        }
    }

    private fun loadAvatar(call: MethodCall, result: FlutterResult) {
        val expectedIdentity = requiredIdentityBinding(call)
        if (call.argument<String>("platform") != "playGames") {
            replyError(result, IllegalArgumentException("Invalid platform"))
            return
        }
        val epoch = requiredLong(call, "identityEpoch")
        val playerHash = call.argument<String>("playerHash")
        val token = call.argument<String>("token")
        if (playerHash.isNullOrBlank() || token.isNullOrBlank()) {
            replyError(result, IllegalArgumentException("Invalid avatar reference"))
            return
        }
        runOperation(
            timeoutMillis = GameServicesContract.AVATAR_TIMEOUT_MILLIS,
            result = result,
            encode = { bytes: ByteArray? -> bytes },
        ) { callback ->
            val composite = CompositeCancellable()
            verifyIdentity(expectedIdentity) { identity ->
                identity.fold(
                    onSuccess = {
                        composite.set(
                            avatarLoader.load(token, epoch, playerHash) { outcome ->
                                outcome.fold(
                                    onSuccess = { bytes ->
                                        verifyIdentity(expectedIdentity) { verified ->
                                            verified.fold(
                                                onSuccess = {
                                                    callback(Result.success(bytes))
                                                },
                                                onFailure = {
                                                    callback(Result.failure(it))
                                                },
                                            )
                                        }
                                    },
                                    onFailure = { callback(Result.failure(it)) },
                                )
                            },
                        )
                    },
                    onFailure = { callback(Result.failure(it)) },
                )
            }
            composite
        }
    }

    private fun requireConfiguration() {
        catalog.validate(activity.packageName)
    }

    private fun recordPlayer(player: NativePlayer): Map<String, Any?> {
        val previousPlayerId = lastPlayerId
        val identityChanged = previousPlayerId == null || previousPlayerId != player.playerId
        val kind = when {
            previousPlayerId == null -> {
                identityEpoch++
                identitySessionToken = UUID.randomUUID().toString()
                "authenticated"
            }
            previousPlayerId != player.playerId -> {
                identityEpoch++
                identitySessionToken = UUID.randomUUID().toString()
                avatarRegistry.clear()
                avatarLoader.cancelAll()
                "accountChanged"
            }
            else -> "authenticated"
        }
        lastPlayerId = player.playerId
        val payload = encodeIdentity(player)
        lastIdentityPayload = payload
        if (identityChanged) {
            eventSink?.success(
                mapOf(
                    "kind" to kind,
                    "epoch" to identityEpoch,
                    "identity" to payload,
                ),
            )
        }
        return payload
    }

    private fun recordSignedOut() {
        if (lastPlayerId == null) return
        lastPlayerId = null
        identitySessionToken = null
        lastIdentityPayload = null
        identityEpoch++
        avatarRegistry.clear()
        avatarLoader.cancelAll()
        eventSink?.success(mapOf("kind" to "signedOut", "epoch" to identityEpoch))
    }

    private fun encodeIdentity(player: NativePlayer): Map<String, Any?> = mapOf(
        "platform" to "playGames",
        "playerId" to player.playerId,
        "displayName" to player.displayName,
        "sessionToken" to requireNotNull(identitySessionToken),
        "avatar" to avatarRegistry.register(
            player.playerId,
            player.avatarUri,
            identityEpoch,
        )?.toChannelMap(),
    )

    private fun encodeLeaderboardPage(page: NativeLeaderboardPage): Map<String, Any?> = mapOf(
        "leaders" to page.leaders.map(::encodeScoreEntry),
        "currentPlayer" to page.currentPlayer?.let(::encodeScoreEntry),
    )

    private fun encodeScoreEntry(entry: NativeScoreEntry): Map<String, Any?> = mapOf(
        "rank" to entry.rank,
        "playerId" to entry.playerId,
        "displayName" to entry.displayName,
        "score" to entry.score,
        "isCurrentPlayer" to entry.isCurrentPlayer,
        "avatar" to avatarRegistry.register(
            entry.playerId,
            entry.avatarUri,
            identityEpoch,
        )?.toChannelMap(),
    )

    private fun requiredInt(call: MethodCall, name: String): Int {
        val value = call.argument<Number>(name)?.toLong()
            ?: throw IllegalArgumentException("Missing argument")
        if (value !in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong()) {
            throw IllegalArgumentException("Invalid argument")
        }
        return value.toInt()
    }

    private fun requiredLong(call: MethodCall, name: String): Long =
        call.argument<Number>(name)?.toLong()
            ?: throw IllegalArgumentException("Missing argument")

    private fun requiredIdentityBinding(call: MethodCall): ExpectedIdentityBinding {
        val playerId = call.argument<String>("expectedPlayerId")
        val sessionToken = call.argument<String>("identitySessionToken")
        if (playerId.isNullOrBlank() || sessionToken.isNullOrBlank()) {
            throw GameServicesUnauthenticatedException()
        }
        return ExpectedIdentityBinding(playerId, sessionToken)
    }

    private fun verifyIdentity(
        expected: ExpectedIdentityBinding,
        callback: (Result<NativePlayer>) -> Unit,
    ) {
        AuthenticationCoordinator(PlayGamesAuthenticationPort(activity))
            .restoreIdentity { outcome ->
                mainHandler.post {
                    outcome.fold(
                        onSuccess = { player ->
                            if (player == null) {
                                recordSignedOut()
                                callback(
                                    Result.failure(GameServicesUnauthenticatedException()),
                                )
                                return@fold
                            }
                            val bindingMatches = IdentitySessionVerifier.matches(
                                expected = expected,
                                currentPlayerId = player.playerId,
                                recordedPlayerId = lastPlayerId,
                                currentSessionToken = identitySessionToken,
                            )
                            if (!bindingMatches) {
                                recordIdentityMismatch(player)
                                callback(
                                    Result.failure(GameServicesUnauthenticatedException()),
                                )
                                return@fold
                            }
                            callback(Result.success(player))
                        },
                        onFailure = { callback(Result.failure(it)) },
                    )
                }
            }
    }

    private fun recordIdentityMismatch(player: NativePlayer) {
        identityEpoch++
        identitySessionToken = UUID.randomUUID().toString()
        avatarRegistry.clear()
        avatarLoader.cancelAll()
        lastPlayerId = player.playerId
        val payload = encodeIdentity(player)
        lastIdentityPayload = payload
        eventSink?.success(
            mapOf(
                "kind" to "accountChanged",
                "epoch" to identityEpoch,
                "identity" to payload,
            ),
        )
    }

    private fun <T> runOperation(
        timeoutMillis: Long,
        result: FlutterResult,
        encode: (T) -> Any?,
        start: ((Result<T>) -> Unit) -> Cancellable?,
    ) {
        val completed = AtomicBoolean(false)
        val cancellation = CompositeCancellable()
        val timeout = Runnable {
            if (completed.compareAndSet(false, true)) {
                cancellation.cancel()
                result.error(GameServicesFailureCode.RETRYABLE.channelCode, null, null)
            }
        }
        mainHandler.postDelayed(timeout, timeoutMillis)

        val callback: (Result<T>) -> Unit = { outcome ->
            mainHandler.post {
                if (!completed.compareAndSet(false, true)) return@post
                mainHandler.removeCallbacks(timeout)
                outcome.fold(
                    onSuccess = { value ->
                        runCatching { encode(value) }.fold(
                            onSuccess = result::success,
                            onFailure = { replyError(result, it) },
                        )
                    },
                    onFailure = { replyError(result, it) },
                )
            }
        }

        try {
            cancellation.set(start(callback))
        } catch (error: Throwable) {
            callback(Result.failure(error))
        }
    }

    private fun replyError(result: FlutterResult, error: Throwable) {
        result.error(GameServicesFailureMapper.fromThrowable(error).channelCode, null, null)
    }

    private fun throwOrReply(result: FlutterResult, error: Throwable): Nothing? {
        replyError(result, error)
        return null
    }

    private class CompositeCancellable : Cancellable {
        private val lock = Any()
        private var cancelled = false
        private var delegate: Cancellable? = null

        fun set(next: Cancellable?) {
            val cancelNow = synchronized(lock) {
                if (cancelled) true else {
                    delegate = next
                    false
                }
            }
            if (cancelNow) next?.cancel()
        }

        override fun cancel() {
            val current = synchronized(lock) {
                if (cancelled) return
                cancelled = true
                delegate.also { delegate = null }
            }
            current?.cancel()
        }
    }
}

private fun Player.toNativePlayer(): NativePlayer = NativePlayer(
    playerId = playerId,
    displayName = displayName,
    avatarUri = (iconImageUri ?: hiResImageUri)?.toString(),
)

private fun LeaderboardScore.toNativeScoreEntry(): NativeScoreEntry {
    val player = requireNotNull(scoreHolder) { "Missing score holder" }
    return NativeScoreEntry(
        rank = rank,
        playerId = player.playerId,
        displayName = scoreHolderDisplayName,
        score = rawScore,
        avatarUri = (player.iconImageUri ?: player.hiResImageUri)?.toString(),
    )
}
