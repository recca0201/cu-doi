package com.example.ban_bua_tuong

import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.games.GamesClientStatusCodes
import java.io.ByteArrayInputStream
import java.io.File
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class GameServicesBridgeTest {
    @Test
    fun `channel and native limits match the versioned Dart contract`() {
        assertEquals("ban_bua_tuong/game_services/v1", GameServicesContract.METHOD_CHANNEL)
        assertEquals(
            "ban_bua_tuong/game_services/identity_events/v1",
            GameServicesContract.IDENTITY_EVENT_CHANNEL,
        )
        assertEquals(10_000L, GameServicesContract.READ_TIMEOUT_MILLIS)
        assertEquals(8_000L, GameServicesContract.SUBMIT_TIMEOUT_MILLIS)
        assertEquals(5_000L, GameServicesContract.AVATAR_TIMEOUT_MILLIS)
        assertEquals(25, GameServicesContract.PAGE_SIZE)
        assertEquals(100, GameServicesContract.MAX_ROWS)
        assertEquals(256 * 1024, GameServicesContract.MAX_AVATAR_BYTES)
        assertEquals(4, GameServicesContract.MAX_AVATAR_REQUESTS)
        assertEquals(32, GameServicesContract.MAX_PENDING_AVATAR_REQUESTS)
    }

    @Test
    fun `identity session requires the expected player and opaque token`() {
        val expected = ExpectedIdentityBinding("player-a", "session-a")

        assertTrue(
            IdentitySessionVerifier.matches(
                expected,
                currentPlayerId = "player-a",
                recordedPlayerId = "player-a",
                currentSessionToken = "session-a",
            ),
        )
        assertFalse(
            IdentitySessionVerifier.matches(
                expected,
                currentPlayerId = "player-b",
                recordedPlayerId = "player-a",
                currentSessionToken = "session-a",
            ),
        )
        assertFalse(
            IdentitySessionVerifier.matches(
                expected,
                currentPlayerId = "player-a",
                recordedPlayerId = "player-a",
                currentSessionToken = "session-b",
            ),
        )
    }

    @Test
    fun `valid fixture has exactly twenty unique non-placeholder IDs`() {
        val catalog = validCatalog()

        catalog.validate(RUNTIME_APPLICATION_ID)

        assertEquals((1..20).toSet(), catalog.leaderboardIds.keys)
        assertEquals(20, catalog.leaderboardIds.values.toSet().size)
        for (arenaId in 1..20) {
            assertEquals("CgkIProductionFixtureEAIQ${arenaId.toString().padStart(2, '0')}", catalog.idForArena(arenaId))
        }
    }

    @Test
    fun `catalog rejects missing duplicate placeholder and application mismatch`() {
        val valid = validCatalog()
        val cases = listOf(
            valid.copy(leaderboardIds = valid.leaderboardIds - 20),
            valid.copy(
                leaderboardIds = valid.leaderboardIds +
                    (20 to requireNotNull(valid.leaderboardIds[19])),
            ),
            valid.copy(
                leaderboardIds = valid.leaderboardIds +
                    (20 to "REPLACE_WITH_LEADERBOARD_ID_ARENA_20"),
            ),
            valid.copy(gameServicesProjectId = "REPLACE_WITH_PLAY_GAMES_PROJECT_ID"),
            valid.copy(configuredApplicationId = "REPLACE_WITH_RELEASE_APPLICATION_ID"),
        )

        for (catalog in cases) {
            assertThrows(GameServicesConfigurationException::class.java) {
                catalog.validate(RUNTIME_APPLICATION_ID)
            }
        }
        assertThrows(GameServicesConfigurationException::class.java) {
            valid.validate("com.example.a_different_application")
        }
        assertThrows(GameServicesConfigurationException::class.java) {
            valid.idForArena(0)
        }
        assertThrows(GameServicesConfigurationException::class.java) {
            valid.idForArena(21)
        }
    }

    @Test
    fun `production resource declares all arenas but placeholders fail configuration`() {
        val values = readStringResources()
        val ids = (1..20).associateWith { arenaId ->
            requireNotNull(values["leaderboard_arena_$arenaId"])
        }
        val catalog = LeaderboardCatalog(
            gameServicesProjectId = requireNotNull(values["game_services_project_id"]),
            configuredApplicationId = requireNotNull(values["play_games_android_application_id"]),
            leaderboardIds = ids,
        )

        assertEquals(20, ids.size)
        assertThrows(GameServicesConfigurationException::class.java) {
            catalog.validate(RUNTIME_APPLICATION_ID)
        }
    }

    @Test
    fun `manifest suppresses launch profile prompt and registers the project ID`() {
        val manifest = File("src/main/AndroidManifest.xml").readText()

        assertTrue(manifest.contains("com.google.android.gms.games.APP_ID"))
        assertTrue(manifest.contains("@string/game_services_project_id"))
        assertTrue(manifest.contains("com.google.android.gms.games.SUPPRESS_GAME_PROFILE_CREATION"))
        assertTrue(Regex("android:value\\s*=\\s*\"true\"").containsMatchIn(manifest))
    }

    @Test
    fun `startup restore is silent while interactive auth calls sign in`() {
        val port = FakeAuthenticationPort(authenticated = false)
        val coordinator = AuthenticationCoordinator(port)
        var restored: Result<NativePlayer?>? = null

        coordinator.restoreIdentity { restored = it }

        assertNull(requireNotNull(restored).getOrThrow())
        assertEquals(1, port.authenticationChecks)
        assertEquals(0, port.signInCalls)
        assertEquals(0, port.playerLoads)

        port.authenticated = true
        var authenticated: Result<NativePlayer>? = null
        coordinator.authenticate(interactive = true) { authenticated = it }

        assertEquals("current-player", requireNotNull(authenticated).getOrThrow().playerId)
        assertEquals(1, port.signInCalls)
        assertEquals(1, port.playerLoads)
    }

    @Test
    fun `non-interactive authenticate never invokes sign in`() {
        val port = FakeAuthenticationPort(authenticated = true)
        val coordinator = AuthenticationCoordinator(port)
        var authenticated: Result<NativePlayer>? = null

        coordinator.authenticate(interactive = false) { authenticated = it }

        assertEquals("current-player", requireNotNull(authenticated).getOrThrow().playerId)
        assertEquals(1, port.authenticationChecks)
        assertEquals(0, port.signInCalls)
    }

    @Test
    fun `top one hundred uses four pages of at most twenty five and releases every buffer`() {
        val pages = (0 until 4).map { page ->
            FakeScorePage(
                rows = (0 until 25).map { offset ->
                    val index = page * 25 + offset
                    scoreRow(playerId = "player-$index", rank = index + 1)
                },
            )
        }
        val port = FakeLeaderboardPort(pages = pages.toMutableList()).apply {
            currentScore = scoreRow(playerId = "current-player", rank = 321)
        }
        val loader = LeaderboardPageLoader(port)
        var loaded: Result<NativeLeaderboardPage>? = null

        loader.load(
            leaderboardId = "CgkIProductionFixtureEAIQ01",
            scope = NativeLeaderboardScope.GLOBAL,
            requestedLimit = 100,
            currentPlayerId = "current-player",
        ) { loaded = it }

        val result = requireNotNull(loaded).getOrThrow()
        assertEquals(100, result.leaders.size)
        assertEquals(100, result.leaders.map { it.playerId }.toSet().size)
        assertEquals("current-player", result.currentPlayer?.playerId)
        assertEquals(4, port.pageSizes.size)
        assertTrue(port.pageSizes.all { it in 1..25 })
        assertEquals(1, port.currentPlayerLoads)
        assertTrue(pages.all { it.releaseCount == 1 })
    }

    @Test
    fun `paging deduplicates player IDs and does not duplicate current player`() {
        val first = FakeScorePage(
            rows = (0 until 25).map { scoreRow("player-$it", it + 1) },
        )
        val second = FakeScorePage(
            rows = listOf(scoreRow("player-24", 25)) +
                (25 until 49).map { scoreRow("player-$it", it + 1) },
        )
        val port = FakeLeaderboardPort(mutableListOf(first, second))
        val loader = LeaderboardPageLoader(port)
        var loaded: Result<NativeLeaderboardPage>? = null

        loader.load(
            leaderboardId = "CgkIProductionFixtureEAIQ01",
            scope = NativeLeaderboardScope.FRIENDS,
            requestedLimit = 50,
            currentPlayerId = "player-10",
        ) { loaded = it }

        val result = requireNotNull(loaded).getOrThrow()
        assertEquals(49, result.leaders.size)
        assertEquals(49, result.leaders.map { it.playerId }.toSet().size)
        assertNull(result.currentPlayer)
        assertEquals(0, port.currentPlayerLoads)
        assertTrue(result.leaders.single { it.playerId == "player-10" }.isCurrentPlayer)
        assertEquals(1, first.releaseCount)
        assertEquals(1, second.releaseCount)
    }

    @Test
    fun `paging failure still releases the prior score buffer`() {
        val first = FakeScorePage(
            rows = (0 until 25).map { scoreRow("player-$it", it + 1) },
        )
        val port = FakeLeaderboardPort(mutableListOf(first)).apply {
            loadMoreFailure = IllegalStateException("network detail")
        }
        val loader = LeaderboardPageLoader(port)
        var loaded: Result<NativeLeaderboardPage>? = null

        loader.load(
            leaderboardId = "CgkIProductionFixtureEAIQ01",
            scope = NativeLeaderboardScope.GLOBAL,
            requestedLimit = 50,
            currentPlayerId = "current-player",
        ) { loaded = it }

        assertTrue(requireNotNull(loaded).isFailure)
        assertEquals(1, first.releaseCount)
    }

    @Test
    fun `friends resolution and platform statuses map to stable channel errors`() {
        assertEquals(
            GameServicesFailureCode.FRIENDS_UNAVAILABLE,
            GameServicesFailureMapper.fromStatus(
                CommonStatusCodes.SUCCESS,
                friendsResolutionRequired = true,
            ),
        )
        assertEquals(
            GameServicesFailureCode.FRIENDS_UNAVAILABLE,
            GameServicesFailureMapper.fromStatus(GamesClientStatusCodes.CONSENT_REQUIRED),
        )
        assertEquals(
            GameServicesFailureCode.UNAUTHENTICATED,
            GameServicesFailureMapper.fromStatus(CommonStatusCodes.SIGN_IN_REQUIRED),
        )
        assertEquals(
            GameServicesFailureCode.CANCELLED,
            GameServicesFailureMapper.fromStatus(CommonStatusCodes.CANCELED),
        )
        assertEquals(
            GameServicesFailureCode.RESTRICTED,
            GameServicesFailureMapper.fromStatus(CommonStatusCodes.INVALID_ACCOUNT),
        )
        assertEquals(
            GameServicesFailureCode.RETRYABLE,
            GameServicesFailureMapper.fromStatus(CommonStatusCodes.NETWORK_ERROR),
        )
        assertEquals(
            GameServicesFailureCode.PERMANENT,
            GameServicesFailureMapper.fromStatus(GamesClientStatusCodes.APP_MISCONFIGURED),
        )
    }

    @Test
    fun `submit maps arena to catalog and uses immediate error-reporting call`() {
        val port = FakeLeaderboardPort(mutableListOf())
        val service = GameServicesService(validCatalog(), RUNTIME_APPLICATION_ID, port)
        var submitted: Result<Unit>? = null

        service.submitScore(arenaId = 12, score = 2_050L) { submitted = it }

        requireNotNull(submitted).getOrThrow()
        assertEquals(
            listOf(SubmittedScore("CgkIProductionFixtureEAIQ12", 2_050L)),
            port.submittedScores,
        )
        assertThrows(IllegalArgumentException::class.java) {
            service.submitScore(arenaId = 12, score = 0L) {}
        }
    }

    @Test
    fun `avatar references are opaque epoch-bound and bytes are capped`() {
        val registry = AvatarTokenRegistry(tokenFactory = { "opaque-token" })
        val avatar = requireNotNull(
            registry.register(
                playerId = "raw-player-id",
                imageUri = "https://example.invalid/avatar.png",
                identityEpoch = 7,
            ),
        )

        assertEquals("playGames", avatar.platform)
        assertEquals(7L, avatar.identityEpoch)
        assertNotEquals("raw-player-id", avatar.playerHash)
        assertEquals("opaque-token", avatar.token)
        assertEquals(
            "https://example.invalid/avatar.png",
            registry.resolve(avatar.token, avatar.identityEpoch, avatar.playerHash),
        )
        assertNull(registry.resolve(avatar.token, 8, avatar.playerHash))
        assertNull(registry.resolve(avatar.token, 7, "another-hash"))

        val atLimit = ByteArray(GameServicesContract.MAX_AVATAR_BYTES) { (it % 251).toByte() }
        assertArrayEquals(atLimit, BoundedAvatarReader.read(ByteArrayInputStream(atLimit)))
        assertThrows(AvatarPayloadTooLargeException::class.java) {
            BoundedAvatarReader.read(
                ByteArrayInputStream(ByteArray(GameServicesContract.MAX_AVATAR_BYTES + 1)),
            )
        }
    }

    @Test
    fun `avatar queue is bounded and timeouts release workers exactly once`() {
        val tokenCounter = AtomicInteger()
        val registry = AvatarTokenRegistry {
            "opaque-${tokenCounter.incrementAndGet()}"
        }
        val descriptors = (1..4).map { index ->
            requireNotNull(
                registry.register(
                    playerId = "player-$index",
                    imageUri = "https://example.invalid/$index.png",
                    identityEpoch = 1,
                ),
            )
        }
        val blocked = CountDownLatch(1)
        val executor = ThreadPoolExecutor(
            1,
            1,
            0L,
            TimeUnit.MILLISECONDS,
            ArrayBlockingQueue(1),
            ThreadPoolExecutor.AbortPolicy(),
        )
        val callbacks = AtomicInteger()
        val firstWave = CountDownLatch(3)
        val loader = NativeAvatarLoader(
            registry = registry,
            readAvatar = {
                blocked.await()
                byteArrayOf(7)
            },
            executor = executor,
            timeoutScheduler = Executors.newSingleThreadScheduledExecutor(),
            timeoutMillis = 30L,
        )

        for (descriptor in descriptors.take(3)) {
            loader.load(
                descriptor.token,
                descriptor.identityEpoch,
                descriptor.playerHash,
            ) {
                callbacks.incrementAndGet()
                firstWave.countDown()
            }
        }

        assertTrue(firstWave.await(2, TimeUnit.SECONDS))
        assertEquals(3, callbacks.get())
        blocked.countDown()

        val finalWave = CountDownLatch(1)
        val accepted = AtomicInteger()
        val fourth = descriptors.last()
        loader.load(fourth.token, fourth.identityEpoch, fourth.playerHash) { outcome ->
            if (outcome.getOrNull()?.contentEquals(byteArrayOf(7)) == true) {
                accepted.incrementAndGet()
            }
            callbacks.incrementAndGet()
            finalWave.countDown()
        }
        assertTrue(finalWave.await(2, TimeUnit.SECONDS))
        Thread.sleep(60L)
        assertEquals(1, accepted.get())
        assertEquals(4, callbacks.get())
        loader.dispose()
    }

    @Test
    fun `clearing avatar jobs cancels active and pending callbacks exactly once`() {
        val tokenCounter = AtomicInteger()
        val registry = AvatarTokenRegistry {
            "clear-${tokenCounter.incrementAndGet()}"
        }
        val descriptors = (1..2).map { index ->
            requireNotNull(
                registry.register(
                    playerId = "clear-player-$index",
                    imageUri = "https://example.invalid/clear-$index.png",
                    identityEpoch = 2,
                ),
            )
        }
        val blocked = CountDownLatch(1)
        val callbacks = AtomicInteger()
        val cancelled = CountDownLatch(2)
        val loader = NativeAvatarLoader(
            registry = registry,
            readAvatar = {
                blocked.await()
                byteArrayOf(9)
            },
            executor = ThreadPoolExecutor(
                1,
                1,
                0L,
                TimeUnit.MILLISECONDS,
                ArrayBlockingQueue(2),
                ThreadPoolExecutor.AbortPolicy(),
            ),
            timeoutScheduler = Executors.newSingleThreadScheduledExecutor(),
            timeoutMillis = 5_000L,
        )
        for (descriptor in descriptors) {
            loader.load(
                descriptor.token,
                descriptor.identityEpoch,
                descriptor.playerHash,
            ) {
                callbacks.incrementAndGet()
                cancelled.countDown()
            }
        }

        loader.cancelAll()
        assertTrue(cancelled.await(1, TimeUnit.SECONDS))
        blocked.countDown()
        Thread.sleep(60L)
        assertEquals(2, callbacks.get())
        loader.dispose()
    }

    @Test
    fun `bridge source never requests native leaderboard UI`() {
        val source = File(
            "src/main/kotlin/com/example/ban_bua_tuong/GameServicesBridge.kt",
        ).readText()

        assertFalse(source.contains("getLeaderboardIntent("))
        assertFalse(source.contains("getAllLeaderboardsIntent("))
    }

    private fun validCatalog(): LeaderboardCatalog = LeaderboardCatalog(
        gameServicesProjectId = "123456789012",
        configuredApplicationId = RUNTIME_APPLICATION_ID,
        leaderboardIds = (1..20).associateWith { arenaId ->
            "CgkIProductionFixtureEAIQ${arenaId.toString().padStart(2, '0')}"
        },
    )

    private fun readStringResources(): Map<String, String> {
        val factory = DocumentBuilderFactory.newInstance().apply {
            setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
            setFeature("http://xml.org/sax/features/external-general-entities", false)
            setFeature("http://xml.org/sax/features/external-parameter-entities", false)
            isExpandEntityReferences = false
        }
        val document = factory.newDocumentBuilder().parse(
            File("src/main/res/values/leaderboards.xml"),
        )
        val strings = document.getElementsByTagName("string")
        return buildMap {
            for (index in 0 until strings.length) {
                val node = strings.item(index)
                put(node.attributes.getNamedItem("name").nodeValue, node.textContent.trim())
            }
        }
    }

    private fun scoreRow(
        playerId: String,
        rank: Int,
    ): NativeScoreEntry = NativeScoreEntry(
        rank = rank.toLong(),
        playerId = playerId,
        displayName = "Player $playerId",
        score = (10_000 - rank).toLong(),
        avatarUri = "https://example.invalid/$playerId.png",
    )

    private class FakeAuthenticationPort(
        var authenticated: Boolean,
    ) : AuthenticationPort {
        var authenticationChecks = 0
        var signInCalls = 0
        var playerLoads = 0

        override fun isAuthenticated(callback: (Result<Boolean>) -> Unit) {
            authenticationChecks++
            callback(Result.success(authenticated))
        }

        override fun signIn(callback: (Result<Boolean>) -> Unit) {
            signInCalls++
            callback(Result.success(authenticated))
        }

        override fun loadCurrentPlayer(callback: (Result<NativePlayer>) -> Unit) {
            playerLoads++
            callback(
                Result.success(
                    NativePlayer(
                        playerId = "current-player",
                        displayName = "Current player",
                        avatarUri = "https://example.invalid/current.png",
                    ),
                ),
            )
        }
    }

    private class FakeScorePage(
        override val rows: List<NativeScoreEntry>,
    ) : ReleasableScorePage {
        var releaseCount = 0
            private set

        override fun release() {
            if (releaseCount == 0) releaseCount++
        }
    }

    private class FakeLeaderboardPort(
        private val pages: MutableList<FakeScorePage>,
    ) : LeaderboardPort {
        val pageSizes = mutableListOf<Int>()
        val submittedScores = mutableListOf<SubmittedScore>()
        var currentPlayerLoads = 0
        var currentScore: NativeScoreEntry? = null
        var loadMoreFailure: Throwable? = null

        override fun loadTopScores(
            leaderboardId: String,
            scope: NativeLeaderboardScope,
            pageSize: Int,
            callback: (Result<ReleasableScorePage>) -> Unit,
        ) {
            pageSizes += pageSize
            callback(Result.success(pages.removeAt(0)))
        }

        override fun loadMoreScores(
            previousPage: ReleasableScorePage,
            pageSize: Int,
            callback: (Result<ReleasableScorePage>) -> Unit,
        ) {
            pageSizes += pageSize
            val failure = loadMoreFailure
            if (failure != null) {
                callback(Result.failure(failure))
            } else {
                callback(Result.success(pages.removeAt(0)))
            }
        }

        override fun loadCurrentPlayerScore(
            leaderboardId: String,
            scope: NativeLeaderboardScope,
            callback: (Result<NativeScoreEntry?>) -> Unit,
        ) {
            currentPlayerLoads++
            callback(Result.success(currentScore))
        }

        override fun submitScoreImmediate(
            leaderboardId: String,
            score: Long,
            callback: (Result<Unit>) -> Unit,
        ) {
            submittedScores += SubmittedScore(leaderboardId, score)
            callback(Result.success(Unit))
        }
    }

    private data class SubmittedScore(val leaderboardId: String, val score: Long)

    private companion object {
        const val RUNTIME_APPLICATION_ID = "com.example.ban_bua_tuong"
    }
}
