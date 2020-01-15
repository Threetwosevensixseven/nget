using NGetData.Response;
using System;
using System.Collections.Generic;
using System.Text;

namespace NGetData.Request
{
    public class NGetRequestV1 : INGetRequest
    {
        private bool testMode;

        // Must have a parameterless constructor
        public NGetRequestV1()
        {
        }

        public NGetRequestV1(bool TestMode)
        {
            testMode = TestMode;
        }

        public byte Version { get { return 1; } }

        public byte ChecksumSeed { get { return 44; } }

        public INGetResponse GetResponse()
        {
            return new NGetResponseV1(this);
        }

        public string ToHex()
        {
            var sb = new StringBuilder();
            foreach (byte b in Serialize())
                sb.Append(b.ToString("X2"));
            return sb.ToString();
        }

        public INGetRequest Deserialize(byte[] Data, int DataSize)
        {
            INGetRequest rv = null;

            // Explicitly check for test mode
            bool testMode = false;
            if (Data != null && Data.Length >= 4 && DataSize == 4)
            {
                var text = (Encoding.ASCII.GetString(Data, 0, 4) ?? "").Trim().ToUpper();
                testMode = text == "TEST";
            }

            // Test mode always validates
            if (testMode)
            {
                return this;
            }

            // Must be at least one byte for version
            if (Data == null || Data.Length <= 0 || Data.Length < DataSize || Data[0] != Version)
                return rv;

            // Must be at exactly two bytes
            if (DataSize != 2)
                return rv;

            // Checksum for all bytes except last must match last byte
            byte cs = ChecksumSeed;
            for (int i = 0; i < DataSize - 1; i++)
                cs ^= Data[i];
            if (Data[DataSize - 1] != cs)
                return rv;

            return this;
        }

        public byte[] Serialize()
        {
            if (testMode)
                return Encoding.ASCII.GetBytes("TEST");
            var rv = new List<byte>();
            rv.Add(Version);
            byte cs = ChecksumSeed;
            foreach (byte b in rv)
                cs ^= b;
            rv.Add(cs);
            return rv.ToArray();
        }
    }
}
