({
	toggleSubList : function(childListElement) {
		$A.util.toggleClass(childListElement, 'slds-is-collapsed');
		$A.util.toggleClass(childListElement, 'slds-is-expanded');
	}
})