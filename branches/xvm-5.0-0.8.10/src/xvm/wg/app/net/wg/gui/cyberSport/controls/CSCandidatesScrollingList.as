package net.wg.gui.cyberSport.controls
{
   import net.wg.gui.components.controls.ScrollingListEx;
   import net.wg.infrastructure.interfaces.IDropList;


   public class CSCandidatesScrollingList extends ScrollingListEx implements IDropList
   {
          
      public function CSCandidatesScrollingList() {
         super();
      }

      public function get selectable() : Boolean {
         return false;
      }

      public function set selectable(param1:Boolean) : void {
          
      }

      public function highlightList() : void {
          
      }

      public function hideHighLight() : void {
          
      }
   }

}