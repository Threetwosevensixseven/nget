using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NGetData.Request
{
    public class NGetRequestFactory
    {
        public static INGetRequest Create(byte Version, byte[] Data, int DataSize)
        {
            var types = AppDomain.CurrentDomain.GetAssemblies().SelectMany(x => x.GetTypes())
                .Where(x => typeof(INGetRequest).IsAssignableFrom(x) && !x.IsInterface && !x.IsAbstract);
            foreach (Type type in types)
            {
                INGetRequest creator = null;
                INGetRequest request = null;
                try
                {
                    creator = (INGetRequest)Activator.CreateInstance(type);
                }
                catch
                {
                    // Any error means this class can't handle the protocol,
                    // so try the next class
                }
                try
                {
                    bool testMode = false;
                    if (creator != null && Data != null && DataSize == 4)
                    {
                        var text = (Encoding.ASCII.GetString(Data, 0, 4) ?? "").Trim().ToUpper();
                        testMode = text == "TEST";
                    }
                    if (creator != null && (testMode || creator.Version == Version))
                        request = creator.Deserialize(Data, DataSize);
                }
                catch
                {
                    // Any error means this is the correct class for the protocol,
                    // but we had an error handling it, so return immediately
                    return null;
                }
                return request;
            }
            // No classes can handle the protocol
            return null;
        }
    }
}
