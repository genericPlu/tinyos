/*
 * ANDES Lab - University of California, Merced
   This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *Adam Pluguez CSE160 Project2 Updated 2/20/19
 
 */

#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include "includes/moteN.h"


module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;
   
   uses interface Random as Random;
   
   uses interface SimpleSend as Sender;
	
   uses interface NeighborDiscovery ;
   
   uses interface CommandHandler;
   
   uses interface List<pack> as sentlist;
   
   
}

implementation{
   uint8_t sequence = 0;
   pack sendPackage;  
   

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   bool checkSentList(pack *Package);
   
  
   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
	  
   }
   
  
 
   event void AMControl.startDone(error_t err){
	  if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
		 call NeighborDiscovery.run();
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }
 
   event void AMControl.stopDone(error_t err){}
	
   //Modifed for flooding and neighbor discovery
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
	  if(len==sizeof(pack)){
        pack* myMsg=(pack*) payload;
        if(myMsg->TTL != 0 && !checkSentList(myMsg)){ 
			if(TOS_NODE_ID == myMsg->dest && myMsg->protocol == PROTOCOL_PING){
				dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
				dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence %d\n", myMsg->payload, myMsg->seq);
				if(myMsg->seq ==1)
					dbg(FLOODING_CHANNEL, "Flooding Successful!\n");
				return msg;
			}
			else if (myMsg->dest != myMsg->src && myMsg->dest != AM_BROADCAST_ADDR&& myMsg->protocol == PROTOCOL_PING){
				makePack(&sendPackage, myMsg->src, myMsg->dest, --myMsg->TTL, 0, myMsg->seq,(uint8_t*)myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call sentlist.pushback(sendPackage);
				//dbg(FLOODING_CHANNEL, "Flooding Packet Received at Node %d for Node %d. Resending..\n", TOS_NODE_ID, myMsg->dest);
				call Sender.send(sendPackage, AM_BROADCAST_ADDR);
				//dbg(FLOODING_CHANNEL, "Flooding Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
				return msg;
			
			}
		}	
		return msg;
	  }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
    }
	
		

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      //dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, PROTOCOL_PING, ++sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
	  call sentlist.pushback(sendPackage);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);

	  
   }

    event void CommandHandler.printNeighbors(){
		call NeighborDiscovery.printNeighbors();
		
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
   
   bool checkSentList(pack *Package){
		uint16_t i;
		for(i = 0; i < call sentlist.size(); i++){
			pack current = call sentlist.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq )
					return TRUE;
		}
		return FALSE;
    }
   
}
