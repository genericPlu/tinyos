/*
 * ANDES Lab - University of California, Merced
   This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *Adam Pluguez CSE160 Project1 Updated 2/12/19
 
 */
/*
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
*/


module NeighborDiscoveryP{
   
   uses interface Receive as DiscoveryReceive;
   uses interface Random as Random;
   uses interface Timer<TMilli> as DiscoveryTimer;
   uses interface SimpleSend as DiscoverySender;
   uses interface List<moteN> as neighborList;
   
   provides interface NeighborDiscovery;

}

implementation{
   pack discoveryPackage; 
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void createNeighborsList();
   
   command void NeighborDiscovery.run(){
		uint32_t randStart;
		uint32_t randFire;
		randStart = call Random.rand32() % 25;
		randFire = call Random.rand32() % 1000;
		call DiscoveryTimer.startPeriodicAt(randStart,45000-randFire);
   }
   
   command void NeighborDiscovery.printNeighbors(){
		uint16_t i;
		moteN neighbor1;
		for(i = 0; i < call neighborList.size();i++){
			neighbor1 = call neighborList.get(i);
			dbg(NEIGHBOR_CHANNEL, "Node %d, Neighbor:%d\n",TOS_NODE_ID,neighbor1.id);
		}
   }
   
   command uint16_t NeighborDiscovery.neighborListSize(){
		uint16_t size;
		size = call neighborList.size();
		return size;
   }
   
   command moteN* NeighborDiscovery.neighborList(){
		uint16_t i;
		moteN returnList[call neighborList.size()];
		for(i=0;i<call neighborList.size();i++){
			returnList[i] = call neighborList.get(i);
		}
		
		return returnList;
   }
   event void DiscoveryTimer.fired(){ 
       createNeighborsList();
   }
   
   event message_t* DiscoveryReceive.receive(message_t* msg, void* payload, uint8_t len){
      uint16_t i;
	  moteN found;
	  moteN temp;
	  bool inlist = FALSE;
	  if(len==sizeof(pack)){
        pack* myMsg=(pack*) payload;
		//Neighbor Discovery
		if(myMsg->TTL != 0 && myMsg->dest == AM_BROADCAST_ADDR){
			if(myMsg->protocol == PROTOCOL_PING){
				makePack(&discoveryPackage, TOS_NODE_ID,AM_BROADCAST_ADDR, --myMsg->TTL, PROTOCOL_PINGREPLY, ++myMsg->seq,(uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				//call sentlist.pushback(discoveryPackage);
				call DiscoverySender.send(discoveryPackage, myMsg->src);
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
   
   void createNeighborsList(){
		uint16_t i;
		moteN temp;
		char* payload = "";
		
		//Check if neighbor list is empty and reduce time last seen(tls)
		if(!call neighborList.isEmpty()){
			for(i=0;i< call neighborList.size();i++){
				temp = call neighborList.popfront();
				temp.tls--;
				if(temp.tls != 0){	
					call neighborList.pushback(temp);
				}
				
			}
		}
		//Send out Discovery Packet, start neighbor list creation/update
		makePack(&discoveryPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, 50, (uint8_t*)payload, PACKET_MAX_PAYLOAD_SIZE);
		call DiscoverySender.send(discoveryPackage, AM_BROADCAST_ADDR);
   }
   
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   
}
