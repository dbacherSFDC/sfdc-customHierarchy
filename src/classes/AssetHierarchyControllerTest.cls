/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce Services
Description:	Test class to validate AssetHierarchyController
				Tests Excecuted:
				
				viewHierarchyFromAssetRoot - view asset hierarchy from the root asset, verfiy hierarchy details and 'lazy load' additional accounts
				
				viewHierarchyFromAssetChild - view asset hierarchy from child asset, should display root asset
				
				viewHierarchyFromAccount - view asset hierarchy from related account
				
				viewHierarchyFromContact - view asset hierarchy from related contact
				
				verifyPopoverFieldsSet - verify correct number of fields were fetched when a FieldSet is found
				
				verifyPopoverFieldsSetNotSet - verify 0 fields were fetched when no FieldSet is defined
				
				loadInitialHierarchyBadInputs - call AssetHierarchyController.loadInitialHierarchy with null inputs
				
				loadInitialHierarchyLightingAccount - call AssetHierarchyController.loadInitialHierarchy with an Account Id
				
				loadInitialHierarchyLightingContact - call AssetHierarchyController.loadInitialHierarchy with an Contact Id
				
				loadInitialHierarchyLightingAsset - call AssetHierarchyController.loadInitialHierarchy with an Asset Id
				
				lazyLoadChildAssetsBadInputs - call AssetHierarchyController.lazyLoadChildAssets with null inputs

History:
<Date>			<Authors Name>		<Brief Description of Change>
12/02/2016		Denise Bacher		Initial Creation
------------------------------------------------------------*/
@isTest
private class AssetHierarchyControllerTest {
	
	@testSetup static void setup(){
		Account primaryAccount = new Account(Name = 'Test Account');
		insert primaryAccount;
		
		Contact primaryContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = primaryAccount.Id);
		insert primaryContact;
		
		List<Asset> rootAssets = new List<Asset>();
		for(Integer i = 0; i < 5; i++){
			rootAssets.add(new Asset(Name = 'Asset '+ i, AccountId = primaryAccount.Id, ContactId = primaryContact.Id));
		}
		insert rootAssets;
		
