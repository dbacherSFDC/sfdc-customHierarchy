({
	/*
	 *  Map the Schema.FieldSetMember to the desired component config, including specific attribute values
	 *  Source: https://www.salesforce.com/us/developer/docs/apexcode/index_Left.htm#CSHID=apex_class_Schema_FieldSetMember.htm|StartTopic=Content%2Fapex_class_Schema_FieldSetMember.htm|SkinName=webhelp
	 *
	 *  Change the componentDef and attributes as needed for other components
	 */
	configMap: {
		'anytype': { componentDef: 'ui:inputText', attributes: {} },
		'base64': { componentDef: 'ui:inputText', attributes: {} },
		'boolean': {componentDef: 'ui:inputCheckbox', attributes: {} },
		'combobox': { componentDef: 'ui:inputText', attributes: {} },
		'currency': { componentDef: 'ui:inputText', attributes: {} },
		'datacategorygroupreference': { componentDef: 'ui:inputText', attributes: {} },
		'date': {
			componentDef: 'ui:inputDate',
			attributes: {
				displayDatePicker: true
			}
		},
		'datetime': { componentDef: 'ui:inputDateTime', attributes: {} },
		'double': { componentDef: 'ui:inputNumber', attributes: {} },
		'email': { componentDef: 'ui:inputEmail', attributes: {} },
		'encryptedstring': { componentDef: 'ui:inputText', attributes: {} },
		'id': { componentDef: 'ui:inputText', attributes: {} },
		'integer': { componentDef: 'ui:inputNumber', attributes: {} },
		'multipicklist': { componentDef: 'ui:inputText', attributes: {} },
		'percent': { componentDef: 'ui:inputNumber', attributes: {} },
		'phone': { componentDef: 'ui:inputPhone', attributes: {} },
		'picklist': { componentDef: 'ui:inputText', attributes: {} },
		'reference': { componentDef: 'ui:inputText', attributes: {} },
		'string': { componentDef: 'ui:inputText', attributes: {} },
		'textarea': { componentDef: 'ui:inputText', attributes: {} },
		'time': { componentDef: 'ui:inputDateTime', attributes: {} },
		'url': { componentDef: 'ui:inputText', attributes: {} }
	},

    // Adds the component via newComponentAsync and sets the value handler
    addComponent: function(component, facet, config, fieldPath) {
        $A.componentService.newComponentAsync(this, function(cmp) {
            cmp.addValueHandler({
                value: "v.value",
                event: "change",
                globalId: component.getGlobalId(),
                method: function(event) {
                    var values = component.get("v.values");
                    for (var i = 0; i < values.length; i++) {
                        if (values[i].name === fieldPath) {
                            values[i].value = event.getParams().value;
                        }
                    }
                    component.set("v.values", values);
                }
            });

            facet.push(cmp);
        }, config);
    }
})