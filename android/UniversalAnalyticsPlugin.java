package com.danielcwilson.plugins.analytics;

import com.google.android.gms.analytics.GoogleAnalytics;
import com.google.android.gms.analytics.Logger.LogLevel;
import com.google.android.gms.analytics.HitBuilders;
import com.google.android.gms.analytics.Tracker;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map.Entry;

public class UniversalAnalyticsPlugin extends CordovaPlugin {
    public static final String START_TRACKER = "startTrackerWithId";
    public static final String TRACK_VIEW = "trackView";
    public static final String TRACK_EVENT = "trackEvent";
    public static final String TRACK_EXCEPTION = "trackException";
    public static final String TRACK_TIMING = "trackTiming";
    public static final String ADD_DIMENSION = "addCustomDimension";
    public static final String ADD_TRANSACTION = "addTransaction";
    public static final String ADD_TRANSACTION_ITEM = "addTransactionItem";
    public static final String SET_SAMPLING = "setSampling";

    public static final String SET_USER_ID = "setUserId";
    public static final String DEBUG_MODE = "debugMode";
    public static final String ENABLE_UNCAUGHT_EXCEPTION_REPORTING = "enableUncaughtExceptionReporting";

    public Boolean debugModeEnabled = false;
    public HashMap<Integer, String> customDimensions = new HashMap<Integer, String>();

    private HashMap<String, Tracker> trackers = new HashMap<String, Tracker>();

    private synchronized Tracker getTracker(String trackerId) {
        return trackers.get(trackerId);
    }

    private synchronized boolean trackerStarted(String trackerId) {
        return trackers.get(trackerId) != null;
    }

    private synchronized void addTracker(String trackerId, Tracker tracker) {
        trackers.put(trackerId, tracker);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (START_TRACKER.equals(action)) {
            String id = args.getString(0);
            this.startTracker(id, callbackContext);
            return true;
        } else if (TRACK_VIEW.equals(action)) {
            String screen = args.getString(0);
            String trackerId = args.getString(1);
            this.trackView(screen, trackerId, callbackContext);
            return true;
        } else if (TRACK_EVENT.equals(action)) {
            int length = args.length();
            if (length > 0) {
                this.trackEvent(
                        args.getString(0),
                        length > 1 ? args.getString(1) : "",
                                length > 2 ? args.getString(2) : "",
                                        length > 3 ? args.getLong(3) : 0,
                                                length > 4 ? args.getString(4) : "",
                                                        callbackContext);
            }
            return true;
        } else if (TRACK_EXCEPTION.equals(action)) {
            String description = args.getString(0);
            Boolean fatal = args.getBoolean(1);
            String trackerId = args.getString(2);
            this.trackException(description, fatal, trackerId, callbackContext);
            return true;
        } else if (TRACK_TIMING.equals(action)) {
            int length = args.length();
            if (length > 0) {
                this.trackTiming(args.getString(0), length > 1 ? args.getLong(1) : 0, length > 2 ? args.getString(2) : "", length > 3 ? args.getString(3) : "", length > 3 ? args.getString(4) : "", callbackContext);
            }
            return true;
        } else if (ADD_DIMENSION.equals(action)) {
            Integer key = args.getInt(0);
            String value = args.getString(1);
            this.addCustomDimension(key, value, callbackContext);
            return true;
        } else if (ADD_TRANSACTION.equals(action)) {
            int length = args.length();
            if (length > 0) {
                this.addTransaction(
                        args.getString(0),
                        length > 1 ? args.getString(1) : "",
                                length > 2 ? args.getDouble(2) : 0,
                                        length > 3 ? args.getDouble(3) : 0,
                                                length > 4 ? args.getDouble(4) : 0,
                                                        length > 5 ? args.getString(5) : null,
                                                                length > 6 ? args.getString(6) : "",
                                                                        callbackContext);
            }
            return true;
        } else if (ADD_TRANSACTION_ITEM.equals(action)) {
            int length = args.length();
            if (length > 0) {
                this.addTransactionItem(
                        args.getString(0),
                        length > 1 ? args.getString(1) : "",
                                length > 2 ? args.getString(2) : "",
                                        length > 3 ? args.getString(3) : "",
                                                length > 4 ? args.getDouble(4) : 0,
                                                        length > 5 ? args.getLong(5) : 0,
                                                                length > 6 ? args.getString(6) : null,
                                                                        length > 7 ? args.getString(7) : null,
                                                                                callbackContext);
            }
            return true;
        } else if (SET_USER_ID.equals(action)) {
            String userId = args.getString(0);
            String trackerId = args.getString(1);
            this.setUserId(userId, trackerId, callbackContext);
        } else if (DEBUG_MODE.equals(action)) {
            this.debugMode(callbackContext);
        } else if (ENABLE_UNCAUGHT_EXCEPTION_REPORTING.equals(action)) {
            Boolean enable = args.getBoolean(0);
            String trackerId = args.getString(1);
            this.enableUncaughtExceptionReporting(enable, trackerId, callbackContext);
        } else if (SET_SAMPLING.equals(action)) {
            Double sampling = args.getDouble(0);
            String trackerId = args.getString(1);
            this.setSampling(sampling, trackerId, callbackContext);
        }
        return false;
    }

