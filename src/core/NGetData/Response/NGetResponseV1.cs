using NGetData.Request;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
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

        public byte[] Serialize(string PackageDir, string PackageFile)
        {
            var rv = new List<byte>();
            try
            {
                rv.Add(request.Version);
                string fn = Path.Combine(PackageDir ?? "", PackageFile ?? "");
                if (!File.Exists(fn))
                    return new byte[0];
                var file = File.ReadAllBytes(fn);
                byte lsb = Convert.ToByte(file.Length % 256);
                byte msb = Convert.ToByte(file.Length / 256);
                byte cs = request.ChecksumSeed;
                for (int i = 0; i < file.Length; i++)
                    cs ^= file[i];
                cs ^= request.Version;
                cs ^= lsb;
                cs ^= msb;
                rv.Add(cs);
                rv.Add(lsb);
                rv.Add(msb);
                rv.AddRange(file);

                //Console.WriteLine("                      RspBytes: " + ToHex(rv));
                //Console.WriteLine("                      Checksum: " + cs.ToString("X2"));

                return rv.ToArray();
            }
            catch
            {
                return new byte[0];
            }
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
            byte cs = request.ChecksumSeed;
            for (int i = 4; i < dataLength; i++)
                cs ^= Data[i];
            cs ^= request.Version;
            cs ^= Data[2];
            cs ^= Data[3];

            //Console.WriteLine("RspBytes: " + ToHex(Data, DataSize));
            //Console.WriteLine("Checksum: " + cs.ToString("X2"));

            if (Data[1] != cs)
                return rv;

            // Get File
            byte[] f = new byte[fileLength];
            Array.Copy(Data, 4, f, 0, fileLength);
            file = f;

            //Console.WriteLine("File: " + ToHex(file));
            //Console.WriteLine("Checksum matches");

            return this;
        }

        public string ToHex()
        {
            var sb = new StringBuilder();
            foreach (byte b in Serialize(null, null))
                sb.Append(b.ToString("X2"));
            return sb.ToString();
        }

        private string ToHex(IEnumerable<byte> Bytes, int Length = -1)
        {
            var sb = new StringBuilder();
            if (Length < 0)
            {
                foreach (byte b in Bytes ?? new byte[0])
                    sb.Append(b.ToString("X2"));
            }
            else
            {
                var bs = Bytes == null ? new byte[0] : Bytes.ToArray();
                for (int i = 0; i < Length; i++)
                {
                    sb.Append(bs[i].ToString("X2"));
                }
            }
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
