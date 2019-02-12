
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

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;
   
   uses interface Random as Random;
   
   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   
   uses interface Timer<TMilli> as Timer0;
   
   uses interface Hashmap<uint16_t> as neighborMap;
   
   uses interface List<pack> as list;
   
   uses interface List<uint16_t*> as neighborList;
   
}

implementation{
   uint8_t counter = 0;
   uint8_t sequence = 0;
   
 
	
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   bool checkSentList(pack *Package);
   void createNeighborsList();
   
   
   event void Boot.booted(){
      call AMControl.start();
	  //call Timer0.startPeriodic(100000);
      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
   event void Timer0.fired(){
       createNeighborsList();
	   dbg(GENERAL_CHANNEL, "TIMER FIRED\n");
	   call Timer0.stop();

   }
 
   event void AMControl.startDone(error_t err){
      createNeighborsList();
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
        if(myMsg->TTL != 0 && !checkSentList(myMsg)){ 
			//dbg(FLOODING_CHANNEL, "Node %d \n" , TOS_NODE_ID);
			 if(myMsg->dest == AM_BROADCAST_ADDR){
			 
				//dbg(FLOODING_CHANNEL, " neighbor probe proto %d \n" ,myMsg->protocol);
				if(call neighborList.size() == 19){
					return msg;
				}
				else if(myMsg->protocol == 1){
					dbg(FLOODING_CHANNEL, "Node %d \n" , TOS_NODE_ID);
					call  neighborList.pushback(myMsg->src);
					dbg(FLOODING_CHANNEL, "proto1 %d \n" ,call neighborList.size());
					makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, 1, 2, ++myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
					call list.pushback(sendPackage);
					call Sender.send(sendPackage, AM_BROADCAST_ADDR);
					return msg;
				}
				/*
				else if(myMsg->protocol == 2){ 
					call  neighborList.pushback(myMsg->src);
					//call  neighborList.pushback(5);
					dbg(FLOODING_CHANNEL, "proto2 %d \n" ,call neighborList.size());
					if(myMsg->src!=19){
						makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, 2, 1, ++myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
						call list.pushback(sendPackage);
						call Sender.send(sendPackage, AM_BROADCAST_ADDR);
					}
					return msg;
				}
*/				
				return msg;
			}
			else if(TOS_NODE_ID == myMsg->dest && myMsg->protocol == 0){

				//call list.pushback(*myMsg);
				dbg(FLOODING_CHANNEL, "Packet Received at Node %d \n", TOS_NODE_ID);
				dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence %d\n", myMsg->payload, myMsg->seq);
				//sequence = 0;
				//makePack(&sendPackage, TOS_NODE_ID, myMsg->src, 20, 0, ++sequence, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				//call list.pushback(sendPackage);
				//call Sender.send(sendPackage, AM_BROADCAST_ADDR);
				//dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->src);
				return msg;
			}
			else if (myMsg->dest != myMsg->src && myMsg->dest != AM_BROADCAST_ADDR&& myMsg->protocol == 0){
				makePack(&sendPackage, myMsg->src, myMsg->dest, --myMsg->TTL, 0, myMsg->seq,myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call list.pushback(sendPackage);
				dbg(FLOODING_CHANNEL, "Packet Received at Node %d for Node %d. Resending..\n", TOS_NODE_ID, myMsg->dest);
				call Sender.send(sendPackage, AM_BROADCAST_ADDR);
				dbg(FLOODING_CHANNEL, "Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
				return msg;
			
			}
		}	
		else{
			return msg;
		}
		return msg;
	  }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
    }
	
		

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, 0, ++sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
	  call list.pushback(sendPackage);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	  dbg(FLOODING_CHANNEL, "Flooding Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, destination);
	  
   }

    event void CommandHandler.printNeighbors(){
		uint16_t i;
		uint16_t t;
		//createNeighborsList();
		for(i = TOS_NODE_ID; i < call neighborList.size(); i++){
			dbg(NEIGHBOR_CHANNEL,"Neighbors:%d\n",call neighborList.get(i));
		}/*
		dbg(NEIGHBOR_CHANNEL, "Neighbor list for Node %d\n",TOS_NODE_ID);
		i = TOS_NODE_ID;
		if(TOS_NODE_ID == 1)
			dbg(NEIGHBOR_CHANNEL, "Neighbors:%d\n",call neighborList.get(1));
		else if(TOS_NODE_ID == 19)
			dbg(NEIGHBOR_CHANNEL, "Neighbors:%d\n",call neighborList.get(18));
		else
			dbg(NEIGHBOR_CHANNEL, "Neighbors:%d, %d\n",call neighborList.get(i-1),call neighborList.get(i+1));	
		*/
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
		for(i = 0; i < call list.size(); i++){
			pack current = call list.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq )
					return TRUE;
		}
		return FALSE;
   }

   void createNeighborsList(){
		char * payload = "";
		call neighborList.pushback(TOS_NODE_ID);
		//call neighborList.pushback(5);
		dbg(NEIGHBOR_CHANNEL, "Creating neighbor list...\n");
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, 1, 50, (uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
		call list.pushback(sendPackage);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
		
   }
   
}
