({
	doInit : function(component, event, helper) {
		var action = component.get("c.loadInitialHierarchy");
		action.setParams({
			"objId": component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			component.set("v.objectNodeList", response.getReturnValue());
		});
		
		var actionFields = component.get("c.getPopoverFieldSetMembers");
		actionFields.setCallback(this, function(response) {
			component.set("v.popoverFieldSetList", response.getReturnValue());
		});
		
		$A.enqueueAction(actionFields);
		$A.enqueueAction(action);
	},
	
	loadChildNodes : function(component, event, helper) {
		var action = component.get("c.loadChildHierarchy");
		var node = event.getParam('node');
		action.setParams({
			"nodeLevel": node.nodeLevel.toString()
			, "nodeId": node.nodeId
			, "objId": component.get("v.recordId")
		});
		action.setCallback(this, function(response){
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var childComponent = event.getSource();
				childComponent.set("v.node", response.getReturnValue()[0]);
			}
		});
		$A.enqueueAction(action);
	}
})