		List<Asset> assetsLevel1 = createChildAssets(rootAssets, primaryAccount.Id, null, 5);
		List<Asset> assetsLevel2 = createChildAssets(assetsLevel1, primaryAccount.Id, primaryContact.Id, 2);
		List<Asset> assetsLevel3 = createChildAssets(assetsLevel2, primaryAccount.Id, null, 2);
		List<Asset> assetsLevel4 = createChildAssets(assetsLevel3, primaryAccount.Id, null, 2);
		List<Asset> assetsLevel5 = createChildAssets(assetsLevel4, primaryAccount.Id, null, 2);
	}
	
	private static List<Asset> createChildAssets(List<Asset> parentAssets, Id accountId, Id contactId, Integer counter){
		List<Asset> childAssets = new List<Asset>();
		for(Asset a : parentAssets){
			for(Integer i = 0; i < counter; i++){
				childAssets.add(new Asset(Name = a.Name + '>'+ i, ParentId = a.Id, AccountId = accountId, ContactId = contactId));
			}
		}
		insert childAssets;
		return childAssets;
	}
	
	static testMethod void viewHierarchyFromAssetRoot() {
		Asset rootAsset = [Select Id, Name, ParentId, RootAssetId From Asset Where ParentId = null Limit 1];
		
		PageReference pageRef = Page.AssetHierarchy;
		Test.setCurrentPage(pageRef);
		
		AssetHierarchyController ctrl = new AssetHierarchyController();
		ctrl.assetObj = rootAsset;
		
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(null, null, rootAsset.RootAssetId, rootAsset.Id);
			
			// verify account hierarchy loaded
			System.assertEquals(1, objectNodes.size());
			System.assertEquals(rootAsset.Id, objectNodes[0].nodeId);
			System.assertEquals(rootAsset.Name, objectNodes[0].nodeName);
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(true, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level2ChildNodes[0].nodeLevel, level2ChildNodes[0].nodeId, rootAsset.Id);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			
			// check last level loaded has missing children (level 4)
			List<ObjectNode> level4ChildNodes = missingChildNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level4ChildNodes[0].hasMissingChildren);
			System.assertEquals(2, level4ChildNodes.size());
			
			// lazy load the missing children
			missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level4ChildNodes[0].nodeLevel, level4ChildNodes[0].nodeId, rootAsset.Id);
			
			// verify missing hierarchy loaded and we've reached the end of this branch
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 5
			System.assertEquals(false, missingChildNodes[0].nodeChildren[0].hasMissingChildren); // level 5 has no missing children
		Test.stopTest();
	}
	
	static testMethod void viewHierarchyFromAssetChild() {
		Asset childAsset = [Select Id, Name, ParentId, RootAssetId From Asset Where ParentId != null And Name = 'Asset 0>0>0>0'Limit 1];
		
		PageReference pageRef = Page.AssetHierarchy;
		Test.setCurrentPage(pageRef);
		
		AssetHierarchyController ctrl = new AssetHierarchyController();
		ctrl.assetObj = childAsset;
		
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(null, null, childAsset.RootAssetId, childAsset.Id);
			
			// verify account hierarchy loaded
			System.assertEquals(1, objectNodes.size());
			System.assertNotEquals(childAsset.Id, objectNodes[0].nodeId);
			System.assertEquals(childAsset.RootAssetId, objectNodes[0].nodeId);
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(false, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level2ChildNodes[0].nodeLevel, level2ChildNodes[0].nodeId, childAsset.Id);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			System.assertEquals(childAsset.Name, missingChildNodes[0].nodeChildren[0].nodeName); // level 3 - originating asset
			System.assertEquals(childAsset.Id, missingChildNodes[0].nodeChildren[0].nodeId); // level 3 - originating asset
			System.assertEquals(true, missingChildNodes[0].nodeChildren[0].isSelectedObject); // level 3 - originating asset
			
			System.assertEquals(2, missingChildNodes[0].nodeChildren[0].nodeChildren.size()); // level 4
			System.assertEquals(true, missingChildNodes[0].nodeChildren[0].nodeChildren[0].hasMissingChildren); // level 4 has missing children
		Test.stopTest();
	}
	
	static testMethod void viewHierarchyFromAccount(){
		Account primaryAccount = [Select Id From Account Limit 1];
		
		PageReference pageRef = Page.AssetAccountHierarchy;
		Test.setCurrentPage(pageRef);
		
		AssetHierarchyController ctrl = new AssetHierarchyController();
		ctrl.accountObj = primaryAccount;
		
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(primaryAccount.Id, null, null, null);
			
			// verify account hierarchy loaded
			System.assertEquals(5, objectNodes.size());
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(false, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level2ChildNodes[0].nodeLevel, level2ChildNodes[0].nodeId, null);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			System.assertEquals(2, missingChildNodes[0].nodeChildren[0].nodeChildren.size()); // level 4
			System.assertEquals(true, missingChildNodes[0].nodeChildren[0].nodeChildren[0].hasMissingChildren); // level 4 has missing children
		Test.stopTest();
	}
	
	static testMethod void viewHierarchyFromContact(){
		Contact primaryContact = [Select Id From Contact Limit 1];
		
		PageReference pageRef = Page.AssetContactHierarchy;
		Test.setCurrentPage(pageRef);
		
		AssetHierarchyController ctrl = new AssetHierarchyController();
		ctrl.contactObj = primaryContact;
		
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(null, primaryContact.Id, null, null);
			
			// verify account hierarchy loaded
			System.assertEquals(5, objectNodes.size());
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(false, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level2ChildNodes[0].nodeLevel, level2ChildNodes[0].nodeId, null);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			System.assertEquals(2, missingChildNodes[0].nodeChildren[0].nodeChildren.size()); // level 4
			System.assertEquals(true, missingChildNodes[0].nodeChildren[0].nodeChildren[0].hasMissingChildren); // level 4 has missing children
		Test.stopTest();
	}
	
	static testMethod void verifyPopoverFieldsSet(){
		Map<String, Schema.FieldSet> fsMap = Schema.SObjectType.Asset.fieldSets.getMap();
		List<String> keySet = new List<String>(fsMap.keySet()); 
		String mapKey = keySet[0];
		AssetHierarchyController.POPOVER_FIELD_SET = mapKey;
		
		AssetHierarchyController ctrl = new AssetHierarchyController();
		List<Schema.FieldSetMember> popoverFields = ctrl.popoverFields;
		System.assertEquals(Schema.SObjectType.Asset.fieldSets.getMap().get(mapKey).getFields().size(), popoverFields.size());
	}
	
	static testMethod void verifyPopoverFieldsNotSet(){
		AssetHierarchyController.POPOVER_FIELD_SET = null;
		
		AssetHierarchyController ctrl = new AssetHierarchyController();
		List<Schema.FieldSetMember> popoverFields = ctrl.popoverFields;
		System.assertEquals(0, popoverFields.size());
	}
	
	static testMethod void loadInitialHierarchyBadInputs(){
		Test.startTest();
			try{
				List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(null, null, null, null);
				System.assert(false, 'loadInitialHierarchy with null params should have thrown an error');
			}
			catch(Exception e){
				System.assert(e.getTypeName().contains('AssetHierarchyException'));
			}
		Test.stopTest();
	}
	
	static testMethod void loadInitialHierarchyLightingAccount(){
		Account primaryAccount = [Select Id From Account Limit 1];
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(primaryAccount.Id);
			
			// verify account hierarchy loaded
			System.assertEquals(5, objectNodes.size());
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(false, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level2ChildNodes[0].nodeLevel, level2ChildNodes[0].nodeId, null);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			System.assertEquals(2, missingChildNodes[0].nodeChildren[0].nodeChildren.size()); // level 4
			System.assertEquals(true, missingChildNodes[0].nodeChildren[0].nodeChildren[0].hasMissingChildren); // level 4 has missing children
		Test.stopTest();
	}
	
	static testMethod void loadInitialHierarchyLightingContact(){
		Contact primaryContact = [Select Id From Contact Limit 1];
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(primaryContact.Id);
			
			// verify account hierarchy loaded
			System.assertEquals(5, objectNodes.size());
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(false, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.lazyLoadChildAssets(level2ChildNodes[0].nodeLevel, level2ChildNodes[0].nodeId, null);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			System.assertEquals(2, missingChildNodes[0].nodeChildren[0].nodeChildren.size()); // level 4
			System.assertEquals(true, missingChildNodes[0].nodeChildren[0].nodeChildren[0].hasMissingChildren); // level 4 has missing children
		Test.stopTest();
	}
	
	static testMethod void loadInitialHierarchyLightingAsset() {
		Asset rootAsset = [Select Id, Name, ParentId, RootAssetId From Asset Where ParentId = null Limit 1];
		AssetHierarchyController.HIERARCHY_DEPTH = 3;
		
		Test.startTest();
			List<ObjectNode> objectNodes = AssetHierarchyController.loadInitialHierarchy(rootAsset.Id);
			
			// verify account hierarchy loaded
			System.assertEquals(1, objectNodes.size());
			System.assertEquals(rootAsset.Id, objectNodes[0].nodeId);
			System.assertEquals(rootAsset.Name, objectNodes[0].nodeName);
			System.assertEquals(0, objectNodes[0].nodeLevel);
			System.assertEquals(true, objectNodes[0].isSelectedObject);
			System.assertEquals(true, objectNodes[0].isTopNode);
			System.assertEquals(false, objectNodes[0].hasMissingParent);
			System.assertEquals(false, objectNodes[0].hasMissingChildren);
			
			System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
			System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
			
			// check last level loaded has missing children (level 2)
			List<ObjectNode> level2ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level2ChildNodes[0].hasMissingChildren);
			
			// lazy load the missing children
			List<ObjectNode> missingChildNodes = AssetHierarchyController.loadChildHierarchy(String.valueOf(level2ChildNodes[0].nodeLevel), level2ChildNodes[0].nodeId, rootAsset.Id);
			
			// verify missing hierarchy loaded
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 3
			
			// check last level loaded has missing children (level 4)
			List<ObjectNode> level4ChildNodes = missingChildNodes[0].nodeChildren[0].nodeChildren;
			System.assertEquals(true, level4ChildNodes[0].hasMissingChildren);
			System.assertEquals(2, level4ChildNodes.size());
			
			// lazy load the missing children
			missingChildNodes = AssetHierarchyController.loadChildHierarchy(String.valueOf(level4ChildNodes[0].nodeLevel), level4ChildNodes[0].nodeId, rootAsset.Id);
			
			// verify missing hierarchy loaded and we've reached the end of this branch
			System.assertEquals(1, missingChildNodes.size());
			System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 5
			System.assertEquals(false, missingChildNodes[0].nodeChildren[0].hasMissingChildren); // level 5 has no missing children
		Test.stopTest();
	}
	
	static testMethod void lazyLoadChildAssetsBadInputs(){
		Test.startTest();
			try{
				List<ObjectNode> objectNodes = AssetHierarchyController.lazyLoadChildAssets(null, null, null);
				System.assert(false, 'lazyLoadChildAssets with null params should have thrown an error');
			}
			catch(Exception e){
				System.assert(e.getTypeName().contains('AssetHierarchyException'));
			}
		Test.stopTest();
	}
}