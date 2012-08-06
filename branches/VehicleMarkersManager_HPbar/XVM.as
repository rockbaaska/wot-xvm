﻿/**
 * ...
 * @author Nicolas Siver
 * @author bkon
 * @author sirmax2
 * @author STL1te
 */
import com.greensock.TimelineLite;
import com.greensock.TweenLite;
import com.greensock.easing.Linear;
import com.greensock.easing.Cubic;
import net.wargaming.controls.UILoaderAlt
import wot.utils.Config;
import wot.utils.Defines;
import wot.utils.GlobalEventDispatcher;
import wot.utils.GraphicsUtil;
import wot.utils.IconLoader;
import wot.utils.StatData;
import wot.utils.StatFormat;
import wot.utils.StatLoader;
import wot.utils.Utils;
import wot.utils.Logger;
import wot.utils.PlayerInfo;
import wot.VehicleMarkersManager.ErrorHandler;
import wot.VehicleMarkersManager.Watermark

/*
 * XVM() instance creates corresponding marker
 * each time some player gets in line of sight.
 * Instantiated 14 times at normal round start.
 * Destructed when player get out of sight.
 * Thus may be instantiated ~50 times and more.
 */

class wot.VehicleMarkersManager.XVM extends net.wargaming.ingame.VehicleMarker
{
    static var DEBUG_TIMES = false;

    // UI Elements
    var damageHolder: MovieClip;
    var xvmHB: MovieClip;
    var xvmHBBorder: MovieClip;
    var xvmHBFill: MovieClip;
    var xvmHBDamage: MovieClip;

    // Private static members
    var s_blowedUp: Array = [];
    var s_isColorBlindMode = false;

    // Private members
    var m_showExInfo: Boolean = false;
    var m_currentHealth: Number;
    var m_showMaxHealth: Boolean;
    var m_team: String;
    var m_isDead: Boolean = false;
    var m_clanIcon: UILoaderAlt = null;
    var m_iconset: IconLoader;

    // TextFields
    var textFields: Object = null;

    // Healthbar Settings
    var hbCfg: Object = null;

    // All stated
    var allStatesAlly: Array = [
        "ally/alive/normal", "ally/alive/extended", "ally/dead/normal", "ally/dead/extended"
    ]
    var allStatesEnemy: Array = [
        "enemy/alive/normal", "enemy/alive/extended", "enemy/dead/normal", "enemy/dead/extended"
    ]

    function XVM()
    {
        //Logger.add("_global.gfxExtensions = " + _global.gfxExtensions);
        //Logger.add("_global.noInvisibleAdvance = " + _global.noInvisibleAdvance);
        if (!_global.noInvisibleAdvance)
            _global.noInvisibleAdvance = true;

        super();

        Utils.TraceXvmModule("XVM");

        Config.LoadConfig("XVM.as", undefined, true);
    }

    private var _initialized = false;
    function XVMInit(event)
    {
        //Logger.add("XVMInit()" + (event ? ": event=" + event.type : ""));
        if (event)
            GlobalEventDispatcher.removeEventListener("config_loaded", this, XVMInit);

        if (_initialized)
            return;
        _initialized = true;

        try
        {
            // Draw watermark
            Watermark.setComponent(_global);

            if (Config.s_config.battle.useStandardMarkers)
                return;


            xvmHB = createEmptyMovieClip("xvmHB", marker.getDepth() - 1); // Put health Bar to back.
            xvmHBBorder = xvmHB.createEmptyMovieClip("border", 1);
            xvmHBDamage = xvmHB.createEmptyMovieClip("damage", 2);
            xvmHBFill = xvmHB.createEmptyMovieClip("fill", 3);

            damageHolder = createEmptyMovieClip("damageHolder", this.getNextHighestDepth());

            // Remove standard fields
            pNameField._visible = false;
            pNameField.removeTextField();

            vNameField._visible = false;
            vNameField.removeTextField();

            healthBar.stop();
            healthBar._visible = false;
            healthBar.removeMovieClip();

            bgShadow.stop();
            bgShadow._visible = false;
            bgShadow.removeMovieClip();

            // Load stat
            XVMInit2();
            if (Config.s_config.rating.showPlayersStatistics && !StatData.s_loaded)
            {
                GlobalEventDispatcher.addEventListener("stat_loaded", this, XVMInit2);
                StatLoader.LoadLastStat();
            }
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMInit():" + String(e));
        }
    }



