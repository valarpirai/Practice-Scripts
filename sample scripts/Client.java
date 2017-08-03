import java.net.*;
import java.io.*;

public class Client
{
   public static void main(String [] args)
   {
      String serverName = "9.0.0.1";
      String clientName = "9.0.0.101";
      int port = 9999;
      try
      {
         System.out.println("Connecting to " + serverName + " on port " + port);
         Socket client = new Socket(serverName, port);
         System.out.println("Just connected to " + client.getRemoteSocketAddress());
         OutputStream outToServer = client.getOutputStream();
         DataOutputStream out = new DataOutputStream(outToServer);

         out.writeUTF("Hello from " + client.getLocalSocketAddress());
         InputStream inFromServer = client.getInputStream();
         DataInputStream in = new DataInputStream(inFromServer);
         System.out.println("Server says " + in.readUTF());
	 
	Thread.sleep(5000);
        
	client.close();
      }catch(Exception e)
      {
         e.printStackTrace();
      }
   }
}
