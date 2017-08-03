
import java.net.*;
import java.io.*;

public class Server extends Thread {
	private ServerSocket serverSocket;

	public Server(int port) throws IOException {
		serverSocket = new ServerSocket(port);
		// serverSocket.setSoTimeout(10000);
	}

	public void run() {
		while (true) {
			try {
				System.out.println("Waiting for client on port "
						+ serverSocket.getLocalPort() + "...");
				final Socket server = serverSocket.accept();
				new Thread(new Runnable() {

					@Override
					public void run() {
						try {
							while (true) {
								try {
									DataInputStream in = new DataInputStream(
											server.getInputStream());
									String str = in.readUTF();
									System.out.println(str);
									
									if(str.equalsIgnoreCase("Bye"))
										break;
									
									DataOutputStream out = new DataOutputStream(
											server.getOutputStream());

									out.writeUTF("Thank you for connecting to "
											+ server.getLocalSocketAddress()
											+ "\nGoodbye!");
									
								} catch (SocketTimeoutException s) {
									System.out.println("Socket timed out!");
									break;
								} catch (IOException e) {
									e.printStackTrace();
									break;
								}
							}
							server.close();
						} catch (IOException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					}
				}).start();

			} catch (SocketTimeoutException s) {
				System.out.println("Socket timed out!");
				break;
			} catch (IOException e) {
				e.printStackTrace();
				break;
			}
		}
	}

	public static void main(String[] args) {
		int port = 9999;
		try {
			Thread t = new Server(port);
			t.start();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
