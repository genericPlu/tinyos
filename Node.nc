/*
 * ANDES Lab - University of California, Merced
   This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *Adam Pluguez CSE160 Project2 Updated 2/21/19
 
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
   
   uses interface SimpleSend as Sender;
	
   uses interface CommandHandler;
   
   uses interface NeighborDiscovery;

   uses interface Flooding;
   
   uses interface Routing;
   
   //Added stuff
   uses interface Timer<TMilli> as neighborTimer;
   uses interface List<moteN> as neighborList;
   uses interface List<linkState> as linkStateList;
   uses interface List<pack> as sentList;
   
   
}

implementation{
   uint8_t sequence = 0;
   pack sendPackage;  
   
   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   //Added
   bool checkSentList(pack *Package);
   void updateLinkList();
   void removeNeighbor(uint16_t id);
   void sendLinkState();
   bool inList(uint16_t id);
   void removeLink(uint16_t id);
   moteN* list;
   linkState listL[20];
   linkState empty;
   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
	  call NeighborDiscovery.run();
	  //sendLinkState();
	  call neighborTimer.startPeriodic(50000);
   }
   
   event void AMControl.startDone(error_t err){
	  if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
		//call NeighborDiscovery.run();
		//call Routing.createTable();
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }
 
   event void AMControl.stopDone(error_t err){}

	event void neighborTimer.fired(){
		uint16_t i;
		//char* payload = "";
		updateLinkList();
		/*
		moteN neighbor, temp;
		uint16_t i ,listSize = call neighborList.size();
		for(i=0;i< listSize;i++){
			temp = call neighborList.get(i);
			temp.tls--;
			removeNeighbor(i);
			//call neighborList.remove(i);	
			call neighborList.pushback(temp);
		}
		for(i=0;i< listSize;i++){
			temp = call neighborList.get(i);
			if(temp.tls <= 0){
				//call neighborList.remove(i);
				removeNeighbor(i);
				listSize--;
				i--;
			}
		}
		*/
		//Send out Discovery Packet, start neighbor list creation
	   //makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, 50, (uint8_t*)payload, PACKET_MAX_PAYLOAD_SIZE);
	   //call sentList.pushback(sendPackage);
	   //call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	  // for(i=0;i< MAX_NODES;i++){
		//	listL[i].id == 0;
		//}
	   
	   sendLinkState();
		
	}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
	  //dbg(GENERAL_CHANNEL, "Packet Received\n");
	  moteN found;
	  moteN temp;
	  bool inNList = FALSE;
	  uint16_t listSize;
	  uint16_t i;
	  linkState* Payload;
	  if(len==sizeof(pack)){
        pack* myMsg=(pack*) payload;
        if(!(checkSentList(myMsg)) && myMsg->TTL != 0 && myMsg->dest == AM_BROADCAST_ADDR ){
			/*if(myMsg->protocol == PROTOCOL_PING){
				makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, --myMsg->TTL, PROTOCOL_PINGREPLY, ++myMsg->seq,(uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call sentList.pushback(sendPackage);
				call Sender.send(sendPackage, myMsg->src);
				return msg;
			}
			else if( myMsg->protocol == PROTOCOL_PINGREPLY){ 
			//dbg(NEIGHBOR_CHANNEL,"revievedNeighbor packet at %d, from %d\n" ,TOS_NODE_ID,myMsg->src);
			found.id = myMsg->src;
			found.tls = 5;
			if(!(call neighborList.isEmpty())){
				listSize = call neighborList.size();
				for(i = 0; i < listSize;i++){
					temp = call neighborList.popfront();
				
					if(temp.id == found.id){
						inNList = TRUE;
						temp.tls++;

					}
					call neighborList.pushback(temp);
				}
			} 
		}
		else */if( myMsg->protocol == PROTOCOL_LINKSTATE){
			Payload = (linkState*) myMsg->payload;
			for(i =0; i < Payload->size;i++){
				temp =  Payload->neighborList[i];
				//dbg(ROUTING_CHANNEL,"node %d neighbor: %d \n",TOS_NODE_ID, temp.id);
			}
			
			//update link linkStateList
			//if(listL[myMsg->src].tls == 0){
				//listL[myMsg->src].tls = 5;
				//dbg(ROUTING_CHANNEL,"sent fromnode %d  \n",myMsg->src);
			
		//	}
			//removeLink(Payload->id);
			//if(!inList(Payload->id)){
				
				//if(Payload->tls < 5)
					//Payload->tls = Payload->tls+1 ;
				
				//listL[myMsg->src] = *Payload;
				//call linkStateList.pushback(*Payload);
				
			//}
			listL[myMsg->src] = *Payload;
			if(listL[myMsg->src].tls == 0){
				listL[myMsg->src].tls = 5;
			
			}
			//dbg(ROUTING_CHANNEL,"tls %d  \n",Payload->tls);
			
			makePack(&sendPackage, myMsg->src, myMsg->dest, --myMsg->TTL, myMsg->protocol, myMsg->seq,(uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
			call sentList.pushback(sendPackage);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
			
			return msg;
		}
		if(!inNList){
			call neighborList.pushback(found);
			//sendLinkState();
			call Routing.createTable();
			return msg;
			
		}
			//sendLinkState();
		
		
		
		}
		return msg;
	 }	
		
		
      
	  dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      
	  return msg;
    }
	
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, PROTOCOL_PING, ++sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
	  //call Flooding.floodSend(sendPackage, destination);
	  
   }

   event void CommandHandler.printNeighbors(){
		call NeighborDiscovery.printNeighbors();
		/*
		uint16_t i;
		moteN neighbor;
		for(i = 0; i < call neighborList.size();i++){
			neighbor = call neighborList.get(i);
			dbg(NEIGHBOR_CHANNEL, "Node %d, Neighbor:%d\n",TOS_NODE_ID,neighbor.id);
		}*/
   }

   event void CommandHandler.printRouteTable(){
		//call Routing.printRouteTable();
   }

   event void CommandHandler.printLinkState(){
		//call Routing.printLinkState();
		
		uint16_t i;
		uint16_t k;
		dbg(ROUTING_CHANNEL, "linkstatelist size: %d\n",  call linkStateList.size());
		
		for(i= 0; i < 20;i++){
			linkState temp = listL[i];
		  if(temp.tls >= 0){
			dbg(ROUTING_CHANNEL, "Node: %d %d\n",temp.id, temp.tls);
			for(k=0;k < temp.size; k++){
				dbg(ROUTING_CHANNEL, "Neighbor: %d\n",temp.neighborList[k].id);
			}
		  }
		}
		/*
		for(i= 0; i < call linkStateList.size();i++){
			linkState temp = call linkStateList.get(i);
			dbg(ROUTING_CHANNEL, "Node: %d, tls:%d\n",temp.id, temp.tls);
			for(k=0;k < temp.size; k++){
				dbg(ROUTING_CHANNEL, "Neighbor: %d\n",temp.neighborList[k].id);
			}
		}
		*/
   }

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
   void updateLinkList(){
	uint16_t i;
	uint16_t size = 20;
	linkState temp;
	//Age list	
	for(i=0;i< 20;i++){
		if(listL[i].tls > 0)
			listL[i].tls--;	
	}
	for(i=0;i< call linkStateList.size();i++){
		temp =call linkStateList.popfront();
		
		if(temp.tls > 0){
			temp.tls--;
			call linkStateList.pushback(temp);	
		}
	}
	for(i=0;i< call linkStateList.size();i++){
		temp =call linkStateList.popfront();
		
		if(temp.tls >= 2){
			call linkStateList.pushback(temp);	
		
		}		
   }
	//Remove non existant neighbors
	for(i=0;i< 20;i++){
		//dbg(NEIGHBOR_CHANNEL,"node %d,tls%d\n",listL[i].id ,listL[i].tls);
		if(listL[i].tls <= 2){
			//listL[i]= listL[0];
			
		}
		
	}	
   }
   
    bool checkSentList(pack *Package){
		uint16_t i;
		for(i = 0; i < call sentList.size(); i++){
			pack current = call sentList.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq )
					return TRUE;
		}
		return FALSE;
    }
	
	void removeNeighbor(uint16_t id){
	   uint16_t i;
	   for(i = 0; i < call neighborList.size(); i++){
			moteN current = call neighborList.popfront();
			if(current.id == id){
				return;
			}
			else{
				call neighborList.pushback(current);
			}
		}
		return;
   }
   void removeLink(uint16_t id){
	   uint16_t i;
	   for(i = 0; i < call linkStateList.size(); i++){
			linkState current = call linkStateList.popfront();
			if(current.id == id){
				return;
			}
			else{
				call linkStateList.pushback(current);
			}
		}
		return;
   }
   
   void sendLinkState(){
		linkState Payload;
		linkState* payload = &Payload;
		uint16_t listSize = call NeighborDiscovery.neighborListSize();
		uint16_t i;
		list[listSize];
/*	
	for(i =0; i < listSize;i++){
			list[i] =  call neighborList.get(i);
			dbg(ROUTING_CHANNEL,"node %d neighbors: %d \n",TOS_NODE_ID, list[i].id);
		}
*/	
	//dbg(ROUTING_CHANNEL,"LINKSTATE PACKET BROADCAST %d\n", TOS_NODE_ID);
		payload->id = TOS_NODE_ID;
		payload->neighborList = call NeighborDiscovery.neighborList();
		payload->size = listSize;
		payload->tls = 5;
/*
		for(i =0; i < listSize;i++){
			list[i] =  payload->neighborList[i];
			dbg(ROUTING_CHANNEL,"node %d neighbors: %d \n",TOS_NODE_ID, list[i].id);
		}
*/	
	makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 20, PROTOCOL_LINKSTATE, sequence++,(uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
		call sentList.pushback(sendPackage);
		listL[TOS_NODE_ID] = Payload;
		/*
		//if(!inList(Payload.id)){
			//call linkStateList.pushback(Payload);
			
			listL[TOS_NODE_ID] = Payload;
			
			call linkStateList.pushback(Payload);
		
		//}	
		//else{
			//removeLink(Payload.id);
			//call linkStateList.pushback(Payload);
		//}
		*/
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 20, PROTOCOL_LINKSTATE, sequence++,(uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
		call sentList.pushback(sendPackage);
		
   }
    bool inList(uint16_t id){
	uint16_t i;
	for(i = 0; i < call linkStateList.size(); i++){
		linkState current = call linkStateList.get(i);
		if(current.id == id)
				return TRUE;
		
	}
		return FALSE;
   }
   
}
