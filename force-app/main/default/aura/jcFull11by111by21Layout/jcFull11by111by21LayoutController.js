({
	init: function (component) {
		var jcUtils = component.find('jcUtils');
		component.set('v.isInBuilder', jcUtils.isInBuilder());
	}
});
