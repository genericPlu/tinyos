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

module NeighborDiscovery{
   
   uses interface SplitControl as AMControl;
   uses interface Receive;
      
   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   
   uses interface List<uint16_t*> as neighborList;
   
}

implementation{
   uint8_t sequence = 0;

   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
  
  //Added prototypes
   void createNeighborsList();
   bool checkSentList(pack *Package);
   
   //Added Timer0
   event void Boot.booted(){
      call AMControl.start();
	  call Timer0.startPeriodic(300000);
      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
   //Added Timer0 firing event to create neighbor list
   event void Timer0.fired(){
       createNeighborsList();

   }
 
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
		
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }
 
	
   //Modifed for flooding and neighbor discovery
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      
      if(len==sizeof(pack)){
        pack* myMsg=(pack*) payload;
        if(myMsg->TTL != 0 && !checkSentList(myMsg)){ 
			if(myMsg->dest == AM_BROADCAST_ADDR){
				if(call neighborList.size() == 19){
					return msg;
				}
				else if(myMsg->protocol == 1){
					//dbg(FLOODING_CHANNEL, "Node %d \n" , TOS_NODE_ID);
					if(call  neighborList.get(TOS_NODE_ID) !=myMsg->src && call neighborList.get(TOS_NODE_ID-1) !=myMsg->src)
						call  neighborList.pushback(myMsg->src);
					makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, --myMsg->TTL, 2, ++myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
					call list.pushback(sendPackage);
					call Sender.send(sendPackage, myMsg->src);
					
					makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, 2, 1, ++myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
					call list.pushback(sendPackage);
					call Sender.send(sendPackage, AM_BROADCAST_ADDR);
					
					return msg;
				}

				else if(myMsg->protocol == 2){ 
					if(call  neighborList.get(TOS_NODE_ID) !=myMsg->src && call neighborList.get(TOS_NODE_ID-1) !=myMsg->src)
						call  neighborList.pushback(myMsg->src);
					if(myMsg->src!=19){
						makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, --myMsg->TTL, 1, ++myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
						call list.pushback(sendPackage);
						call Sender.send(sendPackage, AM_BROADCAST_ADDR);
					}
					return msg;
				}
			
				return msg;
			}
			
		}	
	  }
	  return msg;
    }
	
		
    event void CommandHandler.printNeighbors(){
		uint16_t i;
		dbg(NEIGHBOR_CHANNEL, "Neighbor list for Node %d\n",TOS_NODE_ID);
		i = TOS_NODE_ID;
		if(TOS_NODE_ID == 1)
			dbg(NEIGHBOR_CHANNEL, "Neighbors:%d\n",call neighborList.get(1));
		else if(TOS_NODE_ID == 19)
			dbg(NEIGHBOR_CHANNEL, "Neighbors:%d\n",call neighborList.get(18));
		else
			dbg(NEIGHBOR_CHANNEL, "Neighbors:%d, %d\n",call neighborList.get(TOS_NODE_ID),call neighborList.get(TOS_NODE_ID-1));	
		
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

   void createNeighborsList(){
		uint16_t i;
		char * payload = "";
		call neighborList.pushback(TOS_NODE_ID);
		//dbg(NEIGHBOR_CHANNEL, "Creating neighbor list...\n");
		
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, 1, 50, (uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
		call list.pushback(sendPackage);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
		
		
   }
   
}
