/**
 * ...
 * @author Maxim Schedriviy
 */
import com.xvm.Config;
import com.xvm.Defines;
import com.xvm.GraphicsUtil;
import com.xvm.Locale;
import com.xvm.StatData;
import com.xvm.VehicleInfo;

class com.xvm.Chance
{
    private static var DEBUG_EXP = false;

    private static var battleTier: Number = 0;

    public static var lastChances: Object = null;

    public static function ShowChance(tf:TextField, showExp:Boolean) : String
    {
        var text = GetChanceText(showExp);
        if (text == null)
            return tf.text;
        tf.htmlText = (tf.text == "" ? "" : tf.text + " | ") + text;
        return tf.htmlText;
    }

    public static function ChanceError(text:String) : String
    {
        return "<font color='#FFBBBB'>" + Locale.get("Chance error") + ": " + text + "</font>";
    }

    public static function GetChanceText(showExp:Boolean) : String
    {
        var teamsCount:Object = CalculateTeamPlayersCount();
        //Logger.addObject(teamsCount);
        // only equal and non empty team supported
        if (teamsCount.ally == 0 || teamsCount.enemy == 0)
            return "";
        if (Math.abs(teamsCount.ally - teamsCount.enemy) > 2)
            return "";

        Chance.battleTier = Chance.GuessBattleTier();

        var chG = GetChance(ChanceFuncG);
        var chT = GetChance(ChanceFuncT);

        var text = "";

        if (chG.error)
            return ChanceError("[G] " + chG.error);
        
        if (chT.error)
            return ChanceError("[T] " + chT.error);

        lastChances = { g: chG.percentF, t: chT.percentF };
        text += Locale.get("Chance to win") + ": " +
            FormatChangeText(Locale.get("global"), chG) + ", " +
            FormatChangeText(Locale.get("per-vehicle"), chT);
        if (showExp)
        {
            var chX1 = GetChance(ChanceFuncX1);
            var chX2 = GetChance(ChanceFuncX2);
            text += " | exp: " + FormatChangeText("", chX1) + ", " + FormatChangeText("", chX2) + ". T=" + battleTier;
            lastChances.X1 = chX1.percentF;
            lastChances.X2 = chX2.percentF;
        }
        return text;
    }

    // PRIVATE
    private static var _x1Logged = false;
    private static var _x2Logged = false;
    private static function GetChance(chanceFunc: Function): Object
    {
        var Ka = 0;
        var Ke = 0;
        for (var pname in StatData.s_data)
        {
            var pdata = StatData.s_data[pname];

            var vi1 = VehicleInfo.getInfo1(pdata.icon);
            if (!vi1) {
                var vn = VehicleInfo.getVehicleName(pdata.icon);
                if (vn == "ussr-Observer" || vn == "noImage")
                    continue;
                return { error: "[1] No data for: " + vn };
            }

            var vi2 = VehicleInfo.getInfo2(pdata.icon);
            if (!vi2)
                return { error: "[2] No data for: " + VehicleInfo.getVehicleName(pdata.icon) };

            var K = chanceFunc(vi1, vi2, pdata.team, pdata.stat, (pdata.vehicleState & 1) == 0);

            Ka += (pdata.team == Defines.TEAM_ALLY) ? K : 0;
            Ke += (pdata.team == Defines.TEAM_ENEMY) ? K : 0;
        }

        //Logger.add("Ka=" + Ka + " Ke=" + Ke);
/*
        if (DEBUG_EXP)
        {
            if (!_x1Logged && chanceFunc == ChanceFuncX1)
            {
                _x1Logged = true;
                Logger.add("X1: K = " + Ka + " / " + Ke + " => " + String(Math.round((Ka / (Ka + Ke) * 1000)) / 10) + "%");
            }
            else if (!_x2Logged && chanceFunc == ChanceFuncX2)
            {
                _x2Logged = true;
                Logger.add("X2: K = " + Ka + " / " + Ke + " => " + String(Math.round((Ka / (Ka + Ke) * 1000)) / 10) + "%");
            }
        }
*/

        return PrepareChanceResults(Ka, Ke, chanceFunc);
    }

