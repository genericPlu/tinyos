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

   uses interface CommandHandler;
   
   uses interface Timer<TMilli> as Timer0;
   
   uses interface Hashmap<moteN> as neighborMap;
   
   uses interface List<pack> as sentlist;
   
   uses interface List<moteN> as neighborList;
   uses interface List<moteN> as neighborList2;
   
}

implementation{
   uint8_t sequence = 0;
   pack sendPackage;  
   

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   bool checkSentList(pack *Package);
   void createNeighborsList();
   
  
   event void Boot.booted(){
	  uint32_t randStart;
	  uint32_t randFire;
      call AMControl.start();
	  randStart = call Random.rand32() % 25;
	  randFire = call Random.rand32() % 1000;
	  call Timer0.startPeriodicAt(randStart,45000-randFire);
      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
  
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
			//Neighbor Discovery
			else if(myMsg->dest == AM_BROADCAST_ADDR){
				if(myMsg->protocol == PROTOCOL_PING){
					makePack(&sendPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, --myMsg->TTL, PROTOCOL_PINGREPLY, ++myMsg->seq,(uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
					call sentlist.pushback(sendPackage);
					call Sender.send(sendPackage, myMsg->src);
				}
				else if(myMsg->protocol == PROTOCOL_PINGREPLY){ 
					found.id = myMsg->src;
					found.tls = 5;
					for(i = 0; i < call neighborList.size();i++){
						temp = call neighborList.popfront();
						if(temp.id == found.id){
							inlist = TRUE;
							temp.tls++;
						}
						call neighborList.pushback(temp);
					}
					if(inlist == FALSE){
						call neighborList.pushfront(found);
					}
					inlist = FALSE;	
				}
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
		uint16_t i;
		moteN neighbor1;
		for(i = 0; i < call neighborList.size();i++){
			neighbor1 = call neighborList.get(i);
			dbg(NEIGHBOR_CHANNEL, "Node %d, Neighbor:%d\n",TOS_NODE_ID,neighbor1.id);
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
		char* payload = "";
		
		//Check if list is empty and reduce time last seen(tls)
		if(!call neighborList.isEmpty()){
			for(i=0;i< call neighborList.size();i++){
				temp = call neighborList.popfront();
				temp.tls--;
				if(temp.tls != 0){	
					call neighborList.pushback(temp);
				}
				
			}
		}
		//Send out Discovery Packet
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, 50, (uint8_t*)payload, PACKET_MAX_PAYLOAD_SIZE);
		call sentlist.pushback(sendPackage);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }
   
}
