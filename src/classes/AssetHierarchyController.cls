/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce Services
Description:	Displays asset hierarchy for a specific Account, Contact or Asset
Test Class:		AssetHierarchyController_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
12/01/2016		Denise Bacher		Initial Creation
------------------------------------------------------------*/
global with sharing class AssetHierarchyController {
	@TestVisible private static String POPOVER_FIELD_SET = 'Hierarchy_Popover'; // asset field set used for popovers
	@TestVisible private static Integer HIERARCHY_DEPTH = 3; // default depth of the asset hierarchy to load, outstanding assets will be lazy loaded
	@TestVisible private static Integer QUERY_LIMIT = 1000; // default query limit
	
	public Account accountObj {get; set;} // account object from standard controller
	public Contact contactObj {get; set;} // contact object from standard controller
	public Asset assetObj {get; set;}  // asset object from standard controller
	
	public List<Schema.FieldSetMember> popoverFields {
		get{
			if(popoverFields == null){
				try{
					popoverFields = SObjectType.Asset.FieldSets.getMap().get(POPOVER_FIELD_SET).getFields();
				}
				catch(Exception e){
					popoverFields = new List<Schema.FieldSetMember>();
				}
			}
			return popoverFields;
		}
		private set;
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Controller constructor
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public AssetHierarchyController(){}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Remote function to retrieve the initial Asset Hierarchy for a given object 
	Inputs:			accountObject - Account object
					contactObject - Contact object
					assetObject - Asset object
	Returns:		Map of the root assets
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	@RemoteAction
	global static List<ObjectNode> loadInitialHierarchy(Id accountId, Id contactId, Id assetRootId, Id assetId){
		Set<String> rootAssetIds = getRootAssets(accountId, contactId, assetRootId);
		return getObjectStructure(0, rootAssetIds, assetId);
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Lightning function to retrieve the initial hierarchy based on the record id input
	Inputs:			objId - id of the Object the Asset Hierarchy is being accessed from
	Returns:		List of ObjectNode
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/07/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	@AuraEnabled
	public static List<ObjectNode> loadInitialHierarchy(Id objId){
		Set<String> rootAssetIds = new Set<String>();
		
		// determine what type of Object we have
		Schema.SObjectType currObjType = objId.getSobjectType();
		
		if(Schema.Account.SObjectType == currObjType){
			rootAssetIds = AssetHierarchyController.getRootAssets(objId, null, null);
		}
		else if(Schema.Contact.SObjectType == currObjType){
			rootAssetIds = AssetHierarchyController.getRootAssets(null, objId, null);
		}
		else if(Schema.Asset.SObjectType == currObjType){
			Asset a = [Select Id, Name, RootAssetId From Asset Where Id =: objId];
			rootAssetIds = AssetHierarchyController.getRootAssets(null, null, a.RootAssetId);
		}
		
		return AssetHierarchyController.getObjectStructure(0, rootAssetIds, objId);
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Remote function to retrieve the additional children in the hierarchy
	Inputs:			currentHierarchyLevel - current hierarchy level of the selected Asset
					currentId - id of an Asset
	Returns:		List of ObjectNode
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	@RemoteAction
	global static List<ObjectNode> lazyLoadChildAssets(Integer currentHierarchyLevel, String currentId, String selectedId){
		return getObjectStructure(currentHierarchyLevel, new Set<String>{currentId}, selectedId);
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Lightning function to retrieve the additional children in the hierarchy
	Inputs:			nodeLevel - current hierarchy level of the selected Asset
					nodeId - id of an Asset
					objId - id of the Object the Asset Hierarchy is being accessed from 
	Returns:		List of ObjectNode
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/07/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	@AuraEnabled
	public static List<ObjectNode> loadChildHierarchy(String nodeLevel, String nodeId, String objId){
		return AssetHierarchyController.getObjectStructure(Integer.valueOf(nodeLevel), new Set<String>{nodeId}, objId);
	}
	
	@AuraEnabled
	public static List<FieldSetMember> getPopoverFieldSetMembers(){
		List<FieldSetMember> fset = new List<FieldSetMember>();
		for (Schema.FieldSetMember f: SObjectType.Asset.FieldSets.getMap().get(POPOVER_FIELD_SET).getFields()) {
			fset.add(new FieldSetMember(f));
		}
		return fset;
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Find the root asset(s) for the given input
					NOTE: expected only one of the inputs will not be null 
	Inputs:			accountObject - Account object
					contactObject - Contact object
					assetObject - Asset object
	Returns:		Map of the root assets
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public static Set<String> getRootAssets(Id accountId, Id contactId, Id assetRootId){
		Set<String> rootAssetIds = new Set<String>();
		
		try{
			// query the top level assets
			String selectClause = 'Select RootAssetId';
			String whereClause = ' Where'
				+ (String.isNotBlank(accountId) ? ' AccountId = \'' + accountId + '\'' : '')
				+ (String.isNotBlank(contactId) ? ' ContactId = \'' + contactId + '\'' : '')
				+ (String.isNotBlank(assetRootId) ? ' RootAssetId = \'' + assetRootId + '\'' : '');
			
			String queryTop = selectClause + ' From Asset'
				+ whereClause
				+ ' Group By RootAssetId'
				+ ' Limit ' + QUERY_LIMIT;
			System.debug(queryTop);
				
			for(AggregateResult ar : Database.query(queryTop)){
				rootAssetIds.add((String)ar.get('RootAssetId'));
			}
		}
		catch(Exception e){
			System.debug(e);
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			throw new AssetHierarchyException('There was an error while trying to query for the top of the root asset.');
		}
		
		return rootAssetIds;
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Traverse down the hierarchy to retrieve the assets
					Note: Asset depth is unknown, so HIERARCHY_DEPTH is used to limit the number of queries that are performed 
	Inputs:			initialLevel - initial hierarchy level starting from
					currentIds - Set of Asset Ids to begin traversing down the hierarchy from
					selectedId - Asset Id that we are viewing the hierarchy from
	Returns:		List<ObjectNode> in their tree structure
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public static List<ObjectNode> getObjectStructure(Integer initialLevel, Set<String> currentIds, String selectedId){
		if(currentIds == null || currentIds.isEmpty() || initialLevel == null){
			throw new AssetHierarchyException('Invalid values, unable to retrieve hierarchy.');
		}
		
		List<ObjectNode> hierarchy = new List<ObjectNode>(); // list of objectNodes that represent the hierarchy
		Map<String, ObjectNode> nodeMap = new Map<String, ObjectNode>();
		List<Asset> currentAssets = new List<Asset>();
		Set<String> parentIds = new Set<String>();
		Integer level = initialLevel;
		Integer maxLevel = initialLevel + HIERARCHY_DEPTH;
		Boolean endOfStructure = false;
		
		try{
			// Find highest level obejct in the structure
			parentIds.addAll(currentIds);
			
			String selectClause = 'Select Id, ParentId, RootAssetId, Name';
			// add popover fields
			if(SObjectType.Asset.FieldSets.getMap().containsKey(POPOVER_FIELD_SET)){
				selectClause = getPopoverFields(selectClause, SObjectType.Asset.FieldSets.getMap().get(POPOVER_FIELD_SET).getFields());
			}
			
			// Loop though all children
			while (!endOfStructure && level < maxLevel){
				String fromClause = ' From Asset'
					+ ' Where ' + (level != initialLevel ? 'ParentId' : 'Id') + ' IN (\'' + String.join(new List<String>(parentIds), '\',\'')+ '\')'
					+ ' Order By Name'
					+ ' Limit ' + QUERY_LIMIT;
				
				if(level == initialLevel){
					// if we're at the top, get the current Asset
					System.debug('initial level ' + selectClause + fromClause);
					currentAssets = Database.query(selectClause + fromClause);
				}
				else if(level == maxLevel-1){
					// if we're at max depth, add an extra check to the query for additional children so they can be lazy loaded later
					System.debug('max level ' + selectClause + ', (Select Id From ChildAssets) '+ fromClause);
					currentAssets = Database.query(selectClause + ', (Select Id From ChildAssets) '+ fromClause);
				}
				else {
					System.debug(selectClause + fromClause);
					currentAssets = Database.query(selectClause + fromClause);
				}
				
				if(currentAssets.size() == 0){
					endOfStructure = true;
				}
				else {
					parentIds.clear();
					for(Asset a : currentAssets){
						// add the Asset Id to the parentIds set for the next loop
						parentIds.add(a.Id);
						
						// create the ObjectNode and add it to the node Map
						ObjectNode newNode = new ObjectNode(a, a.Id, a.Name, level, a.ParentId, 
							level == 0 && String.isNotBlank(a.ParentId), 
							String.valueOf(a.Id) == selectedId, 
							String.isBlank(a.ParentId));
						nodeMap.put(a.Id, newNode);  
						
						// if the nodeMap contains the Asset's parent, add the current node as a child of the parent node
						if(nodeMap.containsKey(a.ParentId)){
							nodeMap.get(a.ParentId).nodeChildren.add(newNode);
						}
						
						// set flag so we know there are additional children to be lazy loaded
						newNode.hasMissingChildren = a.ChildAssets != null && a.ChildAssets.size() > 0;
						System.debug(a.Name+' child assets? '+a.ChildAssets);
						
						// add all ObjectNodes at the initialLevel to the objectNode list that will be returned
						if(level == initialLevel){
							hierarchy.add(newNode);
						}
					}		 
					level++;
				}
			}
		}
		catch(Exception e){
			System.debug(e);
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			throw new AssetHierarchyException('There was an error while trying to query for the asset hierarchy.');
		}
		
		return hierarchy;
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Add fields from Field Set to the select clause for the query. If the field is a lookup, pull in the related Name field too
	Inputs:			selectClause - current select clause
					popoverFieldMembers - List of Schema.FieldSetMember
	Returns:		String - completed select clause string
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public static String getPopoverFields(String selectClause, List<Schema.FieldSetMember> popoverFieldMembers){
		// add popover fields
		for(Schema.FieldSetMember f : popoverFieldMembers){
			selectClause += !selectClause.contains(f.getFieldPath()) ? ', ' + f.getFieldPath() : '';
			
			// field is a lookup, lets pull in its name too
			if(String.valueOf(f.getType()).containsIgnoreCase('Reference')){
				String nameField = f.getFieldPath().endswithIgnoreCase('__c') ? f.getFieldPath().replace('__c', '__r.Name') : f.getFieldPath().replace('Id', '.Name');
				selectClause += !selectClause.contains(nameField) ? ', ' + nameField : ''; 
			}
		}
		
		return selectClause;
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce Services
	Description:	Custom Exceptions
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	12/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public class AssetHierarchyException extends Exception {}
}