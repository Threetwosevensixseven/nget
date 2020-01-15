using System;
using System.Collections.Generic;
using System.Text;

namespace NGetData.Response
{
    public interface INGetResponse
    {
        byte[] Serialize(string PackageDir);
        INGetResponse Deserialize(byte[] Data, int DataSize);
        string ToHex();
        string ToText();
    }
}
