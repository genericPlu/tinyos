/**
 * ANDES Lab - University of California, Merced
   This class provides Routing via linkstate routing.
 *
 * @author Adam Pluguez CSE160
 * @date   2/21/19
 */

module RoutingP{
   
   uses interface Receive as RouteReceive;
   uses interface Random as Random;
   uses interface Timer<TMilli> as RouteTimer;
   uses interface SimpleSend as RouteSender;
   uses interface List<linkState> as linkStateList;
   uses interface List<moteN> as neighborList;
   uses interface List<routeEntry> as routingTable;
   uses interface List<pack> as sentList;
 
   uses interface NeighborDiscovery;
   provides interface Routing;

}

implementation{
   uint16_t sequence = 0;
   uint16_t linkStateListSize;
   uint16_t sent=0;
   uint16_t resent=0;
   uint16_t received=0;
   uint16_t* receivedA;
   uint16_t receivedSize = 0;
   moteN lastNeighbors[20];
   pack routePackage; 
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);uint16_t size;
   bool checkSentList(pack *Package);
   bool inList(linkState state);
   bool inListOlder(linkState state);
   void removeState(uint16_t id);
   void sendLinkPacket();
   void updateLinkState();
   void getLinkState(uint16_t node);
   void emptyList();
   
   uint16_t compareNeighbors(moteN* list1, moteN* list2, uint16_t size1, uint16_t size2);
   
   
   event void RouteTimer.fired(){ 
		//updateLinkState();
		if((call linkStateList.isEmpty()))
		sendLinkPacket();
   }
   
   event message_t* RouteReceive.receive(message_t* msg, void* payload, uint8_t len){	
		uint16_t i;
		uint16_t listSize;
		linkState temp;
		bool inLlist = FALSE;
		pack* myMsg=(pack*) payload;
		linkState* Payload = (linkState*) myMsg->payload;
		if(!(checkSentList(myMsg)) && myMsg->protocol == PROTOCOL_LINKSTATE&& myMsg->TTL != 0 ){
			if(myMsg->dest == AM_BROADCAST_ADDR){
				removeState(Payload->id);
				call linkStateList.pushback(*Payload);
				
					
				
				sent++;
				makePack(&routePackage, myMsg->src, myMsg->dest, --myMsg->TTL, myMsg->protocol, myMsg->seq,(uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call sentList.pushback(routePackage);
				call RouteSender.send(routePackage, AM_BROADCAST_ADDR);
				return msg;
			}
			
		}
		return msg;
	}
	
   command void Routing.createTable(){
		//updateLinkState();
		//emptyList();
		//sendLinkPacket();
		//call RouteTimer.startPeriodic(2000);
		call RouteTimer.startOneShot(2500);
   }
   
   
   
   command void Routing.printRoutingTable(){
		//emptyList();
		//sendLinkPacket();
		//call RouteTimer.startOneShot(2500);
		//call RouteTimer.startPeriodic(10000);
	}
   
   command void Routing.removeLink(uint16_t id){
		removeState(id);
	
   }
   
   command void Routing.printLinkState(){
		uint16_t i;
		uint16_t k;
		dbg(ROUTING_CHANNEL, "linkstatelist size: %d \n",  call linkStateList.size());
		for(i= 0; i < call linkStateList.size();i++){
			linkState temp = call linkStateList.get(i);
			dbg(ROUTING_CHANNEL, "Node: %d \n",temp.id);
			for(k=0;k < temp.size; k++){
				dbg(ROUTING_CHANNEL, "Neighbor: %d\n",temp.neighborList[k].id);
			}
		}
		dbg(ROUTING_CHANNEL,"sent: %d received %d\n", sent, received);
   
   }
   
   command uint16_t Routing.nextHop(uint16_t destination){
   
   }
   
   void updateLinkState(){
	linkState temp;
	uint16_t i;
	
	//Age list	
	for(i=0;i< call linkStateList.size();i++){
		temp = call linkStateList.popfront();
		temp.tls--;
		call linkStateList.pushback(temp);	
	}
	
	//Remove old links 
	for(i=0;i< call linkStateList.size();i++){

		temp = call linkStateList.popfront();
		if(temp.tls > 1)
			call linkStateList.pushback(temp);	
	}
	
	
   }
   
   void sendLinkPacket(){
		linkState Payload;
		linkState* payload = &Payload;
		payload->id = TOS_NODE_ID;
		payload->neighborList = call NeighborDiscovery.neighborList();
		payload->size = call NeighborDiscovery.neighborListSize();
		payload->tls = 4;
		makePack(&routePackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 20, PROTOCOL_LINKSTATE, sequence++,(uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
		call sentList.pushback(routePackage);
		
		removeState(Payload.id);
		call linkStateList.pushback(Payload);
		
		call RouteSender.send(routePackage, AM_BROADCAST_ADDR);
		
   }
   
   bool checkSentList(pack *Package){
		uint16_t i;
		for(i = 0; i < call sentList.size(); i++){
			pack current = call sentList.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq)
					return TRUE;
		}
		return FALSE;
    }
	
   bool inList(linkState state){
	uint16_t i;
	for(i = 0; i < call linkStateList.size(); i++){
		linkState current = call linkStateList.get(i);
		if(current.id == state.id)
				return TRUE;
		
	}
		return FALSE;
   }
   
   void removeState(uint16_t id){
	   uint16_t i;
	   //dbg(ROUTING_CHANNEL, "removingdel %d\n",id );
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
   
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   void emptyList(){
		uint16_t i;
		for(i =0; i < call linkStateList.size(); i++){
			call linkStateList.popfront();
		}
   }
}
