/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce Services
Description:	Generic container FieldSet fields, used in a Lightning Component
				Note: modified from http://salesforce.stackexchange.com/questions/56047/how-to-use-fieldsets-with-lightning
Test Class:		

History:
<Date>			<Authors Name>		<Brief Description of Change>
12/20/2016		Denise Bacher		Initial Creation
------------------------------------------------------------*/
public class FieldSetMember {
	@AuraEnabled public Boolean DBRequired { get;set; }
	@AuraEnabled public String fieldPath { get;set; }
	@AuraEnabled public String label { get;set; }
	@AuraEnabled public Boolean required { get;set; }
	@AuraEnabled public String type { get; set; }
	
	public FieldSetMember(Schema.FieldSetMember f) {
		this.DBRequired = f.DBRequired;
		this.fieldPath = f.fieldPath;
		this.label = f.label;
		this.required = f.required;
		this.type = '' + f.getType();
	}
}