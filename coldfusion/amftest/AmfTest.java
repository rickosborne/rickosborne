package org.rickosborne.java;

import flex.messaging.io.amf.client.AMFConnection;
import flex.messaging.io.amf.client.exceptions.ClientStatusException;
import flex.messaging.io.amf.client.exceptions.ServerStatusException;
import flex.messaging.messages.RemotingMessage;

import java.util.HashMap;
import java.util.UUID;

/**
 * @author Rick Osborne
 */
public class AmfTest {
	
	static String miCoachLoginClientId = "38cf965d-ae8f-4a81-9540-1edcfdb35d63";

	/**
	 * @param args The Flex Gateway, dotted path to the CFC, Destination, method name, and any arguments 
	 */
	public static void main(String[] args) {
		if (args.length < 4) {
			System.out.println("Usage: amftest http://127.0.0.1:80/flex2gateway ColdFusion path.to.cfc methodname [name1=value1 name2=value2 ...]");
			System.exit(-1);
		}
		// https://www.adidas.com/com/micoach/Gateway.aspx fluorine Molecular.AdidasCoach.Web.Services.UserProfileWS Login email password
		// String[] map = { args[4], args[5] };
		
		HashMap<String,Object> map = new HashMap<String,Object>();
		for (int i = 4; i < args.length; i++) {
			String[] pair = args[i].split("=");
			if (pair.length == 2) {
				map.put(pair[0], pair[1]);
			}
		}
		
		System.out.println(callCFCmethod(args[0], args[1], miCoachLoginClientId, args[2], args[3], map));
	}
	
	public static Object callCFCmethod(String gateway, String dest, String clientId, String cfcPath, String method, Object data) {
		Object ret = null;
		AMFConnection amfc = new AMFConnection();
		try {
			amfc.connect(gateway);
		}
		catch (ClientStatusException cse) {
			return cse;
		}
		RemotingMessage msg = new RemotingMessage();
		msg.setMessageId(UUID.randomUUID().toString());
		msg.setSource(cfcPath);
		msg.setOperation(method);
		msg.setBody(data);
		msg.setDestination(dest);
		msg.setClientId(clientId);
		try {
			ret = amfc.call(null, msg);
		}
		catch (ServerStatusException sse) {
			return sse;
		}
		catch (ClientStatusException cse) {
			return cse;
		}
		amfc.close();
		return ret;
	}

}
