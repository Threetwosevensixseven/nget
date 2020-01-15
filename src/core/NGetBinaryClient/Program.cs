using NGetData.Request;
using NGetData.Response;
using System;
using System.Linq;
using System.Net.Sockets;
using System.Text;

namespace NGetBinaryClient
{
    public class Program
    {
        public const byte VERSION = 1;
        public static string ServerAddress;
        public static int Port;
        public static bool Interactive;
        public static bool Help;
        public static bool TestMode;

        private static int Main(string[] args)
        {
            try
            {
                Interactive = args.Any(a => a == "-i");
                Help = args.Any(a => a == "-h");
                TestMode = args.Any(a => a == "-t");
                if (Help)
                    return Usage();
                var address = (args.Length > 0 ? args[0] : "").Split(':', 2);
                ServerAddress = (address.Length > 0 ? address[0] : "").Trim();
                string cPort = (address.Length > 1 ? address[1] : "").Trim();
                int.TryParse(cPort, out Port);
                if (string.IsNullOrWhiteSpace(ServerAddress) || ServerAddress.StartsWith('-'))
                    return Usage();
                if (Port <= 0 || Port > 65535)
                    return Usage();
                var zArgs = args.Where(a => a.StartsWith("-z=")).ToList();
                if (zArgs.Count > 1)
                    return Usage();
                if (zArgs.Count > 0 && zArgs[0].Length <= 3)
                    return Usage();

                NGetRequestV1 req;
                if (TestMode)
                    req = new NGetRequestV1(true);
                else
                    req = new NGetRequestV1();

                if (TestMode)
                    Console.WriteLine("Requesting package in TEST mode...");
                else
                    Console.WriteLine("Requesting package...");

                Console.WriteLine("Connecting to server " + ServerAddress + " on port " + Port + "...");
                using (var client = new TcpClient(ServerAddress, Port))
                {
                    Byte[] data = req.Serialize();
                    Console.WriteLine("Request: {0}", req.ToHex());
                    using (var stream = client.GetStream())
                    {
                        // TESTING: Tests connection or receive timeout on the server
                        //Console.WriteLine("DEBUG: Pausing after connect, press any key...");
                        //Console.ReadKey();

                        // TESTING: Tests malformed packet on the server
                        //data[0] = 255;
                        //stream.Write(data, 0, 1);

                        stream.Write(data, 0, data.Length);

                        // TESTING: Tests send timeout on the server
                        //Console.WriteLine("DEBUG: Pausing after send, press any key...");
                        //Console.ReadKey();

                        data = new Byte[1024];
                        int read = stream.Read(data, 0, data.Length);
                        Console.WriteLine("Response is {0} byte(s)", read);
                        var resp = (NGetResponseV1)req.GetResponse().Deserialize(data, read);
                        if (resp == null)
                            Console.WriteLine("Result could not be processed");
                        else
                            Console.WriteLine("Result: {0}",
                              resp.ToText());
                    }
                    Console.WriteLine("Closing connection");
                }
                return 0;
            }
            catch (SocketException ex)
            {
                Console.WriteLine(ex.Message);
                return 2;
            }
            catch (Exception ex)
            {
                var x = ex.GetType();
                Console.WriteLine();
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
                return 2;
            }
            finally
            {
                if (Interactive)
                {
                    Console.WriteLine();
                    Console.WriteLine("Press any key to continue...");
                    Console.ReadKey();
                }
            }
        }

        private static int Usage()
        {
            Console.WriteLine("NXTP ServerAddress:Port [-h [-i]]");
            return 1;
        }

        private static string ToHex(Byte[] Data, int Length)
        {
            if (Data == null || Data.Length < Length)
                return "";
            var sb = new StringBuilder();
            for (int i = 0; i < Length; i++)
                sb.Append(Data[i].ToString("X2"));
            return sb.ToString();
        }
    }
}
