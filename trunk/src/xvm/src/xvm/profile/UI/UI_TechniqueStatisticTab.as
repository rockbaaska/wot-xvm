package xvm.profile.UI
{
    import net.wg.data.gui_items.dossier.*;
    import net.wg.gui.lobby.profile.pages.technique.data.ProfileVehicleDossierVO;
    import xvm.profile.components.TechniqueStatisticTab;

    public dynamic class UI_TechniqueStatisticTab extends TechniqueStatisticTab_UI
    {
        private var worker:TechniqueStatisticTab;

        public function UI_TechniqueStatisticTab()
        {
            super();
            // TODO: FIXIT: worker = new TechniqueStatisticTab(this);
        }

        override protected function configUI():void
        {
            super.configUI();
            // TODO: FIXIT: worker.configUI();
        }

        override public function update(arg1:Object):void
        {
            super.update(arg1);
            // TODO: FIXIT: worker.update(arg1 as ProfileVehicleDossierVO);
        }
    }
}