    function XVMInit2(event)
    {
        //ErrorHandler.setText("XVMStatLoaded()" + (event ? ": event=" + event.type : ""));
        //Logger.add("XVMStatLoaded()" + (event ? ": event=" + event.type : ""));
        if (event)
          GlobalEventDispatcher.removeEventListener("stat_loaded", this, XVMInit2);
        XVMPopulateData();
        updateMarkerLabel();
        XVMUpdateStyle("XVMInit2(event)");
    }

    function setDefaultVehicleMarkerPosition()
    {
        for (var childName in marker.marker)
            marker.marker[childName]._y = 16;
        marker._y = -16;
    }

    // override
    function init(vClass, vIconSource, vType, vLevel, pFullName, curHealth, maxHealth, entityName, speaking, hunt)
    {
        //Logger.add("XVM::init(): Config.s_loaded=" + Config.s_loaded);
        // Use currently remembered extended / normal status for new markers
        m_showExInfo = s_showExInfo;
        m_isDead = curHealth <= 0;

        super.init(vClass, vIconSource, vType, vLevel, pFullName, curHealth, maxHealth, entityName, speaking, hunt);
    }

    // override
    function updateMarkerSettings()
    {
        //Logger.add("XVM::updateMarkerSettings(): Config.s_loaded=" + Config.s_loaded);
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
        {
            super.updateMarkerSettings();
            setDefaultVehicleMarkerPosition();
        }
    }

    // override
    function setSpeaking(value)
    {
        super.setSpeaking(value);
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
            return;

        if (marker._visible != m_speaking)
            XVMUpdateStyle("ov: setSpeaking(value)");
    }
    
    /***************/
    
    // override
    function populateData()
    {
        ErrorHandler.setText("populateData()  ");   // ######
        Logger.add("XVM::populateData(): Config.s_loaded=" + Config.s_loaded);
        
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
            return super.populateData();

        //super.populateData();

        //Logger.add("populateData(): " + getCurrentStateString() + " markerState=" + m_markerState + " pname=" + m_playerFullName);

        if (m_isPopulated)
            return false;
        m_isPopulated = true;

        initMarkerLabel();

        setupIconLoader();

        if (levelIcon != null)
            levelIcon.gotoAndStop(m_level);

        if (m_vehicleClass != null)
            this.setVehicleClass();

        if (m_markerState != null)
            marker.gotoAndPlay(m_markerState);

        XVMPopulateData();        
        XVMSetupNewHealth(m_curHealth);

        return true;
    }

    // override
    function updateHealth(curHealth)
    {
        //ErrorHandler.setText("ov: updateHealth(curHealth)  ");
        Logger.add("XVM::updateHealth(curHealth): curHealth=" + curHealth);
        
        if (Config.s_config.battle.useStandardMarkers)
        {
            super.updateHealth(curHealth);
            return;
        }

        if (curHealth < 0)
            s_blowedUp.push(m_playerFullName);
        m_isDead = curHealth <= 0;
        m_curHealth = m_isDead ? 0 : curHealth; // fix "-1"
        
        XVMSetupNewHealth(curHealth);
        XVMUpdateUI(curHealth);
    }
    
    // Health Visualization
    function XVMSetupNewHealth(curHealth)
    {
        //ErrorHandler.setText("SetupNewHealth(curHealth)  ");
        Logger.add("SetupNewHealth(curHealth): curHealth=" + curHealth);
        /* Called by
         * overriden populateData()
         * overriden updateHealth()
         */
        try
        {
            var delta: Number = curHealth - m_currentHealth;
            if (delta < 0)
            {
                XVMUpdateHealthBar(curHealth, m_maxHealth); // colorizing health bar after taking damage

                XVMShowDamage(curHealth, -delta);

                m_currentHealth = curHealth;

                //Flow bar animation
                TweenLite.killTweensOf(xvmHBDamage);
                xvmHBDamage._x = hbCfg.border.size + hbCfg.width * (curHealth / m_maxHealth) - 1;
                xvmHBDamage._xscale = xvmHBDamage._xscale + 100 * (-delta / m_maxHealth);
                GraphicsUtil.setColor(xvmHBDamage, XVMFormatDynamicColor(hbCfg.damage.color, curHealth));
                xvmHBDamage._alpha = XVMFormatDynamicAlpha(hbCfg.damage.alpha, curHealth);
                TweenLite.to(xvmHBDamage, hbCfg.damage.fade, {_xscale: 0, ease: Cubic.easeIn });
            }
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMSetupNewHealth():" + String(e));
        }
    }
    
