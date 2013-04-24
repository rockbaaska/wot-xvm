﻿/**
 * @author LEMAXHO
 */
import com.xvm.Config;
import com.xvm.GlobalEventDispatcher;
import com.xvm.Utils;
import wot.crew.CrewLoader;
import wot.crew.PingServers;

class wot.crew.tankmen.Crew
{
    /////////////////////////////////////////////////////////////////
    // wrapped methods

    private var wrapper:net.wargaming.tankmen.Crew;
    private var base:net.wargaming.tankmen.Crew;

    public function Crew(wrapper:net.wargaming.tankmen.Crew, base:net.wargaming.tankmen.Crew)
    {
        this.wrapper = wrapper;
        this.base = base;

        Utils.TraceXvmModule("Crew");

        CrewCtor();
    }

    function setTankmen()
    {
        return this.setTankmenImpl.apply(this, arguments);
    }

    // wrapped methods
    /////////////////////////////////////////////////////////////////

    private function CrewCtor()
    {
        GlobalEventDispatcher.addEventListener("config_loaded", this, onConfigLoaded);
        Config.LoadConfig("Crew.as");
    }

    private function onConfigLoaded()
    {
        GlobalEventDispatcher.removeEventListener("config_loaded", this, onConfigLoaded);

        if (Config.s_config.hangar.pingServers.enabled == true)
            PingServers.StartPinging();
    }

    // override
    function setTankmenImpl(data)
    {
        base.setTankmen(data);
        //com.xvm.Logger.addObject(wrapper.list, "list", 2);
        CrewLoader.s_defaultCrew = wrapper.list._dataProvider; // save the crewlist
    }

}