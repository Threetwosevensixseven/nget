﻿using NGetData.Request;
using NGetServer.Classes;
using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

namespace NGetServer
{
    class Program
    {
        private static Socket serverSocket;
        private static bool newClients = true;
        private static byte[] data = new byte[dataSize];
        private const int dataSize = 1024;

        private static void Main(string[] args)
        {
            Console.WriteLine("Starting NGET Server...");
            Console.WriteLine("Connect timeout: " + Options.ConnectTimeoutMilliseconds + " ms");
            Console.WriteLine("Send timeout:    " + Options.SendTimeoutMilliseconds + " ms");
            Console.WriteLine("Receive timeout: " + Options.ReceiveTimeoutMilliseconds + " ms");
            serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            IPEndPoint endPoint = new IPEndPoint(IPAddress.Any, Options.TCPListeningPort); //12300
            serverSocket.Bind(endPoint);
            serverSocket.Listen(0);
            serverSocket.BeginAccept(new AsyncCallback(AcceptConnection), serverSocket);
            Console.WriteLine("Listening for TCP connections on port " + endPoint.Port + "...");
            while (true)
            {
                Thread.Sleep(1);
            }
        }

        private static void AcceptConnection(IAsyncResult result)
        {
            if (!newClients) return;
            Socket oldSocket = (Socket)result.AsyncState;
            Socket newSocket = oldSocket.EndAccept(result);
            newSocket.SendTimeout = Options.SendTimeoutMilliseconds;
            newSocket.ReceiveTimeout = Options.ReceiveTimeoutMilliseconds;
            Client client = new Client((IPEndPoint)newSocket.RemoteEndPoint);
            client.Register(newSocket);
            client.Socket = newSocket;
            client.Log("Connected");
            try
            {
                var acceptResult = serverSocket.BeginAccept(new AsyncCallback(AcceptConnection), serverSocket);
                client.Socket.BeginReceive(data, 0, dataSize, SocketFlags.None, new AsyncCallback(ReceiveData), client.Socket);
                Thread.Sleep(Options.ConnectTimeoutMilliseconds);
                if (client.Socket.Connected)
                {
                    client.Log("Connection timeout");
                    client.Disconnect();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
            }
        }

        private static void ReceiveData(IAsyncResult result)
        {
            try
            {
                Socket clientSocket = (Socket)result.AsyncState;
                var client = Client.Find(clientSocket);
                int received = clientSocket.EndReceive(result);
                if (received == 0)
                {
                    clientSocket.Close();
                    client.Disconnect();
                    return;
                }
                client.Log("Request " + ToHex(data, received));
                byte version = data[0];
                bool testMode = false;
                if (data != null && data.Length >= 4 && received == 4)
                {
                    var text = (Encoding.ASCII.GetString(data, 0, 4) ?? "").Trim().ToUpper();
                    testMode = text == "TEST";
                }
                if (testMode)
                    client.Log("Trying protocol version 1 (TEST mode)");
                else
                    client.Log("Trying protocol version " + version);
                var req = NGetRequestFactory.Create(version, data, received);
                if (req == null)
                {
                    client.Log("Cannot process protocol version");
                    if (client.Socket.Connected)
                    {
                        client.Disconnect();
                    }
                }
                else
                {
                    var resp = req.GetResponse();
                    var bytes = resp.Serialize(Options.PackageDir, Options.PackageFile);
                    client.Log("Response is " + ToText(bytes, bytes.Length) + " for package " + Options.PackageFile);
                    if (bytes != null && bytes.Length > 0)
                        clientSocket.BeginSend(bytes, 0, bytes.Length, SocketFlags.None,
                            new AsyncCallback(SendData), clientSocket);
                }
            }
            catch (InvalidOperationException)
            {
                // Catch timeout errors
            }
            catch (Exception ex)
            {
                // Report other errors without dying
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
            }
        }

        public static void SendData(IAsyncResult result)
        {
            try
            {
                Socket clientSocket = (Socket)result.AsyncState;
                var client = Client.Find(clientSocket);
                client.Disconnect();
            }
            catch
            {
            }
        }

        private static string ToHex(Byte[] Data, int Length)
        {
            var sb = new StringBuilder();
            var bs = Data == null ? new byte[0] : Data;
            for (int i = 0; i < Length; i++)
                sb.Append(bs[i].ToString("X2"));
            return sb.ToString();
        }

        private static string ToText(Byte[] Data, int Length)
        {
            if (Data == null || Data.Length < Length)
                return "0 bytes";
            return Length + (Length == 1 ? " byte" : " bytes");
        }
    }
}
