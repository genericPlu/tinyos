
/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
 
 /*
 Flooding:
 1.Broadcast a packet
 Given in the pdf. 
 Mangaged to rebroadcast but thats about it.
 2.make alist of sent packets?
 Cant seem to get this one done.
 3.if not in list rebroadcast packet? 
 Cant figure out getting the list of src and seq right.
 Not sure im doing anything right here.
 4. TTL? no idea how implement
 
 Neighbor Discovery:
 Wont even finish flooding, SO doubt I will get to attempt this.
 This Project is clearly just betond my abililties.
 Guess the JC didnt prepare me well enough coding wise.
 I cant understand this code.....way to much. 
 I know some c and some c++ but clearly not enough.
 Barely can make sense out of this. Did my best.
 Never really worked on any code this complex. 
 I will likely fail or have to withdraw.

 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   
   uses interface Timer<TMilli> as Timer0;
   
   uses interface Hashmap<uint8_t> as map;
   
   uses interface List<pack> as list;
}

implementation{
   uint8_t counter = 0;
   uint8_t sequence = 0;
  
 
   
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   bool checkList(pack *Package);
   event void Boot.booted(){
      call AMControl.start();
	  

      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
   event void Timer0.fired(){


   }
 
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         if(myMsg->TTL == 0 || checkList(myMsg)){ 
			
				return msg;
			
         }
		 else if (TOS_NODE_ID == myMsg->dest){
		    dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
			dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence# %d\n", myMsg->payload, myMsg->seq);
			makePack(&sendPackage, TOS_NODE_ID, myMsg->dest, --myMsg->TTL, 0, sequence++, (uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
			call list.pushback(sendPackage);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
			dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
			return msg;
		}
		else{
			logPack(myMsg);
			makePack(&sendPackage, TOS_NODE_ID, myMsg->dest, --myMsg->TTL, 0, sequence++,(uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
			if(TOS_NODE_ID == 1)
				dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, TOS_NODE_ID + 1);
			else{
				dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d and Packet sent from Node %d to Node %d  \n" , TOS_NODE_ID, TOS_NODE_ID -1, TOS_NODE_ID, TOS_NODE_ID + 1);
				dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
				dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence# %d\n", myMsg->payload, myMsg->seq); 
			}
		
		
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
     }
	}
		

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, 0, ++sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
	  call list.pushback(sendPackage);
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
   bool checkList(pack *Package){
		uint16_t i;
		for( i = 0; i < call list.size(); i++){
			pack current = call list.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq )
					return TRUE;
		}
		return FALSE;
   }
   
}
