public with sharing class JCFeedbackSchedule implements Schedulable {
	public void execute(SchedulableContext sc) {
		// Implement any logic to be scheduled

		// We now call the batch class to be scheduled
		JCFeedbackDigest digest = new JCFeedbackDigest();

		//Parameters of ExecuteBatch(context,BatchSize)
		database.executebatch(digest, 200);
	}
}
