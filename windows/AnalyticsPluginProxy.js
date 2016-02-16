	
	var handleResponse = function (res, success, error) {
        res = JSON.parse(res);
        if (res.error) {
            if (error) {
                error(res.error);
            }
        } else {
            if (success) {
                success(res.success);
            }
        }
    };
    module.exports = {
        startTrackerWithId: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.startTrackerWithId(JSON.stringify({
                    id: args[0]
                }));
                handleResponse(res, success, error);
            } catch (e) {
                error(e);
            }
        },
        setUserId: function(success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.setUserId(JSON.stringify({
                    id: args[0],
                    trackerId: args[1]
                }));
                handleResponse(res, success, error);
            } catch (e) {
                error(e);
            }
        },
        debugMode: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.debugMode();
                handleResponse(res, success, error);
            } catch (e) {
                error(e);
            }
        },
        trackView: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.trackView(JSON.stringify({
                    screen: args[0],
                    trackerId: args[1]
                }));
                handleResponse(res, success, error);
            } catch (e) {
                error(e);
            }
        },
        addCustomDimension: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.addCustomDimension(JSON.stringify({
                    key: args[0],
                    value: args[1]
                }));
                handleResponse(res, success, error);
            } catch (e) {
                error(e);
            }
        },
        trackEvent: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.trackEvent(JSON.stringify({
                    category: args[0],
                    action: args[1],
                    label: args[2],
                    value: args[3],
                    trackerId: args[4]
                }));
            } catch (e) {
                error(e);
            }
        },
        trackException: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.trackException(JSON.stringify({
                    description: args[0],
                    fatal: args[1],
                    trackerId: args[2]
                }));
            } catch (e) {
                error(e);
            }
        },
        trackTiming: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.trackTiming(JSON.stringify({
                    category: args[0],
                    intervalInMilliseconds: args[1],
                    name: args[2],
                    label: args[3],
                    trackerId: args[4]
                }));
            } catch (e) {
                error(e);
            }
        },
        addTransaction: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.addTransaction(JSON.stringify({
                    transactionId: args[0],
                    affiliation: args[1],
                    revenue: args[2],
                    tax: args[3],
                    shipping: args[4],
                    currencyCode: args[5],
                    trackerId: args[6]
                }));
            } catch (e) {
                error(e);
            }
        },
        addTransactionItem: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.addTransactionItem(JSON.stringify({
                    transactionId: args[0],
                    name: args[1],
                    sku: args[2],
                    category: args[3],
                    price: args[4],
                    quantity: args[5],
                    currencyCode: args[6],
                    trackerId: args[7]
                }));
            } catch (e) {
                error(e);
            }
        },
        setSampling: function (success, error, args) {
            try {
                var res = AnalyticsPlugin.Analytics.setSampling(JSON.stringify({
                    sampling: args[0],
                    trackerId: args[1]
                }));
            } catch (e) {
                error(e);
            }
        }
    };

	require("cordova/exec/proxy").add("UniversalAnalytics", module.exports);