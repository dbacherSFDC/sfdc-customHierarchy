({
	doInit : function(component, event, helper) {
		var ariaControl = 'tree' + component.get("v.treeIndex") + '-node' + component.get("v.node.nodeId"); 
		component.set("v.ariaControl", ariaControl);
	},
	
	toggleBranch : function(component, event, helper) {
		var currentNode = component.get("v.node");
		var ariaControl = component.get("v.ariaControl");
		var childListElement = document.querySelector('ul[aria-labelledby="'+ariaControl+'__label"]');
		
		if(currentNode.hasMissingChildren){
			var loadChildren = component.getEvent("loadChildren");
			loadChildren.setParams({ "node": currentNode });
			loadChildren.fire();
		}
		else{
			helper.toggleSubList(childListElement);
			currentNode.defaultCollapsed = !currentNode.defaultCollapsed;
			component.set("v.node", currentNode);
		}
	},
	
	handleMouseEnter : function(component, event, helper) {
		var popover = component.find("popover");
		$A.util.removeClass(popover,'slds-hide');
	},
	
	handleMouseLeave : function(component, event, helper) {
		var popover = component.find("popover");
		$A.util.removeClass(popover,'slds-show');
	}
})