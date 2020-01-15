using NGetData.Response;
using System;
using System.Collections.Generic;
using System.Text;

namespace NGetData.Request
{
    public interface INGetRequest
    {
        byte Version { get; }
        byte ChecksumSeed { get; }
        byte[] Serialize();
        INGetRequest Deserialize(byte[] Data, int DataSize);
        INGetResponse GetResponse();
        string ToHex();
    }
}