    private void startTracker(String id, CallbackContext callbackContext) {
        if (null != id && id.length() > 0) {
            Tracker tracker = GoogleAnalytics.getInstance(this.cordova.getActivity()).newTracker(id);
            addTracker(id, tracker);
            callbackContext.success("tracker started");
            GoogleAnalytics.getInstance(this.cordova.getActivity()).setLocalDispatchPeriod(30);
        } else {
            callbackContext.error("tracker id is not valid");
        }
    }

    private void addCustomDimension(Integer key, String value, CallbackContext callbackContext) {
        if (key <= 0) {
            callbackContext.error("Expected positive integer argument for key.");
            return;
        }
    	
        if (null == value || value.length() == 0) {
            callbackContext.error("Expected non-empty string argument for value.");
            return;
        }
    		
        customDimensions.put(key, value);
        callbackContext.success("custom dimension started");
    }

    private <T> void addCustomDimensionsToHitBuilder(T builder) {
        //unfortunately the base HitBuilders.HitBuilder class is not public, therefore have to use reflection to use
        //the common setCustomDimension (int index, String dimension) method
        try {
            Method builderMethod = builder.getClass().getMethod("setCustomDimension", Integer.TYPE, String.class);
	    	
            for (Entry<Integer, String> entry : customDimensions.entrySet()) {
	            Integer key = entry.getKey();
	            String value = entry.getValue();
	            try {
	                builderMethod.invoke(builder, (key), value);
	            } catch (IllegalArgumentException e) {
	            } catch (IllegalAccessException e) {
	            } catch (InvocationTargetException e) {
	            }
            }
        } catch (SecurityException e) {
        } catch (NoSuchMethodException e) {
        }
    }

    private void trackView(String screenname, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);

        if (null != screenname && screenname.length() > 0) {
            tracker.setScreenName(screenname);
            
            HitBuilders.AppViewBuilder hitBuilder = new HitBuilders.AppViewBuilder();
            addCustomDimensionsToHitBuilder(hitBuilder);
            
            tracker.send(hitBuilder.build());
            System.out.println("GA SHOUTEM DEBUG performing: trackView on tracker" + trackerId);
            callbackContext.success("Track Screen: " + screenname);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }

    private void trackEvent(String category, String action, String label, long value, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);

