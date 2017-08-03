/*
 * Java Network Programming, Second Edition
 * Merlin Hughes, Michael Shoffner, Derek Hamner
 * Manning Publications Company; ISBN 188477749X
 *
 * http://nitric.com/jnp/
 *
 * Copyright (c) 1997-1999 Merlin Hughes, Michael Shoffner, Derek Hamner;
 * all rights reserved; see license.txt for details.
 */

import java.io.*;
import java.util.*;

public class DNSQuery {
  private String queryHost;
  private int queryType, queryClass, queryID;
  private static int globalID;

  public DNSQuery (String host, int type, int clas) {
    StringTokenizer labels = new StringTokenizer (host, ".");
    while (labels.hasMoreTokens ())
      if (labels.nextToken ().length () > 63)
        throw new IllegalArgumentException ("Invalid hostname: " + host);
    queryHost = host;
    queryType = type;
    queryClass = clas;
    synchronized (getClass ()) {
      queryID = (++ globalID) % 65536;
    }
  }

  public String getQueryHost () {
    return queryHost;
  }

  public int getQueryType () {
    return queryType;
  }

  public int getQueryClass () {
    return queryClass;
  }

  public int getQueryID () {
    return queryID;
  }

  public byte[] extractQuery () {
    ByteArrayOutputStream byteArrayOut = new ByteArrayOutputStream ();
    DataOutputStream dataOut = new DataOutputStream (byteArrayOut);
    try {
      dataOut.writeShort (queryID);
      dataOut.writeShort ((0 << DNS.SHIFT_QUERY) |
                          (DNS.OPCODE_QUERY << DNS.SHIFT_OPCODE) |
                          (1 << DNS.SHIFT_RECURSE_PLEASE));
      dataOut.writeShort (1); // # queries
      dataOut.writeShort (0); // # answers
      dataOut.writeShort (0); // # authorities
      dataOut.writeShort (0); // # additional
      StringTokenizer labels = new StringTokenizer (queryHost, ".");
      while (labels.hasMoreTokens ()) {
        String label = labels.nextToken ();
        dataOut.writeByte (label.length ());
        dataOut.writeBytes (label);
      }
      dataOut.writeByte (0);
      dataOut.writeShort (queryType);
      dataOut.writeShort (queryClass);
    } catch (IOException ignored) {
    }
    return byteArrayOut.toByteArray ();
  }

  private Vector answers = new Vector ();
  private Vector authorities = new Vector ();
  private Vector additional = new Vector ();

  public void receiveResponse (byte[] data, int length) throws IOException {
    DNSInputStream dnsIn = new DNSInputStream (data, 0, length);
    int id = dnsIn.readShort ();
    if (id != queryID)
      throw new IOException ("ID does not match request");
    int flags = dnsIn.readShort ();
    decodeFlags (flags);
    int numQueries = dnsIn.readShort ();
    int numAnswers = dnsIn.readShort ();
    int numAuthorities = dnsIn.readShort ();
    int numAdditional = dnsIn.readShort ();
    while (numQueries -- > 0) { // discard questions
      String queryName = dnsIn.readDomainName ();
      int queryType = dnsIn.readShort ();
      int queryClass = dnsIn.readShort ();
    }
    try {
      while (numAnswers -- > 0)
        answers.addElement (dnsIn.readRR ());
      while (numAuthorities -- > 0)
        authorities.addElement (dnsIn.readRR ());
      while (numAdditional -- > 0)
        additional.addElement (dnsIn.readRR ());
    } catch (EOFException ex) {
      if (!truncated)
        throw ex;
    }
  }

  private boolean authoritative, truncated, recursive;

  protected void decodeFlags (int flags) throws IOException {
    boolean isResponse = ((flags >> DNS.SHIFT_QUERY) & 1) != 0;
    if (!isResponse)
      throw new IOException ("Response flag not set");
    int opcode = (flags >> DNS.SHIFT_OPCODE) & 15;
    // could check opcode
    authoritative = ((flags >> DNS.SHIFT_AUTHORITATIVE) & 1) != 0;
    truncated = ((flags >> DNS.SHIFT_TRUNCATED) & 1) != 0;
    boolean recurseRequest = ((flags >> DNS.SHIFT_RECURSE_PLEASE) & 1) != 0;
    // could check recurse request
    recursive = ((flags >> DNS.SHIFT_RECURSE_AVAILABLE) & 1) != 0;
    int code = (flags >> DNS.SHIFT_RESPONSE_CODE) & 15;
    if (code != 0)
      throw new IOException (DNS.codeName (code) + " (" + code + ")");
  }
  
  public boolean isAuthoritative () {
    return authoritative;
  }

  public boolean isTruncated () {
    return truncated;
  }

  public boolean isRecursive () {
    return recursive;
  }

  public Enumeration getAnswers () {
    return answers.elements ();
  }

  public Enumeration getAuthorities () {
    return authorities.elements ();
  }

  public Enumeration getAdditional () {
    return additional.elements ();
  }
}
