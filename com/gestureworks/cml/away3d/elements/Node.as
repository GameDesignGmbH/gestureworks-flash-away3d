package com.gestureworks.cml.away3d.elements {
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.events.Object3DEvent;
	import away3d.tools.helpers.MeshHelper;
	import away3d.utils.Cast;
	import com.gestureworks.cml.away3d.geometries.PlaneGeometry;
	import com.gestureworks.cml.away3d.geometries.SphereGeometry;
	import com.gestureworks.cml.away3d.interfaces.INode;
	import com.gestureworks.cml.away3d.layouts.CircleLayout3D;
	import com.gestureworks.cml.away3d.materials.ColorMaterial;
	import com.gestureworks.cml.away3d.materials.TextureMaterial;
	import com.gestureworks.cml.elements.Graphic;
	import com.gestureworks.cml.elements.Text;
	import com.gestureworks.cml.utils.document;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	
	/**
	 * Provides Node hiearchy management and graph construction
	 * @author Ideum
	 */
	public class Node extends Mesh implements INode {
		
		private const ASCII_START:int = 97;
		
		private var _lookAtCamera:Boolean = false;
		private var _expanded:Boolean = true;
		private var _directed:Boolean = false;
		private var _autoToggle:Boolean = false;
		private var _autoToggleThreshold:Number = 500;
		private var _autoToggleVisibility:Boolean = true;
		private var _hideOnCollapse:Boolean = false;
		private var _targets:String;
		private var _content:*;
		private var _index:int = NaN;
		private var _label:String;
		private var _numLevel:int = 0;
		private var _hierarchy:String;
		private var _camera:Camera3D;
		private var _groupTransform:Boolean = true;
		
		private var _root:Node;		
		private var _edges:Vector.<Edge> = new Vector.<Edge>();
		private var _allEdges:Dictionary = new Dictionary();
		private var _edgeMesh:Edge;
		private var _eref:XML; //edge mesh		
		
		private var defaultGeometry:SphereGeometry = new SphereGeometry();
		private var defaultMaterial:ColorMaterial = new ColorMaterial(0xFF0000); 
		private var labelMesh:Mesh;
		
		public var expandLayout:Layout3D = new Circle3DLayout(400);
		public var collapseLayout:Layout3D = new Circle3DLayout(0);
		
		/**
		 * Constructor
		 */
		public function Node() {
			super();
			geometry = defaultGeometry;
			material = defaultMaterial;	
		}
		
		/**
		 * Initialization function
		 */
		override public function init():void {
			super.init();
			
			if (eref) {
				var s:String = String(eref);
				if (s.charAt(0) == "#") {
					s = s.substr(1);
				}
				edgeMesh = document.getElementById(s);
			}
			
			_root = Node.ancestors(this).pop();
			
			if (targets)
				parseTargets();
				
			if (groupTransform) {
				vto.gestureList = _root.vto.gestureList;				
				//touchEnabled = true;
				//vto.nativeTransform = false;
				//vto.addEventListener(GWGestureEvent.DRAG, function(e:GWGestureEvent):void {
					//_root.x += e.value.drag_dx;
					//_root.y += e.value.drag_dy;
					//_root.z += e.value.drag_dz;
				//});
			}
			
			if (collapseLayout) {
				collapseLayout.children = Layout3D.getChildren(this, [Node]);
			}			
			if (expandLayout) {				
				expandLayout.children = Layout3D.getChildren(this, [Node]);
				expandLayout.tween = false;
				expandLayout.layout(this);				
			}
			
			initEdges();
		}		
		
		/**
		 * @inheritDoc
		 */
		override public function parseCML(cml:XMLList):XMLList {
			
			if (cml.@edgeMesh != undefined) {
				cml.@eref = cml.@edgeMesh;
				delete cml.@edgeMesh;
			}
			
			return super.parseCML(cml);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get lookAtCamera():Boolean { return _lookAtCamera; }
		public function set lookAtCamera(value:Boolean):void {
			_lookAtCamera = value;
			if (_lookAtCamera && vto.view)
				View3D(vto.view).camera.addEventListener(Object3DEvent.POSITION_CHANGED, faceCamera);
				
		}
		
		/**
		 * @inheritDoc
		 */
		public function get expanded():Boolean { return _expanded; }
		
		/**
		 * @inheritDoc
		 */
		public function get directed():Boolean { return _directed; }
		
		/**
		 * @inheritDoc
		 */
		public function get isLeaf():Boolean { return _edges.length == 0; }
		
		/**
		 * @inheritDoc
		 */
		public function get isRoot():Boolean { return !(parent is Node); }
		
		/**
		 * @inheritDoc
		 */
		public function get root():Node { return _root; }	
		
		/**
		 * @inheritDoc
		 */
		public function get groupTransform():Boolean { return _groupTransform; }
		public function set groupTransform(value:Boolean):void {
			_groupTransform = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function expand(levelCnt:int = int.MAX_VALUE):void {	
			if (!levelCnt){
				return;				
			}	
			
			levelCnt--;
			for each(var edge:Edge in _edges) {
				edge.target.expand(levelCnt);
			}
			
			if (expandLayout) {
				expandLayout.children = Layout3D.getChildren(this, [Node]);
				expandLayout.tween = true;
				expandLayout.layout(this);			
			}
			if (hideOnCollapse) {
				hideChildren(false);
			}
			
			_expanded = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function collapse(levelCnt:int = 0):void {			
			var e:Vector.<Edge> = edgesAtLevel(levelCnt);
			for each(var edge:Edge in e) {
				edge.target.collapse();
			}				
			
			if (collapseLayout) {
				if(hideOnCollapse){
					collapseLayout.onComplete = hideChildren;
					collapseLayout.onCompleteParams = [true];
				}
				collapseLayout.layout(this);				
			}
			else if (hideOnCollapse) {
				hideChildren(true);
			}
			
			_expanded = false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function toggle():void {
			if (_expanded)
				collapse();
			else
				expand();
		}
		
		/**
		 * @inheritDoc
		 */
		public function get autoToggle():Boolean { return _autoToggle; } 
		public function set autoToggle(value:Boolean):void {
			_autoToggle = value;
			if (value && vto.view) {
				View3D(vto.view).camera.addEventListener(Object3DEvent.POSITION_CHANGED, cameraDistance);				
			}
			else if(vto.view) {
				View3D(vto.view).camera.removeEventListener(Object3DEvent.POSITION_CHANGED, cameraDistance);								
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get autoToggleThreshold():Number { return _autoToggleThreshold; }
		public function set autoToggleThreshold(value:Number):void {
			_autoToggleThreshold = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get autoToggleVisibility():Boolean { return _autoToggleVisibility;  }
		public function set autoToggleVisibility(value:Boolean):void {
			_autoToggleVisibility = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get hideOnCollapse():Boolean { return _hideOnCollapse; }
		public function set hideOnCollapse(value:Boolean):void {
			_hideOnCollapse = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function reset(level:int = int.MAX_VALUE):void {
			//loadState(0);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get targets():String { return _targets; }
		public function set targets(value:String):void {
			_targets = value;
		}
		
		/**
		 * Parse target node references and assign corresponding targets
		 */
		private function parseTargets():void {
			var tgtRefs:Array = targets.split(",");
			var tgts:Array = [];
			var flag:String;
			
			for each(var tgtRef:String in tgtRefs) {
				flag = tgtRef.charAt(0);
				
				if(flag == "#"){
					tgts.push(document.getElementById(tgtRef));
				}
				else if(flag == "."){
					tgts = tgts.concat(document.getElementsByClassName(tgtRef));
				}
				else if (!isNaN(parseInt(tgtRef))) {
					tgts.push(siblingNode(parseInt(tgtRef)));
				}
				else{
					tgts.push(nodeByHiearchy(tgtRef));
				}				
			}
			
			for each(var tgt:Node in tgts) {
				if (tgt)
					addTargetNode(tgt);
			}
		}		
		
		/**
		 * @inheritDoc
		 */
		public function siblingNode(index:int):Node {
			if (!parent is Node)
				return null;
			return Node(parent).nodeByIndex(index);
		}		
		
		/**
		 * @inheritDoc
		 */
		public function nodeByIndex(index:int):Node {
			for each(var edge:Edge in edges) {
				if (edge.target.index == index)
					return edge.target;
			}
			return null;
		}
		
		/**
		 * Recursivley search node tree for hiearchy path reference
		 * @param	hiearchy
		 * @param	node
		 * @return
		 */
		private function nodeByHiearchy(hiearchy:String, node:Node=null):Node {
			if (!node)
				node = Node(root);
				
			if (node.hierarchy != hiearchy) {
				for each(var edge:Edge in node.edges) {
					node = nodeByHiearchy(hiearchy, edge.target);
					if (node.hierarchy == hiearchy)
						break;
				}
			}
				
			return node;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get index():int { return _index; }
		public function set index(value:int):void {
			_index = value;
		}		
		
		/**
		 * @inheritDoc
		 */
		public function get level():String { 
			var lev:String = "";
			for (var i:int = 0; i <= Math.floor(numLevel / 26); i++) {
				lev += String.fromCharCode(_numLevel % 26 + ASCII_START); 
			}
			return lev;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numLevel():int { return _numLevel; }
		
		/**
		 * @inheritDoc
		 */
		public function get nodeId():String { return level + index; }	
		
		/**
		 * @inheritDoc
		 */
		public function get hierarchy():String {
			if (!_hierarchy)
				_hierarchy = nodeId;
			return _hierarchy;
		}
		
		/**
		 * Returns all ancestor Node objects of the provided Node
		 */
		public static function ancestors(n:Node):Vector.<Node> {
			var a:Vector.<Node> = new Vector.<Node>();
			if (!n) {
				return a;
			}
			
			a.push(n);
			if (n.parent is Node) {
				a = a.concat(ancestors(Node(n.parent)));
			}
			return a;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get label():String { return _label; }
		public function set label(value:String):void {
			if (_label == value)
				return;
				
			_label = value;
			
			
			var g:Graphic = new Graphic();
			g.shape = "rectangel";
			g.width = 256;
			g.height = 100;
			g.color = 0xFFFFFF;
			
			var text:Text = new Text();
			text.str = value;
			text.autosize = true;
			text.color = 0xFFFFFF;
			text.fontSize = 50;
			
			g.addChild(text);
								
			var bmd:BitmapData = new BitmapData(256, 256, true, 0);
			bmd.draw(text);
			var bitmap:Bitmap = new Bitmap(bmd);
			bitmap.smoothing = true;			
			
			labelMesh = new Mesh();
			labelMesh.y = 50;
			labelMesh.geometry = new PlaneGeometry();
			PlaneGeometry(labelMesh.geometry).yUp = false;
			MeshHelper.invertFaces(labelMesh,true);
			labelMesh.material = new TextureMaterial(Cast.bitmapTexture(bitmap));
			TextureMaterial(labelMesh.material).alphaBlending = true;
			addChild(labelMesh);
			
			if(vto.view)
				View3D(vto.view).camera.addEventListener(Object3DEvent.POSITION_CHANGED, faceCamera);			
		}
		
		/**
		 * @inheritDoc
		 */
		public function get edges():Vector.<Edge> { return _edges; }
		
		/**
		 * Returns edges at a decendant level relative to this node
		 * @param	level
		 * @return
		 */
		public function edgesAtLevel(level:int = 0):Vector.<Edge> {
			var lEdges:Vector.<Edge> = new Vector.<Edge>();
			if (!level){
				return edges;
			}
			for each(var edge:Edge in edges) {
				if (edge.target.numLevel == numLevel + level) {
					lEdges = lEdges.concat(edge.target.edges);
					continue;
				}
				else {
					lEdges = lEdges.concat(edge.target.edgesAtLevel(level-1));
				}
			}
			return lEdges;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get edgeMesh():Edge { return  _edgeMesh; }
		public function set edgeMesh(value:Edge):void {
			_edgeMesh = value;
		}
		
		/**
		 * Edge mesh reference
		 */
		public function get eref():* { return _eref; }
		public function set eref(value:*):void {
			_eref = value;
		}
				
		/**
		 * Override to handle special child registration
		 * @param	child 
		 * @return
		 */
		override public function addChild(child:ObjectContainer3D):ObjectContainer3D {
			super.addChild(child);
			if (child is Node) {
				addTargetNode(child as Node);
			}
			//transfer node graph children to node parent
			else if (child is NodeGraph) {
				NodeGraph(child).init();
				while(child.numChildren) {
					Node(addChild(child.getChildAt(0))).init();
				}
				super.removeChild(child);
			}
			
			return child;
		}
		
		/**
		 * Initialize all edges
		 */
		private function initEdges():void {
			for each(var edge:Edge in edges) {
				if (edgeMesh) {					
					//edge.geometry = edgeMesh.geometry;
					edge.material = edgeMesh.material;
				}				
				edge.init();
			}
			if (expandLayout) {
				expandLayout.onComplete = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addTargetNode(target:Node):void {
			if (isTarget(target)){
				return; 
			}
			
			target.inherit(this);							
			var edge:Edge = new Edge();
			edge.target = target;	
			edges.push(edge);
			addChild(edge);
		}
		
		/**
		 * @inheritDoc
		 */
		public function isTarget(node:Node):Boolean {
			for each(var edge:Edge in edges) {
				if (edge.target == node)
					return true;
			}
			return false;
		}
		
		/**
		 * If not customized, inherit source node attributes and set hierarchy properties
		 */
		private function inherit(source:Node):void {
			
			if (geometry == defaultGeometry){
				geometry = source.geometry;
			}
			if (material == defaultMaterial) {
				material = source.material;
			}
			if (!gref) {
				gref = source.gref;				
			}
			if (!mref) {
				mref = source.mref;				
			}
			if (!edgeMesh) {
				edgeMesh = source.edgeMesh;
			}			

			expandLayout = source.expandLayout;
			index = source.edges.length - 1;
			_numLevel = source.numLevel + 1; 
			_hierarchy = source.hierarchy + "-" + nodeId;
			vto.view = source.vto.view;
		}
				
		/**
		 * Controls camera distance auto-toggling
		 * @param	e
		 */
		private function cameraDistance(e:Object3DEvent):void {
			if (Math.abs(vto.distance) <= autoToggleThreshold && !expanded)
				expand();
			else if (Math.abs(vto.distance) > autoToggleThreshold && expanded)
				collapse();
		}
		
		/**
		 * Orients node towards camera
		 * @param	e
		 */
		private function faceCamera(e:Object3DEvent):void {
			if(labelMesh)
				labelMesh.lookAt(View3D(vto.view).camera.scenePosition);
			if (lookAtCamera)
				lookAt(View3D(vto.view).camera.scenePosition);
		}
		
		/**
		 * Hide/displays edges and associated target nodes
		 * @param	hide 
		 */
		private function hideChildren(hide:Boolean = true):void {
			for each(var edge:Edge in edges) {
				edge.visible = !hide;
				edge.target.visible = !hide;
			}
		}
		
	}

}