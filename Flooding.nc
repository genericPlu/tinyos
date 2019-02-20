/*
 * ANDES Lab - University of California, Merced
   This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *Adam Pluguez CSE160 Project1 Updated 2/12/19
 
 */

#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Flooding{
   
   uses interface Receive;
   
   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   
   uses interface List<pack> as list;
    
}

implementation{
   uint8_t sequence = 0;

   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
  
  //Added prototypes
   bool checkSentList(pack *Package);
   
   //Modifed for flooding and neighbor discovery
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){  
      if(len==sizeof(pack)){
        pack* myMsg=(pack*) payload;
        if(myMsg->TTL != 0 && !checkSentList(myMsg)){ 
			if(TOS_NODE_ID == myMsg->dest && myMsg->protocol == 0){
				dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
				dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence %d\n", myMsg->payload, myMsg->seq);
				if(myMsg->seq ==1)
					dbg(FLOODING_CHANNEL, "Flooding Successful!\n");
				return msg;
			}
			else if (myMsg->dest != myMsg->src && myMsg->dest != AM_BROADCAST_ADDR&& myMsg->protocol == 0){
				makePack(&sendPackage, myMsg->src, myMsg->dest, --myMsg->TTL, 0, myMsg->seq,myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call list.pushback(sendPackage);
				dbg(FLOODING_CHANNEL, "Flooding Packet Received at Node %d for Node %d. Resending..\n", TOS_NODE_ID, myMsg->dest);
				call Sender.send(sendPackage, AM_BROADCAST_ADDR);
				dbg(FLOODING_CHANNEL, "Flooding Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
				return msg;
			
			}
			else if(TOS_NODE_ID == myMsg->dest && myMsg->protocol == 0){
				dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
				dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence %d\n", myMsg->payload, myMsg->seq);
				return msg;
			}
			else if (myMsg->dest != myMsg->src && myMsg->dest != AM_BROADCAST_ADDR&& myMsg->protocol == 0){
				makePack(&sendPackage, myMsg->src, myMsg->dest, --myMsg->TTL, 0, myMsg->seq,myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call list.pushback(sendPackage);
				dbg(FLOODING_CHANNEL, "Flooding Packet Received at Node %d for Node %d. Resending..\n", TOS_NODE_ID, myMsg->dest);
				call Sender.send(sendPackage, AM_BROADCAST_ADDR);
				dbg(FLOODING_CHANNEL, "Flooding Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
				return msg;
			}
		}	
		return msg;
	  }
    }
	
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   
   bool checkSentList(pack *Package){
		uint16_t i;
		for(i = 0; i < call list.size(); i++){
			pack current = call list.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq )
					return TRUE;
		}
		return FALSE;
    }

   
}
