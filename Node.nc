/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#define PACKETLIST_SIZE = 20;
module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   
   uses interface Timer<TMilli> as Timer0;
   
   uses interface List<uint8_t> as list;
   
}

implementation{
   uint8_t* a = (void*)19;
   uint8_t sequence = 0;
   uint16_t counter = 0;
   
   typedef struct packetlist{
		uint16_t src;
		uint16_t seq;
	}
	
	bool inPacktlist(uint16_t src, uint16_t seq){
		uint32_t i;
		for (i = 0; i < PACKETLIST_SIZE; i++) {
			if (src == packetlist[i].src && seq == packetlist[i].seq) {
				dbg(FLOODING_CHANNEL, "Found in list: src%u seq%u\n", src, seq);
				return TRUE;
			}
		}
		return FALSE;
	}

	void addToList(uint16_t src, uint16_t seq) {
		if (counter < PACKETLIST_SIZE) { 
			// add to end of currently extant list
			packetlist[counter].src = src;
			packetlist[counter].seq = seq;
			counter++;
		} else {
			uint32_t i;
			// shift all history over, erasing oldest
			for (i = 0; i<(PACKETLIST_SIZE-1); i++) {
				packetlist[i].src = History[i+1].src;
				packetlist[i].seq = History[i+1].seq;
			}
			// add to end of list
			packetlist[PACKETLIST_SIZE].src = theSrc;
			packetlist[PACKETLIST_SIZE].seq = theSeq;
		}
//		dbg(FLOODING_CHANNEL, "Added to packetlist: src%u seq%u\n", src, seq);
		return;
	}
   
   struct forwarded packetlist[PACKETLIST_SIZE];
   
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
	  

      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
   event void Timer0.fired(){
	call AMControl.stop();
	call AMControl.start();

   }
 
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){
		if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio Off\n");
      }else{
         //Retry until successful
         call AMControl.stop();
      }
	}
   
   

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      /*call Timer0.startOneShot(25);*/
	  dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
		 if (TOS_NODE_ID != myMsg->dest && !inPacktlist(myMsg->src,myMsg->seq){
			forwarded.addToList(myMsg->src, myMsg->seq);
			dbg(GENERAL_CHANNEL, "Package Payload: %s Sequence# %d\n", myMsg->payload, myMsg->seq);
			makePack(&sendPackage, TOS_NODE_ID, myMsg->dest, 0, 0, sequence, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
			dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
			return msg;
		}
		
         
		
         return msg;
      }
	  
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      
	  return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
	  dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, sequence++, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	  dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, destination);
   }

    event void CommandHandler.printNeighbors(){
		dbg(NEIGHBOR_CHANNEL, "Checking neighbors of %d \n", TOS_NODE_ID);

   }   
   
   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
