package com.gestureworks.cml.away3d.elements {
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import com.gestureworks.away3d.utils.LayoutTransforms;
	import com.gestureworks.cml.away3d.interfaces.ILayout3D;
	import com.gestureworks.cml.core.CMLObject;
	import com.greensock.easing.Ease;
	import com.greensock.TimelineLite;
	import com.greensock.TweenLite;
	import com.leapmotion.leap.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	/**
	 * Loads Layout3D instances in CML through the ref attribute 
	 * and serves as the abstract class for all 3D layouts.
	 */
	public class Layout3D extends CMLObject implements ILayout3D {
		
		public var name:String;
		
		private var _tween:Boolean = true;
		private var _tweenTime:Number = 500;
		private var _autoplay:Boolean = true;
		private var _easing:Ease;
		private var _onComplete:Function;
		private var _onUpdate:Function;		
		
		protected var childTransforms:Vector.<LayoutTransforms>;
		protected var childTweens:Array;	
		protected var _layoutTween:TimelineLite;	
		
		/**
		 * Constructor
		 */
		public function Layout3D() {
			super();
			childTransforms = new Vector.<LayoutTransforms>;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function parseCML(cml:XMLList):XMLList {		
			var rXML:XMLList = new XMLList;
			if (cml.@ref != undefined) {
				var ref:String = String(cml.@ref);
				var cp:XMLList = cml.copy();
				cp.setName(ref);				
				delete cp.@ref;
				rXML = cp;
			}			
			return rXML;
		}	
					
		public function layout(container:ObjectContainer3D):void {
			var i:int;
			var child:Object3D;
			var t:LayoutTransforms;
			
			if (tween) {
								
				if (_layoutTween && _layoutTween._active) {
					_layoutTween.eventCallback("onUpdate", onUpdate);
					_layoutTween.eventCallback("onComplete", onComplete);
					return;
				}
				
				childTweens = [];
				
				for (i = 0; i < container.numChildren; i++) {
					child = Object3D(container.getChildAt(i));
					t = LayoutTransforms(childTransforms[i]);				
					
					// position
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { x:t.pos.x, ease:easing } ));
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { y:t.pos.y, ease:easing } ));
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { z:t.pos.z, ease:easing } ));	
					
					// rotation
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { rotationX:t.rot.x, ease:easing } ));
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { rotationY:t.rot.y, ease:easing } ));
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { rotationZ:t.rot.z, ease:easing } ));	
					
					// scale
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { scaleX:t.sca.x, ease:easing } ));
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { scaleY:t.sca.y, ease:easing } ));
					childTweens.push(TweenLite.to(child, tweenTime / 1000, { scaleZ:t.sca.z, ease:easing } ));						
				}	
				
				if (_layoutTween) {
					_layoutTween.clear();
				}
				else {
					_layoutTween = new TimelineLite( { onComplete:onComplete, onUpdate:onUpdate } );
				}
				_layoutTween.pause();				
				_layoutTween.appendMultiple(childTweens);
				
				if (_autoplay) {
					_layoutTween.play();
				}
			}
			else {
				var m:Matrix3D = new Matrix3D;				
				for (i = 0; i < container.numChildren; i++) {
					m.identity();
					child = Object3D(container.getChildAt(i));
					t = LayoutTransforms(childTransforms[i]);	
					
					m.appendTranslation(t.pos.x, t.pos.y, t.pos.z);	
					m.appendRotation(t.rot.x, Vector3D.X_AXIS);
					m.appendRotation(t.rot.y, Vector3D.Y_AXIS);
					m.appendRotation(t.rot.z, Vector3D.Z_AXIS);								
					m.appendScale(t.sca.x, t.sca.y, t.sca.z); 	
					
					child.transform = m;
				}
			}
		}
		
		/**
		 * Kills the tweening of the provided child. If a child is not provided, the group tween is killed.
		 * @param	child  
		 */
		public function killTween(child:*=null):void {
			if (layoutTween) {
				if(!child)
					layoutTween.kill();
				else
					layoutTween.kill(null, child);
			}
		}		
		
		
		/**
		 * Flag indicating the display objects will animate to their layout positions. If false,
		 * the objects will be positioned at initialization.
		 * @default true
		 */
		public function get tween():Boolean { return _tween; }
		public function set tween(t:Boolean):void
		{
			_tween = t;
		}		
		
		/**
		 * The time(ms) the display objects will take to move into positions
		 * @default 500
		 */
		public function get tweenTime():Number { return _tweenTime; }
		public function set tweenTime(t:Number):void
		{
			_tweenTime = t;
		}

		/**
		 * Specifies the easing equation. Argument must be an Ease instance or a String defining the Ease class
		 * either by property syntax or class name (e.g. Expo.easeOut or ExpoOut). 
		 */
		public function get easing():* { return _easing; }
		public function set easing(e:*):void
		{
			if (!(e is Ease))
			{   
				var value:String = e.toString();				
				if (value.indexOf(".ease") != -1)
					value = value.replace(".ease", "");
				
				var easingType:Class = getDefinitionByName("com.greensock.easing." + value) as Class;
				e = new easingType();
			}
			if (e is Ease)
				_easing = e;
		}		
		
		/**
		 * Function to call on layout complete
		 */
		public function get onComplete():Function { return _onComplete; }
		public function set onComplete(f:Function):void
		{
			_onComplete = f;
		}
		
		/**
		 * Function to call on layout update
		 */
		public function get onUpdate():Function { return _onUpdate; }
		public function set onUpdate(f:Function):void
		{
			_onUpdate = f;
		}		
		
		/**
		 * Read-only accessor to layout tweener.
		 */
		public function get layoutTween():TimelineLite {
			return _layoutTween;
		}
		
		/**
		 * Automatically tweens when layout method is called. If false you
		 * call play() on the layoutTween property.
		 */
		public function get autoplay():Boolean {
			return _autoplay;
		}
		public function set autoplay(value:Boolean):void {
			_autoplay = value;
		}
		
	}
}