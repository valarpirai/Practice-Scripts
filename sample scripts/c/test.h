#include<stdio.h>
//#include<netinet/in.h>
#include <winsock2.h>

#define MACLENGTH 6

typedef struct {
	unsigned char ucDestination[MACLENGTH];	/* Destination MAC Address*/
	unsigned char ucSource[MACLENGTH];	/* Source MAC Address*/
	int type_length;			/* Ethernet Type or Length */
} Ethernet;

typedef struct {
	unsigned char ihl:4;			/* header length */
	unsigned char ver:4;			/* version */
	unsigned char tos;			/* type of service */
	unsigned short int length;		/* total length */
	unsigned short int identification;	/* identification */
	unsigned short int flag_offset;		/* fragment offset field */
	unsigned char ttl;			/* time to live */
	unsigned char protocol;			/* protocol */
	unsigned short int checksum;		/* checksum */
	unsigned long int Source,Destination;	/* source and dest address */
} Packet;

typedef struct {
	unsigned short int SourcePort;		/* Source Port Number*/
	unsigned short int DestPort;		/* Destination Port Numebr*/
	unsigned long int seq_num;		/* Sequence Number */
	unsigned long int ack_num;		/* Acknowledge Number*/
	unsigned short int h_length;		/* Header Length*/

	unsigned short int identification;
	unsigned short int flag_offset;
	unsigned char ttl;
	unsigned char protocol;
	unsigned short int checksum;
} TCPSegment;

typedef struct {
	unsigned short int SourcePort;
	unsigned short int DestPort;
	unsigned short int Length;
	unsigned short int CheckSum;

} UDPDatagram;



int main(void)
{
	unsigned char ucSingle;
	int iLoop,iVal;
	char *ptr;

	Ethernet frame;

	printf("Enter the MAC address of the destination\n");
	for(iLoop=0; iLoop<MACLENGTH;iLoop++)
	{
		printf("\nOctet %d = ",iLoop);
		scanf("%d",&iVal);
		frame.ucDestination[iLoop] = (unsigned char) iVal;
	}
	printf("Enter the type length field value (0x800==IP)\n");
	scanf("%d",&frame.type_length);

	ptr = (char *)&frame;
	printf("frame complete\n");
	for(iLoop=0;iLoop<14;iLoop++)
	{
		ucSingle = (unsigned char)ptr[iLoop];
		printf("[%02X]",(int) ucSingle);
	}
	return 0;
}

int main(void) {
	unsigned char ucSingle;
	int iLoop,iVal;
	char *ptr;
	Packet frame;
	Packet packet;

	printf("The size: %d\n", sizeof(Packet));
	//ADD YOUR CODE HERE

	printf("Creating destination MAC address\n");
	ptr = (char *)frame.ucDestination;
	for(iLoop=0;iLoop<MACLENGTH;iLoop++) {
		printf("\nOctet%d=",iLoop);
		scanf("%d", &iVal);
		ptr[iLoop] = (unsigned char)iVal;
	}
	
	printf("Enter the the type of length field value \n");
	scanf("%d",&frame.length);
	
	packet.ver = 4;
	packet.ihl = 5;
	packet.tos = 0;
	packet.length = htons(0x4321);
	packet.identification = htons(0x9876);
	packet.flag_offset = 0;
	packet.ttl = 64;
	packet.protocol = 6;
	packet.checksum = htons(0x1111);
	packet.ucSource = htonl(0xc0a8fa03);
	packet.ucDestination = htonl(0xc0a8faa8);
	
	ptr = (char*) &frame;
	printf("frame complete\n");
	for(iLoop=0;iLoop<14;iLoop++) {
		ucSingle = (unsigned char)ptr[iLoop];
		printf("[%d]",(int)ucSingle);
	}
	
	ptr = (char*)&packet;
	printf("packet complete\n");
	
	for(iLoop=0;iLoop<20;iLoop++) {
		ucSingle = (unsigned char)ptr[iLoop];
		printf("[%d]",(int)ucSingle);
	}

	return 0;
}

