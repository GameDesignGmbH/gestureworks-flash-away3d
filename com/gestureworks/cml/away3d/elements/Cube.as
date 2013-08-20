package com.gestureworks.cml.element.away3d {
	import away3d.core.base.Geometry;
	import away3d.primitives.CubeGeometry;
	import com.gestureworks.cml.element.Element;
	
	/**
	 * ...
	 */
	public class Cube extends Element {
		private var _width:Number = 100;
		private var _height:Number = 100;
		private var _depth:Number = 100;
		private var _segmentsW:uint = 1;
		private var _segmentsH:uint = 1;
		private var _segmentsD:uint = 1;
		private var _geometry:Geometry;
		
		public function Cube() {
			super();
			
		}
		
		/**
		 * Initialisation method
		 */
		override public function init():void {
			displayComplete();
		}
		
		/**
		 * CML callback Initialisation
		 */
		override public function displayComplete():void {
			
			_geometry = new CubeGeometry(_width, _height, _depth, _segmentsW, segmentsH, segmentsD);
			
			if (this.parent is Mesh)
				Mesh(this.parent).geometry = _geometry;
		
		}
		
		/**
		 * The size of the cube along its X-axis.
		 *  @default 100
		 */
		public override function get width():Number {
			return _width;
		}
		
		public override function set width(value:Number):void {
			_width = value;
		}
		
		/**
		 * The size of the cube along its Y-axis.
		 *  @default 100
		 */
		public override function get height():Number {
			return _height;
		}
		
		public override function set height(value:Number):void {
			_height = value;
		}
		
		/**
		 * The size of the cube along its Z-axis.
		 *  @default 100
		 */
		public function get depth():Number {
			return _depth;
		}
		
		public function set depth(value:Number):void {
			_depth = value;
		}
		
		/**
		 * The number of segments that make up the cube along the X-axis.
		 *  @default 1
		 */
		public function get segmentsW():uint {
			return _segmentsW;
		}
		
		public function set segmentsW(value:uint):void {
			_segmentsW = value;
		}
		
		/**
		 * The number of segments that make up the cube along the Y-axis.
		 *  @default 1
		 */
		public function get segmentsH():uint {
			return _segmentsH;
		}
		
		public function set segmentsH(value:uint):void {
			_segmentsH = value;
		}
		
		/**
		 * The number of segments that make up the cube along the Z-axis.
		 *  @default 1
		 */
		public function get segmentsD():uint {
			return _segmentsD;
		}
		
		public function set segmentsD(value:uint):void {
			_segmentsD = value;
		}
		
		/**
		 * Away3d Geometry
		 */
		public function get geometry():Geometry {
			return _geometry;
		}
		
		public function set geometry(value:Geometry):void {
			if (_geometry != value)
				_geometry = value;
		}
	
	}

}