    function XVMUpdateHealthBar(curHealth)
    {
        //ErrorHandler.setText("UpdateHealthBar(curHealth)  ")
        Logger.add("  UpdateHealthBar(curHealth): curHealth=" + curHealth);
        
        /* Called by
         * XVMSetupNewHealth() - Health Visualization
         * XVMDrawHealthBar()
         * XVMUpdateStyle()
         */
        try
        {
            if (!Config.s_loaded)
                return;

            var cfg = getCurrentStateConfigRoot().healthBar;

            xvmHB._alpha = XVMFormatDynamicAlpha(cfg.alpha, curHealth);

            var ct = XVMFormatStaticColorText(cfg.color);
            var lct = XVMFormatStaticColorText(cfg.lcolor);
            var fullColor: Number = XVMFormatDynamicColor(ct, curHealth);
            var lowColor: Number = XVMFormatDynamicColor(lct || ct, curHealth);

            var percent: Number = curHealth / m_maxHealth;

            // determ current (real-time) color
            var currColor = GraphicsUtil.colorByRatio(percent, lowColor, fullColor);

            GraphicsUtil.setColor(xvmHBFill, currColor); // colorizing health bar
            xvmHBFill._alpha = XVMFormatDynamicAlpha(cfg.fill.alpha, curHealth);

            GraphicsUtil.setColor(xvmHBBorder, XVMFormatDynamicColor(cfg.border.color, curHealth));
            xvmHBBorder._alpha = XVMFormatDynamicAlpha(cfg.border.alpha, curHealth);

            GraphicsUtil.setColor(xvmHBDamage, XVMFormatDynamicColor(cfg.damage.color, curHealth));
            xvmHBDamage._alpha = XVMFormatDynamicAlpha(cfg.damage.alpha, curHealth);

            //Logger.add("color: " + cfg.color + " => " + currColor);
            //if (cfg.alpha == "{{a:hp-ratio}}")
            //    Logger.add(Math.round(percent * 100) + " => " + Math.round(xvmHB._alpha));
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: updateCurrentColor():" + String(e));
        }
    }
    
    function XVMDrawHealthBar(cfg)
    {
        //ErrorHandler.setText("DrawHealthBar(cfg)  ")
        Logger.add("DrawHealthBar(cfg)");
        
        // Called by XVMPopulateData()
        xvmHB.clear();
        xvmHBBorder.clear();
        xvmHBFill.clear();
        xvmHBDamage.clear();

        hbCfg = cfg;

        //GraphicsUtil.fillRect(xvmHB, 0, 0, hbCfg.width + 2 * hbCfg.border, hb.height + 2 * hb.border,
        //    cfg.healthBar.border.color, cfg.healthBar.border.alpha);
        GraphicsUtil.fillRect(xvmHBBorder, 0, 0, cfg.width + cfg.border.size * 2, cfg.height + cfg.border.size * 2);
        GraphicsUtil.fillRect(xvmHBFill, cfg.border.size, cfg.border.size, cfg.width, cfg.height);
        GraphicsUtil.fillRect(xvmHBDamage, cfg.border.size, cfg.border.size, cfg.width, cfg.height);

        xvmHBDamage._xscale = 0;

        XVMUpdateHealthBar(m_curHealth);
    }

    /***************/
    
    // override
    function updateState(newState, isImmediate)
    {
        //Logger.add("XVM::updateState(): Config.s_loaded=" + Config.s_loaded);
        if (Config.s_config.battle.useStandardMarkers)
        {
            super.updateState(newState, isImmediate);
            return;
        }

        Logger.add("updateState(): " + getCurrentStateString() + " markerState=" + m_markerState + " pname=" + m_playerFullName);
        super.updateState(newState, isImmediate);
        XVMUpdateStyle("ov: updateState(newState, isImmediate)");
    }

    // override
    function showExInfo(show)
    {
        //Logger.add("XVM::showExInfo(): Config.s_loaded=" + Config.s_loaded);
        if (Config.s_config.battle.useStandardMarkers)
        {
            super.showExInfo(show);
            return;
        }

        if (m_showExInfo == show)
            return;
        m_showExInfo = show;

        // Save current extended / normal state flag to static variable, so
        // new markers can refer to it when rendered initially
        s_showExInfo = show;

        XVMUpdateStyle("ov: showExInfo(show)");
    }

