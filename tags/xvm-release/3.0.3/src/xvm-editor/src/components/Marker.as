﻿package components
{
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.text.AntiAliasType;
    import flash.text.GridFitType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    
    import mx.containers.Canvas;
    import mx.core.ScrollPolicy;
    import mx.core.UIComponent;
    import mx.events.FlexEvent;
    import mx.messaging.channels.StreamingAMFChannel;
    
    import spark.components.Image;
    
    import utils.ClassLoader;
    import utils.Config;
    import utils.Defines;
    import utils.DisplayObjectWrapper;
    import utils.GraphicsUtil;
    import utils.Utils;

    public class Marker extends UIComponent
    {
        [Embed(source="../assets/markers.swf", mimeType="application/octet-stream")]
        private const markersSWF: Class;

        [Embed(source="images/markers/clan1.png")]
        private const IMG_clan1: Class;
        [Embed(source="images/markers/clan2.png")]
        private const IMG_clan2: Class;
        [Embed(source="images/markers/ussr-IS-3.png")]
        private const IMG_contour1: Class;
        [Embed(source="images/markers/germany-Ferdinand.png")]
        private const IMG_contour2: Class;
        [Embed(source="images/markers/germany-Hummel.png")]
        private const IMG_contour3: Class;

        private var loader:ClassLoader;

        private var vehicleLevel:Number;
        private var vehicleClass:String;

        private var s_isColorBlindMode:Boolean = false; // TODO

        private var isInitialized:Boolean = false;

        private var _cfg: Object;
        private var _vtype:String = "ally";
        private var _vdead:Boolean = false;
        private var _zoom:Number = 1;
        private var _extmode:Boolean = false;
        private var m_maxHealth:Number = 1000;
        private var m_curHealth:Number = 1000;
        private var _actionMarkerVisible:Boolean = true;

        private var xvmHB: Canvas;
        private var xvmHBBorder: Canvas;
        private var xvmHBFill: Canvas;
        private var xvmHBDamage: Canvas;
        private var damageHolder: UIComponent;

        private var vehicleIcon:MovieClip;
        private var vehicleIconAlly:MovieClip;
        private var vehicleIconEnemy:MovieClip;
        private var contourIcon:Image = new Image();
        private var contourIconHolder: UIComponent;
        private var clanIcon:Image = new Image();
        private var levelIcon:MovieClip;
        private var actionMarkerHelp:MovieClip;
        private var actionMarkerVictim:MovieClip;
        private var actionMarkerArta:MovieClip;
        private var textFields: Array = [];

        public function Marker()
        {
        }

        public function init(vtype:String, vclass:String, vlevel:Number):void
        {
            this._vtype = vtype == "ally" || vtype == "ally_dead" ? "ally" : "enemy";
            this._vdead = vtype == "ally_dead" || vtype == "enemy_dead";
            this.vehicleClass = vclass;
            this.vehicleLevel = vlevel;

            // draw grid
            graphics.beginFill(0xFFFF00, 0.1);
            graphics.drawRect(-75, 0, 150, 1);
            graphics.endFill();
            graphics.beginFill(0xFFFF00, 0.1);
            graphics.drawRect(0, -75, 1, 150);
            graphics.endFill();

            xvmHB = new Canvas();
            xvmHB.horizontalScrollPolicy = xvmHB.verticalScrollPolicy = ScrollPolicy.OFF;
            xvmHBBorder = new Canvas();
            xvmHB.addChild(xvmHBBorder);
            xvmHBBorder.horizontalScrollPolicy = xvmHBBorder.verticalScrollPolicy = ScrollPolicy.OFF;
            xvmHBDamage = new Canvas();
            xvmHB.addChild(xvmHBDamage);
            xvmHBDamage.horizontalScrollPolicy = xvmHBDamage.verticalScrollPolicy = ScrollPolicy.OFF;
            xvmHBFill = new Canvas();
            xvmHB.addChild(xvmHBFill);
            xvmHBFill.horizontalScrollPolicy = xvmHBFill.verticalScrollPolicy = ScrollPolicy.OFF;
            addChild(xvmHB);
            xvmHB.includeInLayout = false;

            contourIconHolder = new UIComponent();
            contourIconHolder.includeInLayout = false;
            addChild(contourIconHolder);

            contourIcon.includeInLayout = false;
            contourIcon.source = _vdead ? new IMG_contour3()
                : _vtype == "ally" ? new IMG_contour1() : new IMG_contour2();
            contourIcon.width = 80;
            contourIcon.height = 24;

            contourIconHolder.visible = false;
            contourIconHolder.addChild(contourIcon);

            loadSWF(markersSWF);
        }

        private function loadSWF(swf_class:Class):void
        {
            loader = new ClassLoader();
            loader.addEventListener(ClassLoader.LOAD_ERROR,loadErrorHandler);
            loader.addEventListener(ClassLoader.CLASS_LOADED,classLoadedHandler);
            loader.load(swf_class);
        }

        private function loadErrorHandler(e:Event):void {
            throw new Error("Cannot load the specified file.");
        }

        private function classLoadedHandler(e:Event):void
        {
            vehicleIconAlly = CreateMC("markerAlly");
            vehicleIconEnemy = CreateMC("markerEnemy");
            levelIcon = CreateMC("level");
            actionMarkerHelp = CreateMC("actionHelp");
            actionMarkerVictim = CreateMC("actionVictim");
            actionMarkerArta = CreateMC("actionArta");

            clanIcon.includeInLayout = false;
            clanIcon.source =  _vtype == "ally" ? new IMG_clan1() : new IMG_clan2();
            clanIcon.visible = false;
            addChild(clanIcon);

            damageHolder = new UIComponent();
            damageHolder.includeInLayout = false;
            addChild(damageHolder);

            addEventListener(Event.ENTER_FRAME, PostInit);
        }

        private function CreateMC(className: String):MovieClip
        {
            var mc:MovieClip = new (loader.getClass(className))() as MovieClip;
            var dow:DisplayObjectWrapper = new DisplayObjectWrapper(mc);
            dow.content.visible = false;
            addChild(dow);
            return mc;
        }

        private function PostInit(event: Event):void
        {
            removeEventListener(Event.ENTER_FRAME, PostInit);

            vehicleIconAlly.marker.icon.gotoAndStop(vehicleClass);
            vehicleIconAlly.gotoAndPlay(_vdead == false ? "normal" : "immediate_dead");
            vehicleIconAlly.marker.scaleX = vehicleIconAlly.marker.scaleY = _zoom;
            vehicleIconAlly.visible = false;

            vehicleIconEnemy.marker.icon.gotoAndStop(vehicleClass);
            vehicleIconEnemy.gotoAndPlay(_vdead == false ? "normal" : "immediate_dead");
            vehicleIconEnemy.marker.scaleX = vehicleIconEnemy.marker.scaleY = _zoom;
            vehicleIconEnemy.visible = false;

            vehicleIcon = _vtype == "ally" ? vehicleIconAlly : vehicleIconEnemy;

            actionMarkerHelp.stop();
            actionMarkerHelp.visible = false;
            actionMarkerVictim.stop();
            actionMarkerVictim.visible = false;
            actionMarkerArta.stop();
            actionMarkerArta.visible = false;

            levelIcon.gotoAndStop(vehicleLevel);
            levelIcon.visible = false;

            isInitialized = true;

            update();
        }

        public function set zoom(value:Number):void
        {
            this._zoom = value;
            if (vehicleIcon)
                vehicleIcon.marker.scaleX = vehicleIcon.marker.scaleY = value;
        }

        public function set maxHP(value:Number):void
        {
            m_maxHealth = m_curHealth = value;
            update();
        }

        public function set extMode(value:Boolean):void
        {
            this._extmode = value;
            update();
        }

        public function set deadType(value:Boolean):void
        {
            this._vtype = value == true ? "enemy" : "ally";
            vehicleIcon.visible = false;
            vehicleIcon = value == true ? vehicleIconEnemy : vehicleIconAlly;
            vehicleIcon.marker.scaleX = vehicleIcon.marker.scaleY = _zoom;
            clanIcon.source = value ? new IMG_clan2() : new IMG_clan1();
            update();
        }

        public function update():void
        {
            if (!isInitialized)
                return;
            if (!Config.s_config || !Config.s_config.markers)
                return;
            var cfg:Object = Config.s_config.markers;
            cfg = _vtype == "ally" ? cfg.ally : cfg.enemy;
            cfg = _vdead == false ? cfg.alive : cfg.dead;
            cfg = _extmode ? cfg.extended : cfg.normal;
            _cfg = cfg;

            var c:Object;

            // vehicleIcon
            c = cfg.vehicleIcon;
            vehicleIcon.visible = c.visible || c.showSpeaker;
            vehicleIcon.marker.icon.gotoAndStop(c.visible ? vehicleClass : "dynamic");
            vehicleIcon.x = c.x;
            vehicleIcon.y = c.y;
            vehicleIcon.marker.alpha = XVMFormatDynamicAlpha(c.alpha, m_curHealth) / 100;
            vehicleIcon.marker.icon.x = c.scaleX * c.maxScale / 100;
            vehicleIcon.marker.icon.y = c.scaleY * c.maxScale / 100;
            vehicleIcon.marker.icon.scaleX = vehicleIcon.marker.icon.scaleY = c.maxScale / 100;

            // healthBar
            c = cfg.healthBar;
            xvmHB.visible = c.visible;
            xvmHB.x = c.x;
            xvmHB.y = c.y;
            xvmHB.alpha = XVMFormatDynamicAlpha(c.alpha, m_curHealth) / 100;

            // damageText
            c = cfg.damageText;
            damageHolder.visible = c.visible;
            damageHolder.x = c.x;
            damageHolder.y = c.y;

            // contourIcon
            c = cfg.contourIcon;
            contourIconHolder.visible = c.visible;
            contourIcon.x = c.x - contourIcon.width / 2.0;
            contourIcon.y = c.y - contourIcon.height / 2.0;
            var tintColor: Number = XVMFormatDynamicColor(XVMFormatStaticColorText(c.color), m_curHealth);
            var tintAmount: Number = Math.min(100, Math.max(0, c.amount)) * 0.01;
            GraphicsUtil.setColor(contourIcon, tintColor, tintAmount);
            contourIconHolder.alpha = XVMFormatDynamicAlpha(c.alpha, m_curHealth) / 100;

            // clanIcon
            c = cfg.clanIcon;
            clanIcon.visible = c.visible;
            clanIcon.x = c.x - c.w / 2.0;
            clanIcon.y = c.y - c.h / 2.0;
            clanIcon.width = c.w;
            clanIcon.height = c.h;
            clanIcon.alpha = XVMFormatDynamicAlpha(c.alpha, m_curHealth) / 100;

            // levelIcon
            c = cfg.levelIcon;
            levelIcon.visible = c.visible;
            levelIcon.x = c.x;
            levelIcon.y = c.y;
            levelIcon.alpha = XVMFormatDynamicAlpha(c.alpha, m_curHealth) / 100;

            // actionMarker
            c = cfg.actionMarker;
            _actionMarkerVisible = c.visible;
            if (actionMarkerHelp.isPlaying)
                actionMarkerHelp.visible = _actionMarkerVisible;
            if (actionMarkerVictim.isPlaying)
                actionMarkerVictim.visible = _actionMarkerVisible;
            if (actionMarkerArta.isPlaying)
                actionMarkerArta.visible = _actionMarkerVisible;
            actionMarkerHelp.x = actionMarkerVictim.x = actionMarkerArta.x = c.x;
            actionMarkerHelp.y = actionMarkerVictim.y = actionMarkerArta.y = c.y;
            actionMarkerHelp.alpha = actionMarkerVictim.alpha = actionMarkerArta.alpha = c.alpha / 100;

            // Update HB
            XVMUpdateHealthBar(m_curHealth);
            // Update Text Fields
            XVMUpdateUI(m_curHealth);
        }

        public function hit():void
        {
            var blowup:Boolean = Math.round(Math.random() * 5) == 0;
            var hp:Number = blowup ? -1 : m_curHealth - Math.min(m_curHealth, Math.round(Math.random() * 500) + 5);
            if (m_curHealth <= 0)
                hp = m_maxHealth;
            XVMSetupNewHealth(hp);
            update();
            //XVMUpdateUI(hp);
        }

        public function action():void
        {
            var mc:MovieClip;
            if (_vtype == "ally")
                mc = actionMarkerHelp;
            else
                mc = Math.round(Math.random()) == 0 ? actionMarkerVictim : actionMarkerArta;
            actionMarkerHelp.stop();
            actionMarkerHelp.visible = false;
            actionMarkerVictim.stop();
            actionMarkerVictim.visible = false;
            actionMarkerArta.stop();
            actionMarkerArta.visible = false;
            mc.visible = _actionMarkerVisible;
            mc.gotoAndPlay(0);
        }

        // Damage Visualization
        private function removeTextField(f: TextField):void
        {
            damageHolder.removeChild(f);
        }

        private function XVMShowDamage(curHealth:Number, delta:Number):void
        {
            var cfg:Object = Config.s_config.markers;
            cfg = _vtype == "ally" ? cfg.ally : cfg.enemy;
            cfg = curHealth > 0 ? cfg.alive : cfg.dead;
            cfg = _extmode ? cfg.extended : cfg.normal;

            cfg = cfg.damageText;

            if (!cfg.visible)
                return;

            var msg:String = (curHealth < 0) ? cfg.blowupMessage : cfg.damageMessage;
            var text:String = XVMFormatDynamicText(XVMFormatStaticText(msg), curHealth, delta);

            var damageField: TextField = new TextField();
            damageHolder.addChild(damageField);

            damageField.width = 140;
            damageField.height = 20;

            damageField.text = " " + text + " ";
            damageField.antiAliasType = AntiAliasType.ADVANCED;
            damageField.border = false;
            damageField.embedFonts = cfg.font.name == "$FieldFont";
            damageField.defaultTextFormat = XVMCreateNewTextFormat(cfg.font);
            damageField.text = " " + text + " ";
            damageField.textColor = !isNaN(parseInt(cfg.color)) ? int(cfg.color)
                : Config.s_config.colors.system[_vtype + "_alive_" + (s_isColorBlindMode ? "blind" : "normal")];
            damageField.x = -(damageField.width / 2.0);

            if (cfg.shadow)
            {
                var sh_color:Number = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.shadow.color), m_curHealth);
                var sh_alpha:Number = XVMFormatDynamicAlpha(cfg.shadow.alpha, m_curHealth);
                damageField.filters = [ GraphicsUtil.createShadowFilter(cfg.shadow.distance,
                    cfg.shadow.angle, sh_color, sh_alpha, cfg.shadow.size, cfg.shadow.strength) ];
            }

            var st:Number = (new Date()).time;
            var timer:Timer = new Timer(10);
            var timerFunc:Function = function():void {
                var d:Number = (new Date()).time - st;
                if (d > cfg.speed * 1000)
                {
                    damageHolder.removeChild(damageField);
                    timer.stop();
                    timer.removeEventListener(TimerEvent.TIMER, timerFunc);
                    timer = null;
                    timerFunc = null;
                    return;
                }
                damageField.y = cfg.maxRange * (cfg.speed * 1000 - d) / (cfg.speed * 1000) - cfg.maxRange;
            };
            timer.addEventListener(TimerEvent.TIMER, timerFunc);
            timer.start();
        }

        // Health Visualization
        private var dmgTimer:Timer = new Timer(10);
        private var dmgTimerFunc:Function = null;
        private function XVMSetupNewHealth(curHealth:Number):void
        {
            dmgTimer.stop();
            if (dmgTimerFunc != null)
            {
                dmgTimer.removeEventListener(TimerEvent.TIMER, dmgTimerFunc);
                dmgTimerFunc = null;
            }

            XVMUpdateHealthBar(curHealth); // colorizing health bar after taking damage

            var delta: Number = curHealth - m_curHealth;
            if (delta >= 0)
            {
                m_curHealth = curHealth;
                xvmHBDamage.graphics.clear();
                return;
            }

            XVMShowDamage(curHealth, -delta);

            m_curHealth = curHealth;

            //Flow bar animation
            var cfg:Object = _cfg.healthBar;
            if (cfg.damage.fade > 0)
            {
                var fade:Number = cfg.damage.fade * 1000;
                var color:Number = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.damage.color), curHealth);
                var alpha:Number = XVMFormatDynamicAlpha(cfg.damage.alpha, curHealth) / 100;
                var st:Number = (new Date()).time;
                var drawing: Boolean = false;
                dmgTimerFunc = function():void
                {
                    if (drawing)
                        return;
                    drawing = true;
                    var d:Number = (new Date()).time - st;
                    var w:Number = cfg.width * (-delta / m_maxHealth) * (fade - d) / fade;
                    xvmHBDamage.graphics.clear();
                    if (w <= 0)
                    {
                        dmgTimer.stop();
                        dmgTimer.removeEventListener(TimerEvent.TIMER, dmgTimerFunc);
                        dmgTimerFunc = null;
                        return;
                    }
                    xvmHBDamage.graphics.beginFill(color, alpha);
                    xvmHBDamage.graphics.drawRect(
                        cfg.border.size + cfg.width * (1.0 * curHealth / m_maxHealth) - 1, cfg.border.size,
                        w, cfg.height);
                    xvmHBDamage.graphics.endFill();
                    drawing = false;
                };
                dmgTimer.addEventListener(TimerEvent.TIMER, dmgTimerFunc);
                dmgTimer.start();
            }
        }

        private function XVMUpdateUI(curHealth:Number):void
        {
            xvmHBFill.scaleX = Math.min(curHealth / m_maxHealth * 100, 100) / 100;

            while (textFields.length > 0)
                removeChild(textFields.pop());

            textFields = [];
            for (var i:String in _cfg.textFields)
            {
                var cfg:Object = _cfg.textFields[i];
                if (cfg.visible)
                {
                    var tf:TextField = XVMCreateTextField(cfg);
                    tf.text = XVMFormatDynamicText(XVMFormatStaticText(cfg.format), curHealth);
                    tf.textColor = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.color), curHealth);
                    tf.alpha = XVMFormatDynamicAlpha(cfg.alpha, curHealth) / 100;
                    addChild(tf);
                    textFields.push(tf);
                }
            }
        }

        private function XVMUpdateHealthBar(curHealth:Number):void
        {
            var cfg:Object = _cfg.healthBar;

            xvmHB.alpha = XVMFormatDynamicAlpha(cfg.alpha, curHealth) / 100;

            var fullColor: Number = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.color), curHealth);
            var lowColor: Number = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.lcolor || cfg.color), curHealth);

            var percent: Number = curHealth / m_maxHealth;

            // determ current (real-time) color
            var currColor:Number = GraphicsUtil.colorByRatio(percent, lowColor, fullColor);

            xvmHBBorder.graphics.clear();
            xvmHBFill.graphics.clear();
            xvmHBDamage.graphics.clear();

            xvmHBBorder.graphics.beginFill(XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.border.color), curHealth), 1);
            xvmHBBorder.graphics.drawRect(0, 0, cfg.width + cfg.border.size * 2, cfg.height + cfg.border.size * 2);
            xvmHBBorder.graphics.endFill();
            xvmHBBorder.alpha = XVMFormatDynamicAlpha(cfg.border.alpha, curHealth) / 100;

            xvmHBFill.graphics.beginFill(currColor, 1);
            xvmHBFill.graphics.drawRect(cfg.border.size, cfg.border.size, cfg.width, cfg.height);
            xvmHBFill.graphics.endFill();
            xvmHBFill.alpha = XVMFormatDynamicAlpha(cfg.fill.alpha, curHealth) / 100;
        }

        private function XVMFormatDynamicAlpha(format: String, curHealth: Number): Number
        {
            if (!format || format == "0")
                return 100;

            if (!isNaN(parseInt(format)))
                return int(format);

            var hpRatio: Number = Math.ceil(curHealth / m_maxHealth * 100);
            var formatArr:Array = format.split("{{a:hp}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicAlphaValue(Defines.DYNAMIC_ALPHA_HP, curHealth).toString());
            formatArr = format.split("{{a:hp-ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicAlphaValue(Defines.DYNAMIC_ALPHA_HP_RATIO, hpRatio).toString());
            formatArr = format.split("{{a:hp_ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicAlphaValue(Defines.DYNAMIC_ALPHA_HP_RATIO, hpRatio).toString());

            var n:Number = !isNaN(parseInt(format)) ? int(format) : 100;
            return (n <= 0) ? 1 : (n > 100) ? 100 : n;
        }

        private function get pname():String
        {
            return "Player" + (_vtype == "ally" ? "Ally" : "Enemy");
        }

        private const rlevel:Array = [ "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" ];
        private function XVMFormatStaticText(format: String): String
        {
            // AS 2 doesn't have String.replace? Shame on them. Let's use our own square wheel.
            format = format.split("{{nick}}").join(pname);
            format = format.split("{{vehicle}}").join(_vdead ? "Hummel" : _vtype == "ally" ? "ИС-3" : "Ferdinand");
            var level:int = _vdead ? 5 : 8;
            format = format.split("{{level}}").join(String(level));
            format = format.split("{{rlevel}}").join(rlevel[level - 1]);

            format = format.split("{{kb}}").join("4k");
            format = format.split("{{battles}}").join("4321");
            format = format.split("{{wins}}").join("3210");
            format = format.split("{{rating}}").join("48%");
            format = format.split("{{eff}}").join("1234");

            format = format.split("{{t-kb}}").join("1k");
            format = format.split("{{t-kb-0}}").join("1.1k");
            format = format.split("{{t-hb}}").join("12h");
            format = format.split("{{t-battles}}").join("1234");
            format = format.split("{{t-wins}}").join("1000");
            format = format.split("{{t-rating}}").join("54%");

            // This code is stupid, and needs to be rewritten
            format = format.split("{{kb:3}}").join(" 4k");
            format = format.split("{{rating:3}}").join("48%");
            format = format.split("{{eff:4}}").join("1234");

            format = format.split("{{t-kb:4}}").join("  1k");
            format = format.split("{{t_kb:4}}").join("  1k");
            format = format.split("{{t-hb:3}}").join("12h");
            format = format.split("{{t_hb:3}}").join("12h");
            format = format.split("{{t-battles:4}}").join("1234");
            format = format.split("{{t_battles:4}}").join("1234");
            format = format.split("{{t-rating:3}}").join("54%");
            format = format.split("{{t_rating:3}}").join("54%");

            return format;
        }

        private function XVMFormatDynamicText(format: String, curHealth: Number, delta: Number = 0): String
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

            return format;
        }

        private function XVMCreateNewTextFormat(config_font: Object): TextFormat
        {
            var name:String = config_font.name || "$FieldFont";
            if (name == "$TextFont")
                name = "Tahoma";
            return new TextFormat(
                name,
                config_font.size || 13,
                0x000000,
                config_font.bold,
                config_font.italic,
                false, null, null,
                config_font.align || "center",
                0, 0, 0, 0);
        }

        private function XVMCreateTextField(cfg:Object):TextField
        {
            var textField: TextField = new TextField();
            textField.width = 140;
            textField.height = 30;
            //textField.height = cfg.font.size + 4;

            textField.selectable = false;
            textField.multiline = false;
            textField.wordWrap = false;
            //textField.antiAliasType = AntiAliasType.ADVANCED;
            //textField.gridFitType = GridFitType.SUBPIXEL;
            //textField.border = true;
            //textField.borderColor = 0xFFFFFF;
            textField.embedFonts = !cfg.font.name || cfg.font.name == "$FieldFont";
            textField.defaultTextFormat = XVMCreateNewTextFormat(cfg.font);

            if (cfg.shadow)
            {
                var sh_color:Number = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.shadow.color), m_curHealth);
                var sh_alpha:Number = XVMFormatDynamicAlpha(cfg.shadow.alpha, m_curHealth);
                textField.filters = [ GraphicsUtil.createShadowFilter(cfg.shadow.distance,
                    cfg.shadow.angle, sh_color, sh_alpha, cfg.shadow.size, cfg.shadow.strength) ];
            }

            textField.textColor = XVMFormatDynamicColor(XVMFormatStaticColorText(cfg.color), m_curHealth);
            textField.alpha = XVMFormatDynamicAlpha(cfg.alpha, m_curHealth) / 100;
            textField.x = cfg.x - (textField.width / 2.0);
            textField.y = cfg.y - (textField.height / 2.0);
            if (cfg.font.name != "$FieldFont")
                textField.y--; // -1 to be equal with ScaleForm renderer

            textField.visible = cfg.visible;

            return textField;
        }

        private function XVMFormatDynamicColor(format: String, curHealth: Number): Number
        {
            var systemColorName: String = _vtype + "_";
            systemColorName += !_vdead ? "alive_" : m_curHealth < 0 ? "blowedup_" : "dead_";
            systemColorName += s_isColorBlindMode ? "blind" : "normal";
            var systemColor:Number = Config.s_config.colors.system[systemColorName];

            if (!format)
                return systemColor;

            if (!isNaN(parseInt(format)))
                return int(format);

            var hpRatio: Number = Math.ceil(curHealth / m_maxHealth * 100);
            var formatArr:Array = format.split("{{c:hp}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_HP, curHealth, "0x"))
            formatArr = format.split("{{c:hp-ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_HP_RATIO, hpRatio, "0x"))
            formatArr = format.split("{{c:hp_ratio}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_HP_RATIO, hpRatio, "0x"))
            formatArr = format.split("{{c:vtype}}");
            if (formatArr.length > 1)
                format = formatArr.join(GraphicsUtil.GetVTypeColorValue(Utils.vehicleClassToVehicleType(vehicleClass), "0x"))
            return !isNaN(parseInt(format)) ? int(format) : systemColor;
        }

        private function XVMFormatStaticColorText(format: String): String
        {
            if (!format || !isNaN(parseInt(format)))
                return format;

            // Dynamic colors
            format = format.split("{{c:eff}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_EFF, 1234, "#", _vdead));
            format = format.split("{{c:rating}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_RATING, 48, "#", _vdead));
            format = format.split("{{c:kb}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_KB, 1, "#", _vdead));
            format = format.split("{{c:t-rating}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_RATING, 54, "#", _vdead));
            format = format.split("{{c:t_rating}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_RATING, 54, "#", _vdead));
            format = format.split("{{c:t-battles}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_TBATTLES, 1234, "#", _vdead));
            format = format.split("{{c:t_battles}}").join(
                GraphicsUtil.GetDynamicColorValue(Defines.DYNAMIC_COLOR_TBATTLES, 1234, "#", _vdead));

            return format;
        }
    }
}