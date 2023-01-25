import { LightningElement, api } from 'lwc';
import { showToast, formatText } from 'c/jcUtils';
import manageSubscriptions from '@salesforce/apex/JCTopicController.manageSubscriptions';
import COMMUNITY_ID from '@salesforce/community/Id';
import USER_ID from '@salesforce/user/Id';

export default class JcFollowLink extends LightningElement {
	// Private Properties
	_isFollowingHolder = false;
	_topic;

	get _isFollowing() {
		return this._isFollowingHolder;
	}
	set _isFollowing(_isFollowing) {
		this._isFollowingHolder = _isFollowing;
	}

	// Private Reactive Properties
	customColor;

	get buttonLabel() {
		return this._isFollowing ? 'Unfollow' : 'Follow';
	}

	// Public Reactive Properties
	@api get darkFont() {
		return this._darkFont;
	}
	set darkFont(darkFont) {
		this._darkFont = darkFont;
		if (darkFont !== undefined) {
			this.customColor = darkFont ? 'black' : 'white';
		}
	}
	@api
	get topic() {
		return this._topic;
	}
	set topic(topic) {
		this._isFollowingHolder = topic.isFollowing;
		this._topic = topic;
	}

	// Handles the Follow/Unfollow functionality. If the user clicks the button, depending on the value of topic.isFollowing, it will call an apex method passing the value to either Follow/Unfollow the specific Topic.
	handleFollow = (event) => {
		event.preventDefault();
		event.stopPropagation();
		let params = {
			recordIds: [this.topic.id],
			userIds: [USER_ID],
			removeSubscription: this._isFollowing,
			communityId: COMMUNITY_ID
		};
		manageSubscriptions(params)
			.then((data) => {
				if (data.success) {
					this._isFollowing = !this._isFollowing;
					this.dispatchEvent(new CustomEvent('followchange'));
					showToast('success', formatText(data.messages[0], this.topic.title), 'Success', 'dismissable');
				} else {
					showToast('error', data.messages[0], 'Error Message', 'dismissable');
					console.error('Error Processing manageSubscriptions: ', data.messages[0]);
				}
			})
			.catch((error) => {
				showToast('error', error.body.message, 'Error Message', 'dismissable');
				console.error('Error Processing manageSubscriptions: ', error);
			});
	};
}
