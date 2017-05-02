/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce Services
Description:	Generic container for objects displayed in a Hierarchy
Test Class:		

History:
<Date>			<Authors Name>		<Brief Description of Change>
12/01/2016		Denise Bacher		Initial Creation
------------------------------------------------------------*/
global class ObjectNode {
	@AuraEnabled public SObject sObj {get; set;}					// the SObject
	@AuraEnabled public String nodeId {get; set;}					// ID of the SObject
	@AuraEnabled public String nodeName {get; set;}					// Name or Label correspidning to the SObject
	@AuraEnabled public Integer nodeLevel {get; set;}				// Level of the node
	@AuraEnabled public String nodeParentId {get; set;}				// ID of the Parent SObject
	@AuraEnabled public Boolean isSelectedObject {get; set;}		// Is this the object that was initially selected
	@AuraEnabled public Boolean isTopNode {get; set;}				// Is this the upper most object in the hierarchy
	@AuraEnabled public Boolean hasMissingParent {get; set;}		// Does this node have a parent that is not being displayed
	@AuraEnabled public Boolean hasMissingChildren {get; set;}		// Does this node have children that are not being displayed
	@AuraEnabled public Boolean defaultCollapsed {get; set;}		// Does this node default to being expanded
	@AuraEnabled public List<ObjectNode> nodeChildren {get; set;}	// List of the current node's children
	
	global ObjectNode(SObject obj, String nId, String nName, Integer nLevel, String nParentId, Boolean nMissingParent, Boolean nSelected, Boolean nTopNode){
		sObj = obj;
		nodeId = nId;
		nodeName = nName;
		nodeLevel = nLevel;
		nodeParentId = nParentId;
		hasMissingParent = nMissingParent;
		isSelectedObject = nSelected;
		isTopNode = nTopNode;
		nodeChildren = new List<ObjectNode>();
		
		hasMissingChildren = false;
		defaultCollapsed = false;
	}
}