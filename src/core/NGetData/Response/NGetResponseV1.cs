using NGetData.Request;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace NGetData.Response
{
    public class NGetResponseV1 : INGetResponse
    {
        private NGetRequestV1 request;
        private byte[] file;

        // Must have a parameterless constructor
        public NGetResponseV1()
        {
        }

        public NGetResponseV1(NGetRequestV1 Request)
        {
            request = Request;
        }

        public INGetResponse Deserialize(byte[] Data, int DataSize)
        {
            INGetResponse rv = null;

            // Must be at least one byte for version
            if (Data == null || Data.Length <= 0 || Data.Length < DataSize || Data[0] != request.Version)
                return rv;

            // Must be at least four bytes excluding payload
            if (Data.Length < 4)
                return rv;

            // Must be four bytes longer than payload
            int fileLength = Convert.ToInt32(Data[2] + (Data[3] * 256));
            int dataLength = fileLength + 4;
            if (DataSize != dataLength)
                return rv;

            // Checksum for all bytes except last must match last byte
            byte cs = Convert.ToByte(request.ChecksumSeed ^ Data[2] ^ Data[3]);
            for (int i = 4; i < dataLength - 1; i++)
                cs ^= Data[i];
            //if (Data[1] != cs)
            //    return rv;

            // Get File
            byte[] f = new byte[fileLength];
            Array.Copy(Data, 4, f, 0, fileLength);
            file = f;
            return this;
        }

        public byte[] Serialize(string PackageDir)
        {
            var rv = new List<byte>();
            try
            {
                rv.Add(request.Version);
                string fn = Path.Combine(PackageDir ?? "", "NGET");
                if (!File.Exists(fn))
                    return new byte[0];
                var file = File.ReadAllBytes(fn);
                byte lsb = Convert.ToByte(file.Length % 256);
                byte msb = Convert.ToByte(file.Length / 256);
                byte cs = Convert.ToByte(request.ChecksumSeed ^ rv[0] ^ lsb ^ msb);
                for (int i = 0; i < file.Length - 1; i++)
                    cs ^= file[i];
                rv.Add(cs);
                rv.Add(lsb);
                rv.Add(msb);
                rv.AddRange(file);
                return rv.ToArray();
            }
            catch
            {
                return new byte[0];
            }
        }

        public string ToHex()
        {
            var sb = new StringBuilder();
            foreach (byte b in Serialize(null))
                sb.Append(b.ToString("X2"));
            return sb.ToString();
        }

        public string ToText()
        {
            if (file == null)
                return "0 bytes";
            return file.Length + (file.Length == 1 ? " byte" : " bytes");
        }

        public byte[] GetFile()
        {
            return file;
        }
    }
}
