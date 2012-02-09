﻿/**
 * ...
 * @author sirmax2
 */
import flash.geom.ColorTransform;
import flash.filters.DropShadowFilter;

class wot.utils.GraphicsUtil
{
  public static function createShadowFilter(data:Object):Object
  {
    if (Number(data.attributes.alpha) == 0 || Number(data.attributes.strength) == 0)
      return null;

    var shadow: DropShadowFilter = new DropShadowFilter();
    shadow.blurX = shadow.blurY = Number(data.attributes.size);
    shadow.angle = Number(data.attributes.angle);
    shadow.distance = Number(data.attributes.distance);
    shadow.color = Number(data.attributes.color);
    shadow.alpha = Number(data.attributes.alpha) * 0.01;
    shadow.strength = Number(data.attributes.strength) * 0.01;

    return shadow;
  }

  public static function fillRect(target:MovieClip, x:Number, y:Number,
    width: Number, height: Number, color: Number, alpha: Number)
  {
    target.moveTo(x, y);
    target.beginFill(color, alpha);
    target.lineTo(x + width, y);
    target.lineTo(x + width, y + height);
    target.lineTo(x, y + height);
    target.lineTo(x, y);
    target.endFill();
  }

  public static function colorByRatio($value:Number, $start:Number, $end:Number):Number
  {
    var r: Number = $start >> 16;
    var g: Number = ($start >> 8) & 0xff;
    var b: Number = $start & 0xff;
    var r2: Number = ($end >> 16) - r;
    var g2: Number = (($end >> 8) & 0xff) - g;
    var b2: Number = ($end & 0xff) - b;
    return ((r + ($value * r2)) << 16 | (g + ($value * g2)) << 8 | (b + ($value * b2)));
  }

  //method to set a specified movieClip(item:movidClip) to a specified color(col:hex value number)
  public static function setColor(item, col)
  {
    var myColorTransform: ColorTransform = new ColorTransform();
    myColorTransform.rgb = Number(col);
    item.transform.colorTransform = myColorTransform;
  }
}
