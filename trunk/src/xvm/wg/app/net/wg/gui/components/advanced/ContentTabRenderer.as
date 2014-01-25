package net.wg.gui.components.advanced
{
   import net.wg.gui.components.controls.SoundButtonEx;
   import flash.events.MouseEvent;
   import net.wg.data.constants.Cursors;
   import __AS3__.vec.Vector;


   public class ContentTabRenderer extends SoundButtonEx
   {
          
      public function ContentTabRenderer() {
         super();
      }

      private static const PREFIX_FIRST:String = "first_";

      private static const PREFIX_LAST:String = "last_";

      private static const PREFIX_SELECTED:String = "selected_";

      private var _isFirst:Boolean = false;

      private var _isLast:Boolean = false;

      override public function showTooltip(param1:MouseEvent) : void {
         if(!enabled)
         {
            App.cursor.setCursor(Cursors.ARROW);
         }
         else
         {
            App.cursor.setCursor(Cursors.BUTTON);
         }
         super.showTooltip(param1);
      }

      override public function set enabled(param1:Boolean) : void {
         super.enabled = param1;
         mouseEnabled = true;
      }

      override protected function configUI() : void {
         super.configUI();
         setState(_state);
      }

      override protected function draw() : void {
         super.draw();
      }

      override protected function updateDisable() : void {
         if(disableMc != null)
         {
            disableMc.visible = !enabled;
            disableMc.x = bgMc.x;
            disableMc.y = bgMc.y;
            disableMc.scaleX = 1 / this.scaleX;
            disableMc.scaleY = 1 / this.scaleY;
            disableMc.widthFill = Math.round(bgMc.width * bgMc.scaleX * this.scaleX);
            disableMc.heightFill = Math.round(bgMc.height * bgMc.scaleY * this.scaleY);
         }
      }

      override protected function getStatePrefixes() : Vector.<String> {
         var _loc1_:* = "";
         if(this._isFirst)
         {
            _loc1_ = _loc1_ + PREFIX_FIRST;
         }
         else
         {
            if(this._isLast)
            {
               _loc1_ = _loc1_ + PREFIX_LAST;
            }
         }
         if(_selected)
         {
            _loc1_ = _loc1_ + PREFIX_SELECTED;
         }
         return Vector.<String>([_loc1_]);
      }

      public function get isFirst() : Boolean {
         return this._isFirst;
      }

      public function set isFirst(param1:Boolean) : void {
         this._isFirst = param1;
         invalidateState();
      }

      public function get isLast() : Boolean {
         return this._isLast;
      }

      public function set isLast(param1:Boolean) : void {
         this._isLast = param1;
         invalidateState();
      }
   }

}