    // http://www.koreanrandom.com/forum/topic/2598-/#entry31429
    private static function ChanceFuncG(vi1, vi2, team, stat, dead): Number
    {
        var Td = (vi1.tiers[0] + vi1.tiers[1]) / 2.0 - battleTier;

        var Tmin = vi1.tiers[0];
        var Tmax = vi1.tiers[1];
        var T = battleTier;
        var Ea = stat.xwn == null ? Config.s_config.consts.AVG_XVMSCALE : stat.xwn;
        var Ean = Ea + (Ea * (((stat.avglvl || T) - T) * 0.05));
        var Ra = stat.r || Config.s_config.consts.AVG_GWR;
        var Ba = stat.battles || Config.s_config.consts.AVG_BATTLES;

        // 1
        var Klvl = (Tmax + Tmin) / 2 - T;

        // 2
        var Kab = (Ba <= 500) ? 0                          //   0..0.5k  => 0
            : (Ba <= 5000) ? (Ba - 500) / 10000            //  1k..5k => 0..0.45
            : (Ba <= 10000) ? 0.45 + (Ba - 5000) / 20000   //  5k..10k => 0.45..0.7
            : (Ba <= 20000) ? 0.7 + (Ba - 10000) / 40000   // 10k..20k => 0.7..0.95
            : 0.95 + (Ba - 20000) / 80000                  // 20k..    => 0.95..

        // 3
        var Kra = (100 + Ra - 48.5) / 100;

        // 4
        var Eb = ((Ean * Kra) * (Kra + Kab)) * (Kra + 0.25 * Klvl);

        // 5
        return Math.max(0, Math.min(Config.s_config.consts.MAX_EBN, Eb));
    }

    private static function ChanceFuncT(vi1, vi2, team, stat, dead): Number
    {
        var Td = (vi1.tiers[0] + vi1.tiers[1]) / 2.0 - battleTier;

        var Tmin = vi1.tiers[0];
        var Tmax = vi1.tiers[1];
        var T = battleTier;
        var Bt = stat.tb || 0;
        var Et = stat.teff || 0;
        var Rt = stat.tr || 0;
        var AvgW = vi2.avg.R ? vi2.avg.R * 100 : 49.5;
        var Ea = stat.xwn == null ? Config.s_config.consts.AVG_XVMSCALE : stat.xwn;
        var Ean = Ea + (Ea * (((stat.avglvl || T) - T) * 0.05));
        var Ra = stat.r || Config.s_config.consts.AVG_GWR;
        var Ba = stat.battles || Config.s_config.consts.AVG_BATTLES;

        // 1
        var Klvl = (Tmax + Tmin) / 2 - T;

        // 2
        var Ktb = (Bt <= 50) ? 0                           //    0..50  => 0
            : (Bt <= 500) ? (Bt - 50) / 1000               //  51..500  => 0..0.45
            : (Bt <= 1000) ? 0.45 + (Bt - 500) / 2000      //  501..1000 => 0.45..0.7
            : (Bt <= 2000) ? 0.7 + (Bt - 1000) / 4000      // 1001..2000 => 0.7..0.95
            : 0.95 + (Bt - 2000) / 8000;                   // 2000..     => 0.95..
        var Kab = (Ba <= 500) ? 0                          //   0..0.5k  => 0
            : (Ba <= 5000) ? (Ba - 500) / 10000            //  1k..5k => 0..0.45
            : (Ba <= 10000) ? 0.45 + (Ba - 5000) / 20000   //  5k..10k => 0.45..0.7
            : (Ba <= 20000) ? 0.7 + (Ba - 10000) / 40000   // 10k..20k => 0.7..0.95
            : 0.95 + (Ba - 20000) / 80000                  // 20k..    => 0.95..

        // 3
        var Krt = (100 + Rt - AvgW) / 100;
        var Kra = (100 + Ra - 48.5) / 100;

        // 4
        var Eb = (Et > 0)
            ? (((3 / 5 * (Et / 20) * Krt) * (Krt + Ktb)) +
                ((2 / 5 * Ean * Kra) * (Kra + Kab))) * (Kra + 0.25 * Klvl)
            : ((Ean * Kra) * (Kra + Kab)) * (Kra + 0.25 * Klvl);

        // 5
        return Math.max(0, Math.min(Config.s_config.consts.MAX_EBN, Eb));
    }