        if (null != category && category.length() > 0) {
            HitBuilders.EventBuilder hitBuilder = new HitBuilders.EventBuilder();
            addCustomDimensionsToHitBuilder(hitBuilder);
            
            tracker.send(hitBuilder
                            .setCategory(category)
                            .setAction(action)
                            .setLabel(label)
                            .setValue(value)
                            .build()
            );
            callbackContext.success("Track Event: " + category);
        } else {
            callbackContext.error("Expected non-empty string arguments.");
        }
    }

    private void trackException(String description, Boolean fatal, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);

        if (null != description && description.length() > 0) {
            HitBuilders.ExceptionBuilder hitBuilder = new HitBuilders.ExceptionBuilder();
            addCustomDimensionsToHitBuilder(hitBuilder);
        	
            tracker.send(hitBuilder
                            .setDescription(description)
                            .setFatal(fatal)
                            .build()
            );
            callbackContext.success("Track Exception: " + description);
        } else {
            callbackContext.error("Expected non-empty string arguments.");
        }
    }

    private void trackTiming(String category, long intervalInMilliseconds, String name, String label, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);

        if (null != category && category.length() > 0) {
            HitBuilders.TimingBuilder hitBuilder = new HitBuilders.TimingBuilder();
            addCustomDimensionsToHitBuilder(hitBuilder);
        	
            tracker.send(hitBuilder
                            .setCategory(category)
                            .setValue(intervalInMilliseconds)
                            .setVariable(name)
                            .setLabel(label)
                            .build()
            );
            callbackContext.success("Track Timing: " + category);
        } else {
            callbackContext.error("Expected non-empty string arguments.");
        }
    }

    private void addTransaction(String id, String affiliation, double revenue, double tax, double shipping, String currencyCode, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);

        if (null != id && id.length() > 0) {
            HitBuilders.TransactionBuilder hitBuilder = new HitBuilders.TransactionBuilder();
            addCustomDimensionsToHitBuilder(hitBuilder);
        	
            tracker.send(hitBuilder
                            .setTransactionId(id)
                            .setAffiliation(affiliation)
                            .setRevenue(revenue).setTax(tax)
                            .setShipping(shipping)
                            .setCurrencyCode(currencyCode)
                            .build()
            ); //Deprecated
            callbackContext.success("Add Transaction: " + id);
        } else {
            callbackContext.error("Expected non-empty ID.");
        }
    }

    private void addTransactionItem(String id, String name, String sku, String category, double price, long quantity, String currencyCode, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);

        if (null != id && id.length() > 0) {
            HitBuilders.ItemBuilder hitBuilder = new HitBuilders.ItemBuilder();
            addCustomDimensionsToHitBuilder(hitBuilder);

            tracker.send(hitBuilder
                    .setTransactionId(id)
                    .setName(name)
                    .setSku(sku)
                    .setCategory(category)
                    .setPrice(price)
                    .setQuantity(quantity)
                    .setCurrencyCode(currencyCode)
                    .build()
                    ); //Deprecated
            callbackContext.success("Add Transaction Item: " + id);
        } else {
            callbackContext.error("Expected non-empty ID.");
        }
    }

    private void debugMode(CallbackContext callbackContext) {
        GoogleAnalytics.getInstance(this.cordova.getActivity()).getLogger().setLogLevel(LogLevel.VERBOSE);

        this.debugModeEnabled = true;
        callbackContext.success("debugMode enabled");
    }

    private void setUserId(String userId, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);
        tracker.set("&uid", userId);
        callbackContext.success("Set user id" + userId);
    }
    
    private void enableUncaughtExceptionReporting(Boolean enable, String trackerId, CallbackContext callbackContext) {
        if (!trackerStarted(trackerId)) {
            callbackContext.error("Tracker not started");
            return;
        }

        Tracker tracker = getTracker(trackerId);
        tracker.enableExceptionReporting(enable);
        callbackContext.success((enable ? "Enabled" : "Disabled") + " uncaught exception reporting");
    }

    private void setSampling(Double sampling, String trackerId, CallbackContext callbackContext) {
        Tracker tracker = getTracker(trackerId);

        if (tracker == null) {
            callbackContext.error("Tracker " + trackerId + " not found");
            return;
        }

        tracker.setSampleRate(sampling);
        callbackContext.success("Set sampling rate to: " + sampling);
    }
}
