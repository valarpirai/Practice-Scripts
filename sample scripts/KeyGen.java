import java.util.Random;

public class KeyGen {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		//System.out.println(generateKey(36, 6));
		System.out.print("Key: ");
		System.out.println(generateKey(Integer.parseInt(args[0]), Integer.parseInt(args[1])));
	}

	static String generateKey(int keyLen, int suffix) {

		Random random = new Random();
		char[] keyStr = new char[keyLen + suffix];
		int constant = suffix;
		
		for (int i = 0; i < (keyLen + suffix - 1); i++) {

//			System.out.println(i +" "+suffix);

			int x = random.nextInt(43);
			x = x + '0';

			while (true)
			{
				if ((x > '0' && x < '9') || (x > 'A' && x < 'Z'))
				{
					keyStr[i] = (char) x;
					break;
				} else
				{
					x = random.nextInt(43) + '0';
				}
			}
			
			if(constant == i){
				keyStr[i] = '-';
				constant+=suffix;
				constant++;
			}
			
		}

		return new String(keyStr);
	}
}
