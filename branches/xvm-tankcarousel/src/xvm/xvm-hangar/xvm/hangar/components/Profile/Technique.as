package xvm.hangar.components.Profile
{
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import scaleform.clik.data.*;
    import scaleform.clik.events.*;
    import scaleform.clik.interfaces.*;
    import net.wg.gui.lobby.profile.pages.summary.*;
    import net.wg.gui.lobby.profile.pages.technique.*;
    import net.wg.gui.components.advanced.*;
    import com.xvm.*;
    import com.xvm.events.*;
    import com.xvm.io.*;
    import com.xvm.types.cfg.*;
    import com.xvm.l10n.Locale;
    import xvm.UI.profileSections.UI_TechniqueRenderer;

    public class Technique extends Sprite
    {
        private var page:ProfileTechnique;
        private var summary:ProfileSummary;

        public function Technique(page:ProfileTechnique, summary:ProfileSummary):void
        {
            this.page = page;
            this.summary = summary;

            // remove lower shadow (last item is looks bad with it)
            page.listComponent.lowerShadow.visible = false;

            // default sort
            //sortColumn
    //"filterFocused": true,
    //"showFilters": true,

            // handle dataProvider change
            page.listComponent.addEventListener(ListEvent.INDEX_CHANGE, adjustSummaryItem, false, 0, true);
            page.listComponent.sortableButtonBar.addEventListener(SortingButton.SORT_DIRECTION_CHANGED, adjustSummaryItem, false, 0, true);

            // override renderer
            list.itemRenderer = UI_TechniqueRenderer;
        }

        // PRIVATE

        private function get list():TechniqueList
        {
            return page.listComponent.techniqueList;
        }

        private function adjustSummaryItem(e:Event):void
        {
            //Logger.add("adjustSummaryItem");
            try
            {
                var dp:IDataProvider = list.dataProvider;
                if (!dp || dp.length <= 0)
                    return;

                var idx:int = -1;
                for (var i:int = 0; i < dp.length; ++i)
                {
                    if (dp[i].id == -1)
                    {
                        idx = i;
                        break;
                    }
                }

                if (idx != 0)
                {
                    var d:Array = dp as Array;
                    if (idx > 0)
                        d.splice(idx, 1);
                    d.unshift(summaryItem);
                    if (list.selectedIndex == idx)
                        list.selectedIndex = 0;
                    else if (idx > 0 && list.selectedIndex < d.length - 1)
                        list.selectedIndex++;
                }
            }
            catch (ex:Error)
            {
                Logger.add(ex.getStackTrace());
            }
        }

        private function get summaryItem():TechniqueListVehicleVO
        {
            return new TechniqueListVehicleVO(
            {
                "id": -1,
                "level": 0,
                "markOfMastery": 0,
                "typeIndex": 0,
                "typeIconPath": "../maps/icons/filters/tanks/all.png",
                "tankIconPath": "../maps/icons/filters/empty.png",
                "nationIndex": -1,
                "userName": "",
                "shortUserName": Locale.get("Summary"),
                "isInHangar": true,
                "nationID": -1,
                "inventoryID": -1,
                "battlesCount": extractNumber(summary.tfTotalBattles.text),
                "winsEfficiency": extractNumber(summary.tfWins.text),
                "avgExperience": summary.tfAvgExperience.text
            });
        }

        private function extractNumber(str:String):Number
        {
            if (!str)
                return NaN;

            str = str.replace(",", ".");

            // String.replace have problems with unicode.
            var res:String = "";
            for (var i:int = 0; i < str.length; ++i)
            {
                var c:String = str.charAt(i);
                if ((c >= "0" && c <= "9") || c == ".")
                    res += c;
            }
            return parseFloat(res);
        }

    }
}