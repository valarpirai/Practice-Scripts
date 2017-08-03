import java.applet.Applet;
import java.awt.GridLayout;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.awt.*;
import javax.swing.JLabel;


public class IpFinder extends Applet {

	String ip,mac;
	
	public void init() {
		
		String s[] = getActiveIpAddress(true).split("IP");
		/*for (int i = 0; i < s.length; i++) {
			System.out.println(s[i]);
		}*/
		ip = "IP Address: "+s[0];
		mac = "Mac Address: "+s[1];
		
	};
	
	
	 public void paint(Graphics g) {

		 
		 g.drawString(ip, 10, 20);
		 g.drawString(mac, 10, 40);
		    }

	/**
	 * Create the applet.
	 */
	public IpFinder() {
		setLayout(new GridLayout(0, 1, 0, 0));
		
		JLabel lblIpAddress = new JLabel("IP Address: ");
		add(lblIpAddress);
		
		JLabel lblMacAddress = new JLabel("Mac Address: ");
		add(lblMacAddress);
		
		JLabel label = new JLabel("");
		add(label);

		
		
	}
public String getActiveIpAddress(boolean isSiteLocalAddress)

	{
		
		Pattern pattern = Pattern.compile("^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])$");
		
		//if isSiteLocalAddress = false, it will return only public addresses. else true, It will return the private IP address also. 

		try {

			for (Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements();) {

				NetworkInterface interf = en.nextElement();
				byte[] mac = interf.getHardwareAddress();
 
//					System.out.print("Your MAC address : ");
 
					StringBuilder sb = new StringBuilder();
					for (int i = 0; i < mac.length; i++) {
						sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "-" : ""));		
					}
//					System.out.println(sb.toString());


				for (Enumeration<InetAddress> enumIpAddr = interf.getInetAddresses(); enumIpAddr.hasMoreElements();) {

					InetAddress inetAddress = enumIpAddr.nextElement();

					//System.out.println(inetAddress.getHostAddress());
					
					Matcher matcher = pattern.matcher(inetAddress.getHostAddress());
		
						if(!inetAddress.isLoopbackAddress() && matcher.find()){ // && InetAddressUtils.isIPv4Address(inetAddress.getHostAddress().toUpperCase())){

						//MLog.d("", "***** Name :" + interf.getDisplayName()+" = " +inetAddress.getHostAddress());

						if(isSiteLocalAddress){

							String ip = inetAddress.getHostAddress();//Formatter.formatIpAddress(inetAddress.hashCode());

							// MLog.i(TAG, "***** site local IP="+ ip);

							return ip +"IP"+sb.toString();

						}

						else if (!inetAddress.isSiteLocalAddress()){ 

							String ip = inetAddress.getHostAddress();//Formatter.formatIpAddress(inetAddress.hashCode());

							//  MLog.i(TAG, "***** IP="+ ip);

							return ip;

						}

					}/*else if(InetAddressUtils.isIPv6Address(inetAddress.getHostAddress().toUpperCase())){

						String ip = inetAddress.getHostAddress();

						// MLog.i(TAG, "***** IPV6 = "+ ip);

						return ip;

					}*/
				}
			}

		} catch (Exception ex) {

			//ex.printstacktrace();

			return "0.0.0.0";

		}

		return "0.0.0.0";   
	}

}