    // override
    function configUI()
    {
        //Logger.add("XVM::configUI(): Config.s_loaded=" + Config.s_loaded);
        //Logger.add("configUI(): " + getCurrentStateString() + " markerState=" + m_markerState + " pname=" + m_playerFullName);
        m_currentHealth = m_curHealth;
        super.configUI();
        if (Config.s_loaded)
            XVMInit();
        else
            GlobalEventDispatcher.addEventListener("config_loaded", this, XVMInit);
    }

    // override
    function setupIconLoader()
    {
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
        {
            super.setupIconLoader();
            return;
        }

        // Alternative icon set
        if (!m_iconset)
            m_iconset = new IconLoader(this, completeLoad);
        m_iconset.init(iconLoader,
            [ m_source.split(Defines.CONTOUR_ICON_PATH).join(Config.s_config.iconset.vehicleMarker), m_source ]);
        iconLoader.source = m_iconset.currentIcon;
    }

    // override
    function initMarkerLabel()
    {
        //Logger.add("XVM::initMarkerLabel(): Config.s_loaded=" + Config.s_loaded);
        super.initMarkerLabel();
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
        {
            setDefaultVehicleMarkerPosition();
            return;
        }

        XVMUpdateMarkerLabel();
        XVMUpdateUI(m_curHealth);
    }

    // override
    function updateMarkerLabel()
    {
        //Logger.add("XVM::updateMarkerLabel(): Config.s_loaded=" + Config.s_loaded);
        Logger.add("ov: updateMarkerLabel(): " + getCurrentStateString() + " markerLabel=" + m_markerLabel + " pname=" + m_playerFullName);
        super.updateMarkerLabel();
        if (Config.s_config.battle.useStandardMarkers)
        {
            setDefaultVehicleMarkerPosition();
            return;
        }

        XVMUpdateMarkerLabel();

        XVMIconCompleteLoad();

        // Update layout for the current marker state
        XVMUpdateStyle("updateMarkerLabel()");
    }

    // override
    function _centeringIcon()
    {
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
            super._centeringIcon();
    }

    /**
    * MAIN
    */

    function completeLoad()
    {
        if (!Config.s_loaded || Config.s_config.battle.useStandardMarkers)
            return;

        iconLoader._visible = false;
        onEnterFrame = function()
        {
            delete this.onEnterFrame;
            this.XVMIconCompleteLoad();
        };
    }

    // VehicleMarkerAlly should contain 4 named frames:
    // - green - normal ally
    // - gold - squad mate
    // - blue - teamkiller
    // - yellow - squad mate in color blind mode
    // VehicleMarkerEnemy should contain 2 named frames:
    // - red - normal enemy
    // - purple - enemy in color blind mode
    /*function XVMGetMarkerColorAlias()
    {
        //if (m_entityName != "ally" && m_entityName != "enemy" && m_entityName != "squadman" && m_entityName != "teamKiller")
        //  Logger.add("m_entityName=" + m_entityName);
        if (m_entityName == "ally")
            return "green";
        if (m_entityName == "squadman")
            return s_isColorBlindMode ? "yellow" : "gold";
        if (m_entityName == "teamKiller")
            return "blue";
        if (m_entityName == "enemy")
            return s_isColorBlindMode ? "purple" : "red";

        // if not found (node is not implemented), return inverted enemy color
        return s_isColorBlindMode ? "red" : "purple";
    }*/

    function XVMGetSystemColor()
    {
        var systemColorName: String = m_entityName + "_";
        systemColorName += (!vehicleDestroyed && !m_isDead) ? "alive_" : (Utils.indexOf(s_blowedUp, m_playerFullName) >= 0) ? "blowedup_" : "dead_";
        systemColorName += s_isColorBlindMode ? "blind" : "normal";
        return Config.s_config.colors.system[systemColorName];
    }

    function getCurrentStateString(): String
    {
        var result = m_team + "/";
        result += (vehicleDestroyed || m_isDead) ? "dead/" : "alive/";
        result += m_showExInfo ? "extended" : "normal";
        return result;
    }

