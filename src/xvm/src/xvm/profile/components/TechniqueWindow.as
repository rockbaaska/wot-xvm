package xvm.profile.components
{
    import com.xvm.*;
    import net.wg.gui.lobby.profile.pages.technique.*;
    import net.wg.data.gui_items.dossier.*;

    public class TechniqueWindow extends Technique
    {
        public function TechniqueWindow(window:ProfileTechniqueWindow, playerName:String, playerId:int):void
        {
            super(window, playerName);

            _accountDossier = new AccountDossier(playerId.toString());
        }

        override protected function createFilters():void
        {
            super.createFilters();

            filter.visible = false;
            filter.x = 680;
            filter.y = -47;
        }
    }
}