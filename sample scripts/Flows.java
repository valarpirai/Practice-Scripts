import java.io.*;

public class Flows {
	public static void main(String args[]) {
		int flow[] = new int[10];// { 1, 0, 7, 0, 0, 0, 0, 0, 0, 0 };
		int total = 0, active = 0, current = 0;
		BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
		try {
			for (int i = 0; i < 10; i++) {
				flow[i] = Integer.parseInt(in.readLine());
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		for (int i = 0; i < flow.length; i++) {
			current = flow[i];

			if (active > current) {
				active = current;
			} else if (active < current) {
				total += (current - active);
				active = current;
			}
		}

		System.out.println("Total: " + total + " Active: " + active
				+ " current: " + current);
	}
}
