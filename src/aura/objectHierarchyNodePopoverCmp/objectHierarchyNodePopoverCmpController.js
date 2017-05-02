({
	doInit : function(component, event, helper) {
		var nodeObj = component.get("c.node.sObj");
		var popoverFields = component.get("c.popoverFieldSetList");
		
		var fieldList = [];
		for(var i = 0; i < popoverFields.length; i++){
			fieldList.push({
				name: popoverFields[i].label
				, value: nodeObj[popoverFields[i].fieldPath]
			});
		}
		
		component.set("c.values", fieldList);
	}
})