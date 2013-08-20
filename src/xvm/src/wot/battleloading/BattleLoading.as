﻿import com.xvm.Comm;
import com.xvm.Config;
import com.xvm.Defines;
import com.xvm.GlobalEventDispatcher;
import com.xvm.Logger;
import com.xvm.StatData;
import com.xvm.StatLoader;
import com.xvm.StatsLogger;
import com.xvm.Utils;
import wot.battleloading.RealClock;
import wot.battleloading.TipField;
import wot.battleloading.WinChances;

class wot.battleloading.BattleLoading
{
    /////////////////////////////////////////////////////////////////
    // wrapped methods

    private var wrapper:net.wargaming.BattleLoading;
    private var base:net.wargaming.BattleLoading;

    public function BattleLoading(wrapper:net.wargaming.BattleLoading, base:net.wargaming.BattleLoading)
    {
        this.wrapper = wrapper;
        this.base = base;
        BattleLoadingCtor();
    }

    function setSize()
    {
        return this.setSizeImpl.apply(this, arguments);
    }

    // wrapped methods
    /////////////////////////////////////////////////////////////////

    private static var STAT_PRELOAD_DELAY:Number = 1000;

    // Components
    private var winChances:WinChances;
    private var tipField:TipField;
    private var realClock:RealClock;

    private function BattleLoadingCtor()
    {
        Utils.TraceXvmModule("battleloading");

        StatData.s_loaded = false;
        StatData.s_data = {};
        StatLoader.instance.players_count = 0;
        StatLoader.instance.teams = { t1:0, t2:0 };

        // Components
        winChances = new WinChances(wrapper.form_mc); // Winning chance info above players list.
        tipField   = new TipField(wrapper.form_mc);   // Information field below players list.
        realClock  = new RealClock(wrapper.form_mc);  // Realworld time at right side of TipField.

        GlobalEventDispatcher.addEventListener(Config.E_CONFIG_LOADED, this, onConfigLoaded);
        Config.LoadConfig();
        GlobalEventDispatcher.addEventListener(StatData.E_STAT_LOADED, this, onStatLoaded);
    }

    private function onStatLoaded()
    {
        GlobalEventDispatcher.removeEventListener(StatData.E_STAT_LOADED, this, onStatLoaded);
        if (Config.s_config.rating.enableStatisticsLog == true)
            StatsLogger.saveStatistics("setup", StatData.s_data);
    }

    // override
    function setSizeImpl(width, height)
    {
        base.setSize(width, height);
        Comm.SetVar("window_size", width + "," + height);
    }

    private function onConfigLoaded()
    {
        GlobalEventDispatcher.removeEventListener(Config.E_CONFIG_LOADED, this, onConfigLoaded);
        traceToProxyTerminal();

        winChances.showChances = Config.s_config.battleLoading.showChances;
        winChances.showExp = Config.s_config.battleLoading.showChancesExp;
        winChances.enableLog = Config.s_config.rating.enableStatisticsLog;

        if (Config.s_config.rating.showPlayersStatistics)
            loadStatistics();
    }

    private static function loadStatistics(loop)
    {
        if (!loop)
          loop = 0;
        // Force stats loading after 0.5 sec if enabled (for 12x12 battles, FogOfWar, ...)
        _global.setTimeout
        (
            function() {
                if (!StatData.s_loaded) {
                    if (StatLoader.instance.teams.t1 == 0 /*&& StatLoader.teams.t2 == 0*/) { // t2 disabled because of FogOfWar
                        if (loop * BattleLoading.STAT_PRELOAD_DELAY > 10000) { // 10 sec
                            Logger.add("WARNING: no players data after 10 sec, skip stats loading");
                        } else {
                            Logger.add("[" + loop  + "] no players data, waiting more");
                            BattleLoading.loadStatistics(loop + 1);
                        }
                    }
                    else {
                        Logger.add("[BattleLoading] loading stat data (" + StatLoader.instance.players_count + " players)");
                        StatLoader.instance.StartLoadData();
                    }
                }
            },
            STAT_PRELOAD_DELAY
        );
    }

    private function traceToProxyTerminal()
    {
        Logger.add("[BattleLoading]\n" +
                "    XVM_VERSION=" + Defines.XVM_VERSION + "\n" +
                "    MAX_PATH=" + Defines.MAX_PATH + "\n" +
                "    GameRegion=" + Config.s_game_region + "\n" +
                "    configVersion=" + Config.s_config.configVersion + "\n" +
                "    showPlayersStatistics=" + Config.s_config.rating.showPlayersStatistics + "\n" +
                "    loadEnemyStatsInFogOfWar=" + Config.s_config.rating.loadEnemyStatsInFogOfWar + "\n" +
                "    useStandardMarkers=" + Config.s_config.battle.useStandardMarkers);
    }
}