    private static function ChanceFuncX1(vi1, vi2, team, stat, dead): Number
    {
        if (dead)
            return 0;

        var Td = (vi1.tiers[0] + vi1.tiers[1]) / 2.0 - battleTier;

        var Tmin = vi1.tiers[0];
        var Tmax = vi1.tiers[1];
        var T = battleTier;
        var Ea = stat.xwn == null ? Config.s_config.consts.AVG_XVMSCALE : stat.xwn;
        var Ean = Ea + (Ea * (((stat.avglvl || T) - T) * 0.05));
        var Ra = stat.r || Config.s_config.consts.AVG_GWR;
        var Ba = stat.battles || Config.s_config.consts.AVG_BATTLES;

        // 1
        var Klvl = (Tmax + Tmin) / 2 - T;

        // 2
        var Kab = (Ba <= 500) ? 0                          //   0..0.5k  => 0
            : (Ba <= 5000) ? (Ba - 500) / 10000            //  1k..5k => 0..0.45
            : (Ba <= 10000) ? 0.45 + (Ba - 5000) / 20000   //  5k..10k => 0.45..0.7
            : (Ba <= 20000) ? 0.7 + (Ba - 10000) / 40000   // 10k..20k => 0.7..0.95
            : 0.95 + (Ba - 20000) / 80000                  // 20k..    => 0.95..

        // 3
        var Kra = (100 + Ra - 48.5) / 100;

        // 4
        var Eb = ((Ean * Kra) * (Kra + Kab)) * (Kra + 0.25 * Klvl);

        // 5
        return Math.max(0, Math.min(Config.s_config.consts.MAX_EBN, Eb));
    }

    private static function ChanceFuncX2(vi1, vi2, team, stat, dead): Number
    {
        if (dead)
            return 0;

        var Td = (vi1.tiers[0] + vi1.tiers[1]) / 2.0 - battleTier;

        var Tmin = vi1.tiers[0];
        var Tmax = vi1.tiers[1];
        var T = battleTier;
        var Bt = stat.tb || 0;
        var Et = stat.teff || 0;
        var Rt = stat.tr || 0;
        var AvgW = vi2.avg.R ? vi2.avg.R * 100 : 49.5;
        var Ea = stat.xwn == null ? Config.s_config.consts.AVG_XVMSCALE : stat.xwn;
        var Ean = Ea + (Ea * (((stat.avglvl || T) - T) * 0.05));
        var Ra = stat.r || Config.s_config.consts.AVG_GWR;
        var Ba = stat.battles || Config.s_config.consts.AVG_BATTLES;

        // 1
        var Klvl = (Tmax + Tmin) / 2 - T;

        // 2
        var Ktb = (Bt <= 50) ? 0                           //    0..50  => 0
            : (Bt <= 500) ? (Bt - 50) / 1000               //  51..500  => 0..0.45
            : (Bt <= 1000) ? 0.45 + (Bt - 500) / 2000      //  501..1000 => 0.45..0.7
            : (Bt <= 2000) ? 0.7 + (Bt - 1000) / 4000      // 1001..2000 => 0.7..0.95
            : 0.95 + (Bt - 2000) / 8000;                   // 2000..     => 0.95..
        var Kab = (Ba <= 500) ? 0                          //   0..0.5k  => 0
            : (Ba <= 5000) ? (Ba - 500) / 10000            //  1k..5k => 0..0.45
            : (Ba <= 10000) ? 0.45 + (Ba - 5000) / 20000   //  5k..10k => 0.45..0.7
            : (Ba <= 20000) ? 0.7 + (Ba - 10000) / 40000   // 10k..20k => 0.7..0.95
            : 0.95 + (Ba - 20000) / 80000                  // 20k..    => 0.95..

        // 3
        var Krt = (100 + Rt - AvgW) / 100;
        var Kra = (100 + Ra - 48.5) / 100;

        // 4
        var Eb = (Et > 0)
            ? (((3 / 5 * (Et / 20) * Krt) * (Krt + Ktb)) +
                ((2 / 5 * Ean * Kra) * (Kra + Kab))) * (Kra + 0.25 * Klvl)
            : ((Ean * Kra) * (Kra + Kab)) * (Kra + 0.25 * Klvl);

        // 5
        return Math.max(0, Math.min(Config.s_config.consts.MAX_EBN, Eb));
    }

