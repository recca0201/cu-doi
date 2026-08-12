package com.tungbogin.cudoi

import android.app.Application
import com.google.android.gms.games.PlayGamesSdk
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity

class BanBuaTuongApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (!BuildConfig.LEADERBOARDS_ENABLED) return
        // Play Games can only be initialized once its console-owned catalog is
        // real. Placeholder builds remain fully playable and fail the explicit
        // configuration check instead of crashing during process startup.
        runCatching {
            LeaderboardCatalog.fromResources(this).validate(packageName)
        }.onSuccess {
            PlayGamesSdk.initialize(this)
        }
    }
}

class MainActivity : FlutterActivity() {
    private var gameServicesBridge: GameServicesBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (!BuildConfig.LEADERBOARDS_ENABLED) return
        gameServicesBridge = GameServicesBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onResume() {
        super.onResume()
        gameServicesBridge?.refreshIdentitySilently()
    }

    override fun onDestroy() {
        gameServicesBridge?.dispose()
        gameServicesBridge = null
        super.onDestroy()
    }
}