    function getStateConfigRoot(stateString: String)
    {
        // stateString example: "ally/alive/normal"
        var path: Array = stateString.split("/");
        if (path.length != 3)
            return null;
        var result = Config.s_config.markers;
        result = path[0] == "ally" ? result.ally : result.enemy;
        result = path[1] == "alive" ? result.alive : result.dead;
        result = path[2] == "normal" ? result.normal : result.extended;
        return result;
    }

    function getCurrentStateConfigRoot()
    {
        return getStateConfigRoot(getCurrentStateString());
    }

    function getCurrentStateConfigRootNormal()
    {
        return getStateConfigRoot(getCurrentStateString().split("extended").join("normal"));
    }

    function XVMFormatStaticText(format: String): String
    {
        try
        {
            // AS 2 doesn't have String.replace? Shame on them. Let's use our own square wheel.
            format = format.split("{{nick}}").join(m_playerFullName);
            format = format.split("{{vehicle}}").join(m_vname);
            format = format.split("{{level}}").join(String(m_level));
            format = StatFormat.FormatText({ label: m_playerFullName }, format);
            format = Utils.trim(format);
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMFormatStaticText(" + format + "):" + String(e));
        }
        return format;
    }

    function XVMFormatDynamicText(format: String, curHealth: Number, delta: Number): String
    {
        try
        {
            if (format.indexOf("{{") == -1)
                return format;

            var hpRatio: Number = Math.ceil(curHealth / m_maxHealth * 100);
            format = format.split("{{hp}}").join(String(curHealth));
            format = format.split("{{hp-max}}").join(String(m_maxHealth));
            format = format.split("{{hp-ratio}}").join(String(hpRatio));

            var dmgRatio: Number = delta ? Math.ceil(delta / m_maxHealth * 100) : 0;
            format = format.split("{{dmg}}").join(delta ? String(delta) : "");
            format = format.split("{{dmg-ratio}}").join(delta ? String(dmgRatio) : "");

            format = Utils.trim(format);
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMFormatDynamicText(" + format + "):" + String(e));
        }

        return format;
    }

    function XVMFormatStaticColorText(format: String): String
    {
        try
        {
            if (!format || isFinite(format))
                return format;

            format = StatFormat.FormatText( { label: m_playerFullName }, format).split("#").join("0x");
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMFormatStaticColorText(" + format + "):" + String(e));
        }

        return format;
    }

