public with sharing class JCFilesController {
	// TODO write test class
	// TODO write method to get accepted file types
	@AuraEnabled
	public static JCResponse assignFilesToRecord(List<String> fileIds, String recordId) {
		JCResponse response = new JCResponse();
		try {
			if (Schema.sObjectType.ContentDocumentLink.isCreateable()) {
				List<ContentDocumentLink> linksToAdd = new List<ContentDocumentLink>();
				for (String fileId : fileIds) {
					linksToAdd.add(
						new ContentDocumentLink(ContentDocumentId = fileId, LinkedEntityId = recordId, ShareType = 'I')
					);
				}
				insert Security.stripInaccessible(AccessType.CREATABLE, linksToAdd).getRecords();
			}
		} catch (Exception e) {
			response.success = false;
			response.messages.add(
				'There was an error while processing your request. Please take note of the time and contact your system administrator.'
			);
		}
		return response;
	}
}
