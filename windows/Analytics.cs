using GoogleAnalytics.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.ApplicationModel;
using Windows.Data.Json;

namespace AnalyticsPlugin
{
    public sealed class Analytics
    {
        private static TrackerManager trackerManager = new TrackerManager(new PlatformInfoProvider());
        private static IDictionary<int, string> customDimensions = new Dictionary<int, string>();
        private static IDictionary<string, Tracker> trackers = new Dictionary<string, Tracker>();

        public static string StartTrackerWithId(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string id = jsonObject.GetNamedString("id");
            if (!String.IsNullOrWhiteSpace(id))
            {
                Tracker tracker = trackerManager.GetTracker(id);
                tracker = trackerManager.GetTracker(id);
                tracker.SetStartSession(true);
                tracker.IsUseSecure = true;
                tracker.AppName = AppInfoProvider.ApplicationName;
                tracker.AppVersion = AppInfoProvider.ApplicationVersion;
                AddTracker(id, tracker);

                return SuccessResponse("tracker started");
            }
            else
            {
                return ErrorResponse("tracker id is not valid");
            }
        }

        public static string SetUserId(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string id = jsonObject.GetNamedString("id");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(id);
            if (tracker != null)
            {
                tracker.UserId = id;

                return SuccessResponse("Set user id" + id);
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string DebugMode(string options)
        {
            trackerManager.IsDebugEnabled = true;

            return SuccessResponse("");
        }

        public static string TrackView(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string screen = jsonObject.GetNamedString("screen");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                if (!String.IsNullOrWhiteSpace(screen))
                {
                    AddCustomDimensionsToTracker(tracker);
                    tracker.SendView(screen);
                    return SuccessResponse("Track Screen: " + screen);
                }
                else
                {
                    return ErrorResponse("Expected one non-empty string argument.");
                }
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string AddCustomDimension(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            int key = int.Parse(jsonObject.GetNamedString("key"));
            string value = jsonObject.GetNamedString("value");

            if (key <= 0)
            {
                return ErrorResponse("Expected positive integer argument for key.");
            }
            else if (String.IsNullOrWhiteSpace(value))
            {
                return ErrorResponse("Expected non-empty string argument for value.");
            }
            else
            {
                customDimensions.Add(key, value);

                return SuccessResponse("Add Custom Dimension: " + key);
            }
        }

        public static string TrackEvent(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string category = jsonObject.GetNamedString("category");
            string action = jsonObject.GetNamedString("action");
            string label = jsonObject.GetNamedString("label");
            long value = long.Parse(jsonObject.GetNamedString("value"));
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                if (!String.IsNullOrWhiteSpace(category))
                {
                    AddCustomDimensionsToTracker(tracker);
                    tracker.SendEvent(category, action, label, value);

                    return SuccessResponse("Track Event: " + category);
                }
                else
                {
                    return ErrorResponse("Expected non - empty string arguments.");
                }
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string TrackException(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string description = jsonObject.GetNamedString("description");
            bool fatal = jsonObject.GetNamedBoolean("fatal");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                if (!String.IsNullOrWhiteSpace(description))
                {
                    AddCustomDimensionsToTracker(tracker);
                    tracker.SendException(description, fatal);

                    return SuccessResponse("Track Exception: " + description);
                }
                else
                {
                    return ErrorResponse("Expected non - empty string arguments.");
                }
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string TrackTiming(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string category = jsonObject.GetNamedString("category");
            long intervalInMilliseconds = long.Parse(jsonObject.GetNamedString("intervalInMilliseconds"));
            string name = jsonObject.GetNamedString("name");
            string label = jsonObject.GetNamedString("label");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                if (!String.IsNullOrWhiteSpace(category))
                {
                    AddCustomDimensionsToTracker(tracker);
                    tracker.SendTiming(TimeSpan.FromMilliseconds(intervalInMilliseconds), category, name, label);

                    return SuccessResponse("Track Timing: " + category);
                }
                else
                {
                    return ErrorResponse("Expected non - empty string arguments.");
                }
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string AddTransaction(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string id = jsonObject.GetNamedString("id");
            string affiliation = jsonObject.GetNamedString("affiliation");
            double revenue = jsonObject.GetNamedNumber("revenue");
            double tax = jsonObject.GetNamedNumber("tax");
            double shipping = jsonObject.GetNamedNumber("shipping");
            string currencyCode = jsonObject.GetNamedString("currencyCode");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                if (!String.IsNullOrWhiteSpace(id))
                {
                    Transaction transaction = new Transaction();
                    transaction.TransactionId = id;
                    transaction.Affiliation = affiliation;
                    transaction.TotalCostInMicros = (long)(revenue * 1000000);
                    transaction.TotalTaxInMicros = (long)(tax * 1000000);
                    transaction.ShippingCostInMicros = (long)(shipping * 1000000);
                    transaction.CurrencyCode = currencyCode;

                    AddCustomDimensionsToTracker(tracker);
                    tracker.SendTransaction(transaction);

                    return SuccessResponse("Add Transaction: " + transaction.TransactionId);
                }
                else
                {
                    return ErrorResponse("Expected non-empty ID.");
                }
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string AddTransactionItem(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            string id = jsonObject.GetNamedString("id");
            string name = jsonObject.GetNamedString("name");
            string sku = jsonObject.GetNamedString("sku");
            string category = jsonObject.GetNamedString("category");
            double price = jsonObject.GetNamedNumber("price");
            long quantity = long.Parse(jsonObject.GetNamedString("quantity"));
            string currencyCode = jsonObject.GetNamedString("currencyCode");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                if (!String.IsNullOrWhiteSpace(id))
                {
                    TransactionItem transactionItem = new TransactionItem();
                    transactionItem.TransactionId = id;
                    transactionItem.Name = name;
                    transactionItem.SKU = sku;
                    transactionItem.Category = category;
                    transactionItem.PriceInMicros = (long)(price * 1000000);
                    transactionItem.Quantity = quantity;
                    transactionItem.CurrencyCode = currencyCode;

                    AddCustomDimensionsToTracker(tracker);
                    tracker.SendTransactionItem(transactionItem);

                    return SuccessResponse("Add Transaction Item: " + transactionItem.TransactionId);
                }
                else
                {
                    return ErrorResponse("Expected non-empty ID.");
                }
            }
            else
            {
                return ErrorResponse("Tracker not started");
            }
        }

        public static string SetSampling(string options)
        {
            JsonObject jsonObject = JsonObject.Parse(options);
            double sampling = jsonObject.GetNamedNumber("sampling");
            string trackerId = jsonObject.GetNamedString("trackerId");
            Tracker tracker = GetTracker(trackerId);
            if (tracker != null)
            {
                tracker.SampleRate = (float)sampling;
                return SuccessResponse("Set sampling rate to: " + sampling);
            }
            else
            {
                return ErrorResponse("Tracker " + trackerId + " not found");
            }
        }

        private static Tracker GetTracker(string id)
        {
            return trackers[id];
        }

        private static void AddTracker(string id, Tracker tracker)
        {
            trackers.Add(id, tracker);
        }
        
        private static void AddCustomDimensionsToTracker(Tracker tracker)
        {
            foreach (KeyValuePair<int, string> dimension in customDimensions)
            {
                tracker.SetCustomDimension(dimension.Key, dimension.Value);
            }
        }

        private static string ErrorResponse(string message)
        {
            JsonObject error = new JsonObject();
            error.Add("error", JsonValue.CreateStringValue(message));
            return error.Stringify();
        }

        private static string SuccessResponse(string message)
        {
            JsonObject success = new JsonObject();
            success.Add("success", JsonValue.CreateStringValue(message));
            return success.Stringify();
        }
    }
}
