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

typedef struct moteN{
		uint16_t id;
		uint16_t tls;
   }moteN;
   
typedef struct LinkState{
		
}LinkState;
   
module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;
   
   uses interface Random as Random;
   
   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   
   uses interface Timer<TMilli> as Timer0;
   
   uses interface Hashmap<moteN> as neighborMap;
   
   uses interface List<pack> as sentlist;
   
   uses interface List<uint16_t*> as neighborList;
   uses interface List<moteN> as neighborList2;
   
}

implementation{
   uint8_t sequence = 0;
   
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
  
  //Added prototypes
   bool checkSentList(pack *Package);
   void createNeighborsList();
   
   //Added Timer0
   event void Boot.booted(){
      call AMControl.start();
	  createNeighborsList();
	  call Timer0.startPeriodic(50000);
	  //call Timer0.startPeriodicAt(5000,300000);
      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
   //Added Timer0 firing event to create neighbor list
   event void Timer0.fired(){ 
       createNeighborsList();
	   //dbg(GENERAL_CHANNEL, "TIMER FIRED\n");


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
	
   //Modifed for flooding and neighbor discovery
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      uint16_t i;
	  moteN found;
	  moteN temp;
	  bool inlist = FALSE;
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
				makePack(&sendPackage, myMsg->src, myMsg->dest, --myMsg->TTL, 0, myMsg->seq,(uint8_t*)myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call sentlist.pushback(sendPackage);
				dbg(FLOODING_CHANNEL, "Flooding Packet Received at Node %d for Node %d. Resending..\n", TOS_NODE_ID, myMsg->dest);
				call Sender.send(sendPackage, AM_BROADCAST_ADDR);
				dbg(FLOODING_CHANNEL, "Flooding Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
				return msg;
			
			}
			//Neighbor Discovery
			else if(myMsg->dest == AM_BROADCAST_ADDR){
				//dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery Packet Recieved at Node %d  \n" , TOS_NODE_ID);
				if(myMsg->protocol == 1){
					makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, --myMsg->TTL, 2, ++myMsg->seq,(uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
					call sentlist.pushback(sendPackage);
					call Sender.send(sendPackage, myMsg->src);
					//dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery sending neighbor response to Node %d  \n" , myMsg->src);
					
					return msg;
				}

				else if(myMsg->protocol == 2){ 
					//dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery Node %d  \n" , TOS_NODE_ID);
					found.id = myMsg->src;
					found.tls = 5;
					for(i = 0; i < call neighborList2.size();i++){
						temp = call neighborList2.popfront();
						if(temp.id == found.id){
							inlist = TRUE;
							temp.tls++;
						}
						call neighborList2.pushback(temp);
					}
					if(inlist == FALSE){
						call neighborList2.pushfront(found);
					}
					inlist = FALSE;
					return msg;
				}
			
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
      //dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, 0, ++sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
	  call sentlist.pushback(sendPackage);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);

	  
   }

    event void CommandHandler.printNeighbors(){
		uint16_t i;
		moteN neighbor1;
		for(i = 0; i < call neighborList2.size();i++){
			neighbor1 = call neighborList2.get(i);
			dbg(NEIGHBOR_CHANNEL, "Node %d, Neighbor:%d tls: %d\n",TOS_NODE_ID,neighbor1.id, neighbor1.tls);
		}
		
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

   void createNeighborsList(){
		uint16_t i;
		moteN temp;
		char* payload = "hi";
		if(!call neighborList2.isEmpty()){
			for(i=0;i< call neighborList2.size();i++){
				temp = call neighborList2.popfront();
				if(temp.tls != 0){
					temp.tls--;
					call neighborList2.pushback(temp);
				}
				
			}
		}
		
			makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, 1, 50, (uint8_t*)payload, PACKET_MAX_PAYLOAD_SIZE);
			call sentlist.pushback(sendPackage);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
			
		
   }
   
}
