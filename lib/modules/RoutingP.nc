/**
 * ANDES Lab - University of California, Merced
   This class provides Routing via neighbor discovery and a routing table.
 *
 * @author Adam Pluguez CSE160 Project1 Updated 2/12/19
 * @date   2/21/19
 */



module RoutingP{
   
   uses interface Receive as RouteReceive;
   uses interface Random as Random;
   uses interface Timer<TMilli> as RouteTimer;
   uses interface SimpleSend as RouteSender;
   
   provides interface Routing;

}

implementation{
   pack routePackage; 
   
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   
   event void RouteTimer.fired(){ 
       
   }
   
   event message_t* RouteReceive.receive(message_t* msg, void* payload, uint8_t len){
	
   }
   
   command void Routing.createTable(){
		
   }
   
   command void Routing.printRoutingTable(){
   
   }
   
   command void Routing.printLinkState(){
   
   }
   
   command uint16_t Routing.nextHop(uint16_t destination){
   
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