    // return: { ally: Number, enemy: Number }
    private static function CalculateTeamPlayersCount(): Object
    {
        var nally = 0;
        var nenemy = 0;
        for (var pname in StatData.s_data)
        {
            var pdata = StatData.s_data[pname];
            if (pdata.vehicleKey == "UNKNOWN" || pdata.vehicleKey == "OBSERVER") // skip unknown tanks in Fog of War mode and observer
                continue;
            if (pdata.team == Defines.TEAM_ALLY) ++nally else ++nenemy;
        }
        return { ally: nally, enemy: nenemy };
    }

    private static function PrepareChanceResults(Ea, Ee, chanceFunc)
    {
        if (Ea == 0 && Ee == 0) Ea = Ee = 1;
        //Logger.add("Ea=" + Math.round(Ea) + " Ee=" + Math.round(Ee));

        var p = Math.max(0.05, Math.min(0.95, (0.5 + (Ea / (Ea + Ee) - 0.5) * 1.5))) * 100;

        // Normalize (5..95)
        return {
            ally_value: Math.round(Ea),
            enemy_value: Math.round(Ee),
            percent: Math.round(p),
            raw: Ea / (Ea + Ee) * 100,
            percentF: Math.round(1000 * p) / 1000
        };
    }

    private static function GuessBattleTier(): Number
    {
        // 1. Collect all vehicles info
        var vis: Array = [];
        for (var pname in StatData.s_data)
        {
            var pdata = StatData.s_data[pname];
            var vi1 = VehicleInfo.getInfo1(pdata.icon);
            if (!vi1) {
                var vn = VehicleInfo.getVehicleName(pdata.icon);
                if (vn == "ussr-Observer")
                    continue;
                return 0;
            }
            var vi2 = VehicleInfo.getInfo2(pdata.icon);
            if (!vi2)
                return 0;
            vis.push( {
                level: vi2.level,
                Tmin: vi1.tiers[0],
                Tmax: vi1.tiers[1]
            });
        }

        // 2. Sort vehicles info by top tiers descending
        vis.sortOn("Tmax", Array.NUMERIC | Array.DESCENDING);

        // 3. Find minimum Tmax and maximum Tmin
        var Tmin = vis[0].Tmin;
        var Tmax = vis[0].Tmax;
        //Logger.add("T before=" + Tmin + ".." + Tmax);
        var vis_length = vis.length;
        for (var i = 1; i < vis_length; ++i)
        {
            var vi = vis[i];
            //Logger.add("l=" + vi.level + " Tmin=" + vi.Tmin + " Tmax=" + vi.Tmax);
            if (vi.Tmax < Tmin) // Skip "trinkets"
                continue;
            if (vi.Tmin > Tmin)
                Tmin = vi.Tmin;
            if (vi.Tmax < Tmax)
                Tmax = vi.Tmax;
        }
        //Logger.add("T after=" + Tmin + ".." + Tmax);

        //// 4. Calculate average tier
        //return (Tmax + Tmin) / 2.0;
        // 4. Return max tier
        return Tmax;
    }

    private static function FormatChangeText(txt, chance)
    {
        var htmlText = (txt && txt != "") ? txt + ": " : "";
        if (!chance)
            htmlText += "xx%";
        else
        {
            var color = GraphicsUtil.brightenColor(GraphicsUtil.GetDynamicColorValueInt(Defines.DYNAMIC_COLOR_RATING, chance.raw), 50);
            htmlText += "<font color='#" + color.toString(16) + "'>" + chance.percent + "%</font>";
        }

        return htmlText;
    }
}