    function XVMFormatDynamicColor(format: String, curHealth: Number): Number
    {
        var systemColor = XVMGetSystemColor();
        try
        {
            if (!format)
                return systemColor;

            if (isFinite(format))
                return Number(format);

            var hpRatio: Number = Math.ceil(curHealth / m_maxHealth * 100);
            var formatArr = format.split("{{c:hp}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_HP, curHealth, "0x"))
            formatArr = format.split("{{c:hp-ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_HP_RATIO, hpRatio, "0x"))
            formatArr = format.split("{{c:hp_ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_HP_RATIO, hpRatio, "0x"))
            return isFinite(format) ? Number(format) : systemColor;
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMFormatDynamicColor(" + format + "):" + String(e));
        }

        return systemColor;
    }

    function XVMFormatDynamicAlpha(format: String, curHealth: Number): Number
    {
        try
        {
            if (!format)
                return 100;

            if (isFinite(format))
                return Number(format);

            var hpRatio: Number = Math.ceil(curHealth / m_maxHealth * 100);
            var formatArr = format.split("{{a:hp}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicAlphaValue(Defines.DYNAMIC_ALPHA_HP, curHealth).toString());
            formatArr = format.split("{{a:hp-ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicAlphaValue(Defines.DYNAMIC_ALPHA_HP_RATIO, hpRatio).toString());
            formatArr = format.split("{{a:hp_ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicAlphaValue(Defines.DYNAMIC_ALPHA_HP_RATIO, hpRatio).toString());

            var n = isFinite(format) ? Number(format) : 100;
            return (n <= 0) ? 1 : (n > 100) ? 100 : n;
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMFormatDynamicAlpha(" + format + "):" + String(e));
        }

        return 100;
    }

    function XVMCreateNewTextFormat(config_font: Object): TextFormat
    {
        try
        {
            if (!config_font)
                return null;

            return new TextFormat(
                config_font.name || "$FieldFont",
                config_font.size || 13,
                0x000000,
                config_font.bold,
                false, false, null, null,
                config_font.align || "center",
                0, 0, 0, 0);
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMCreateNewTextFormat():" + String(e));
        }

        return null;
    }

    function XVMCreateTextField(cfg)
    {
        try
        {
            var n = getNextHighestDepth();
            var textField: TextField = createTextField("textField" + n, n, 0, 0, 140, 31);
            textField.html = false; // FIXIT: in html mode Font and Position are wrong.
            textField.embedFonts = true;
            textField.selectable = false;
            textField.multiline = false;
            textField.wordWrap = false;
            textField.antiAliasType = "normal";
            //textField.antiAliasType = "advanced";
            //textField.gridFitType = "none";
            //textField.autoSize = "center"; // http://theolagendijk.com/2006/09/07/aligning-htmltext-inside-flash-textfield/
            var textFormat: TextFormat = XVMCreateNewTextFormat(cfg.font);
            textField.setNewTextFormat(textFormat);
            textField.filters = [ GraphicsUtil.createShadowFilter(cfg.shadow) ];

            var staticColor = XVMFormatStaticColorText(cfg.color);
            textField.textColor = XVMFormatDynamicColor(staticColor, m_curHealth);
            textField._alpha = XVMFormatDynamicAlpha(cfg.alpha, m_curHealth);
            textField._x = cfg.x - (textField._width >> 1);
            textField._y = cfg.y - (textField._height >> 1);
            textField._visible = cfg.visible;

            return { field: textField, format: XVMFormatStaticText(cfg.format), alpha: cfg.alpha, color: staticColor };
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMCreateTextField():" + String(e));
        }

        return null;
    }

    // Damage Visualization
    function removeTextField(f: TextField)
    {
        f.removeTextField();
    }

    function XVMShowDamage(curHealth, delta)
    {
        try
        {
            var cfg = getCurrentStateConfigRoot().damageText;

            if (!cfg.visible)
                return;

            var msg = (curHealth < 0) ? cfg.blowupMessage : cfg.damageMessage;
            var text = XVMFormatDynamicText(XVMFormatStaticText(msg), curHealth, delta);

            var n = damageHolder.getNextHighestDepth();
            var damageField: TextField = damageHolder.createTextField("damageField" + n, n, 0, 0, 140, 20);
            var animation: TimelineLite = new TimelineLite({ onComplete:this.removeTextField, onCompleteParams:[damageField] });

            // For some reason, DropShadowFilter is not rendered when textfield contains only one character,
            // so we're appending empty prefix and suffix to bypass this unexpected behavior
            damageField.text = " " + text + " ";
            damageField.antiAliasType = "advanced";
            damageField.autoSize = "left";
            damageField.border = false;
            damageField.embedFonts = true;
            damageField.setTextFormat(XVMCreateNewTextFormat(cfg.font));
            damageField.textColor = isFinite(cfg.color) ? Number(cfg.color)
                : Config.s_config.colors.system[m_entityName + "_alive_" + (s_isColorBlindMode ? "blind" : "normal")];
            damageField._x = -(damageField._width >> 1);
            damageField.filters = [ GraphicsUtil.createShadowFilter(cfg.shadow) ];

            animation.insert(new TweenLite(damageField, cfg.speed, { _y: -cfg.maxRange, ease: Linear.easeOut } ), 0);
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: showDamage():" + String(e));
        }
    }

    function XVMUpdateMarkerLabel()
    {
        // Guess color blind mode
        if (m_markerLabel == "yellow" || m_markerLabel == "purple")
            s_isColorBlindMode = true;
        else if (m_markerLabel == "gold" || m_markerLabel == "red")
            s_isColorBlindMode = false;

        // Hide original fields
        if (pNameField != null)
        {
            pNameField._visible = false;
            pNameField.removeTextField();
        }
        if (vNameField != null)
        {
            vNameField._visible = false;
            vNameField.removeTextField();
        }
    }

    function XVMUpdateUI(curHealth)
    {
        try
        {
            xvmHBFill._xscale = Math.min(curHealth / m_maxHealth * 100, 100);

            if (textFields)
            {
                var st = getCurrentStateString();
                for (var i in textFields[st])
                {
                    var tf = textFields[st][i];
                    tf.field.text = XVMFormatDynamicText(tf.format, curHealth);
                    //tf.field.htmlText = "<p align='center'><font face='$FieldFont'>" + XVMFormatDynamicText(tf.format, curHealth) + "</font></p>";
                    tf.field.textColor = XVMFormatDynamicColor(tf.color, curHealth);
                    tf.field._alpha = XVMFormatDynamicAlpha(tf.alpha, curHealth);
                }
            }
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMUpdateUI():" + String(e));
        }
    }

    function XVMIconCompleteLoad(event)
    {
        try
        {
            if (!Config.s_loaded)
                return;

            // Vehicle Icon
            var cfg = getCurrentStateConfigRootNormal().contourIcon;

            if (cfg.amount >= 0)
            {
                var tintColor: Number = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.color), m_curHealth);
                var tintAmount: Number = Math.min(100, Math.max(0, cfg.amount)) * 0.01;
                GraphicsUtil.setColor(iconLoader, tintColor, tintAmount);
                //var _loc2 = new flash.geom.Transform(iconLoader);
                //_loc2.colorTransform = this.__get__colorsManager().getTransform(this.__get__colorSchemeName());
            }

            XVMUpdateStyle("XVMIconCompleteLoad(event)");
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMIconCompleteLoad():" + String(e));
        }
    }

    function XVMInitializeStates()
    {
        try
        {
            if (!m_vname || !m_playerFullName)
                return;

            // cleanup
            if (textFields)
            {
                for (var st in textFields)
                {
                    for (var i in textFields[st])
                    {
                        var tf = textFields[st][i];
                        tf.field.removeTextField();
                        delete tf;
                    }
                }
            }

            textFields = { };
            var allStates = (m_team == "enemy") ? allStatesEnemy : allStatesAlly;
            for (var stid in allStates)
            {
                var st = allStates[stid];
                var cfg = getStateConfigRoot(st);

                // create text fields
                var fields: Array = [];
                for (var i in cfg.textFields)
                {
                    if (cfg.textFields[i].visible)
                    {
                        //if (m_team == "ally")
                        //    Logger.addObject(cfg.textFields[i], m_vname + " " + m_playerFullName + " " + st);
                        //if (m_team == "enemy")
                        //    Logger.addObject(cfg.textFields[i], m_vname + " " + m_playerFullName + " " + st);
                        fields.push(XVMCreateTextField(cfg.textFields[i]));
                    }
                }
                textFields[st] = fields;
            }
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMInitializeStates():" + String(e));
        }
    }

    function XVMInitializeClanIcon(cfg)
    {
        if (m_clanIcon == null)
            m_clanIcon = PlayerInfo.createIcon(this, cfg, cfg.x - (cfg.w / 2.0), cfg.y - (cfg.h / 2.0), Defines.TEAM_ALLY);
        PlayerInfo.setSource(m_clanIcon, Utils.GetPlayerName(m_playerFullName), Utils.GetClanName(m_playerFullName));
    }

    function XVMPopulateData()
    {
        try
        {
            //Logger.add("XVMPopulateData: " + m_vname + " " + m_playerFullName);
            if (!Config.s_loaded)
                return;

            var start = new Date();

            var cfg = getCurrentStateConfigRootNormal();

            // Vehicle Type Icon
            if (iconLoader != null && iconLoader.initialized)
                setupIconLoader();

            // Health Bar
            XVMDrawHealthBar(cfg.healthBar);

            // Initialize states and creating text fields
            XVMInitializeStates();

            // Initialize clan icons
            XVMInitializeClanIcon(cfg.clanIcon);

            if (DEBUG_TIMES)
                Logger.add("DEBUG TIME: XVMPopulateData(): " + Utils.elapsedMSec(start, new Date()) + " ms");
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMPopulateData():" + String(e));
        }
    }

    function XVMUpdateStyle(caller:String)
    {
        /*
         * Called by
         * XVMInit2(event)
         * ov: setSpeaking(value)
         * ov: updateState(newState, isImmediate)
         * ov: showExInfo(show)
         * ov: updateMarkerLabel()
         * XVMIconCompleteLoad(event)
         */
        Logger.add("X UpdateStyle() caller: " + caller);
        try
        {
            //Logger.add("XVMUpdateStyle: " + m_vname + " " + m_playerFullName + " scale=" + marker._xscale);
            if (!Config.s_loaded)
                return;

            var start = new Date();

            var cfg = getCurrentStateConfigRoot();

            var visible: Boolean;

            // Vehicle Type Marker
            visible = cfg.vehicleIcon.visible || (m_speaking && cfg.vehicleIcon.showSpeaker);
            if (visible)
            {
                // Vehicle Type Marker
                //var systemColor = XVMGetSystemColor();
                var x = cfg.vehicleIcon.scaleX * cfg.vehicleIcon.maxScale / 100;
                var y = cfg.vehicleIcon.scaleY * cfg.vehicleIcon.maxScale / 100;
                for (var childName in marker.marker)
                {
                    //if (childName == "marker_shadow")
                    //  return;

                    var icon: MovieClip = marker.marker[childName];
                    icon._x = x;
                    icon._y = y;
                    icon._xscale = icon._yscale = cfg.vehicleIcon.maxScale;

                    //var ms: MovieClip = icon.duplicateMovieClip("marker_shadow", icon.getNextHighestDepth());
                    //ms.gotoAndStop(icon._currentframe);
                    //ms.filters = [ new DropShadowFilter(0, 0, 0, 1, 1, 1, 10, 1, false, true) ];
                    //GraphicsUtil.setColor(icon, systemColor);
                }

                marker._x = cfg.vehicleIcon.x;
                marker._y = cfg.vehicleIcon.y;
                marker._alpha = XVMFormatDynamicAlpha(cfg.vehicleIcon.alpha, m_curHealth);
            }
            marker._visible = visible;

            // Level Icon
            visible = cfg.levelIcon.visible;
            if (visible)
            {
                levelIcon._x = cfg.levelIcon.x;
                levelIcon._y = cfg.levelIcon.y;
                levelIcon._alpha = XVMFormatDynamicAlpha(cfg.levelIcon.alpha, m_curHealth);
            }
            levelIcon._visible = visible;

            // Action Marker
            visible = cfg.actionMarker.visible;
            if (visible)
            {
                actionMarker._x = cfg.actionMarker.x;
                actionMarker._y = cfg.actionMarker.y;
            }
            actionMarker._visible = visible;

            // Vehicle Icon
            if (iconLoader != null && iconLoader.initialized)
            {
                visible = cfg.contourIcon.visible;
                if (visible)
                {
                    iconLoader._x = cfg.contourIcon.x - (iconLoader.contentHolder._width >> 1);
                    iconLoader._y = cfg.contourIcon.y - (iconLoader.contentHolder._height >> 1);
                    iconLoader._alpha = XVMFormatDynamicAlpha(cfg.contourIcon.alpha, m_curHealth);
                }
                iconLoader._visible = visible;
            }

            // Clan Icon
            if (m_clanIcon != null && m_clanIcon.source != "")
            {
                visible = cfg.clanIcon.visible;
                if (visible)
                {
                    var holder = m_clanIcon["holder"];
                    holder._x = cfg.clanIcon.x - (cfg.clanIcon.w >> 1);
                    holder._y = cfg.clanIcon.y - (cfg.clanIcon.h >> 1);
                    m_clanIcon.setSize(cfg.clanIcon.w, cfg.clanIcon.h);
                    holder._alpha = XVMFormatDynamicAlpha(cfg.clanIcon.alpha, m_curHealth);
                }
                m_clanIcon._visible = visible;
            }

            // Damage Text
            visible = cfg.damageText.visible;
            if (visible)
            {
                damageHolder._x = cfg.damageText.x;
                damageHolder._y = cfg.damageText.y;
            }
            damageHolder._visible = visible;

            // Health Bar
            visible = cfg.healthBar.visible;
            if (visible)
            {
                xvmHB._x = cfg.healthBar.x;
                xvmHB._y = cfg.healthBar.y;
                xvmHB._alpha = XVMFormatDynamicAlpha(cfg.healthBar.alpha, m_curHealth);
            }
            xvmHB._visible = visible;

            // Text fields
            if (textFields)
            {
                var st = getCurrentStateString();
                for (var i in textFields)
                {
                    for (var j in textFields[i])
                        textFields[i][j].field._visible = (i == st);
                }
            }

            // Update Colors and Values
            XVMUpdateHealthBar(m_curHealth);
            XVMUpdateUI(m_curHealth);

            if (DEBUG_TIMES)
                Logger.add("DEBUG TIME: XVMUpdateStyle(): " + Utils.elapsedMSec(start, new Date()) + " ms");
        }
        catch (e)
        {
            ErrorHandler.setText("ERROR: XVMUpdateStyle():" + String(e));
        }
    }
}
