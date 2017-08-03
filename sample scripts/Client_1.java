
import java.net.*;
import java.io.*;

public class Client_1
{
   public static void main(String [] args)
   {
	String[] servers = new String[97];
	for (int i = 3; i <= 99; i++) 
	{
		servers[i - 3] = "9.0.0." + i;
	}
      final String[] serverName = servers;
      final int port = 9999;
      try
      {
         System.out.println("Connecting to " + serverName + " on port " + port);
        for (int i = 0; i < serverName.length; i++) 
        {
		final int j = i;
		new Thread(new Runnable() {
			public void run() {
			try {	
				Socket client = new Socket(serverName[j], port);
	       			System.out.println("Just connected to " + client.getRemoteSocketAddress());
	       			OutputStream outToServer = client.getOutputStream();
	       			DataOutputStream out = new DataOutputStream(outToServer);
				
				String tmp = "";
				for (int k = 0; k <= 1024; k++)
        			{
					tmp = tmp + "test str";
        			}	
				tmp = "";
					
	       			out.writeUTF("Hello from " + client.getLocalSocketAddress() + tmp);
	       			InputStream inFromServer = client.getInputStream();
	       			DataInputStream in = new DataInputStream(inFromServer);
	       			System.out.println("Server says " + in.readUTF());
	       			Thread.sleep(5000);
	       			out.writeUTF("Hello ");
	       			in = new DataInputStream(inFromServer);
	       			System.out.println("Server says " + in.readUTF());
	        
	       			Thread.sleep(10000);
	       			out.writeUTF("Bye");
	        	        
	        		client.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
			}
		}).start();
        }
      }catch(Exception e)
      {
         e.printStackTrace();
      }
   }
}          
