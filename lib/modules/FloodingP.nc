/**
 * ANDES Lab - University of California, Merced
   This class provides Flooding.
 *
 * @author Adam Pluguez CSE160 Project1 Updated 2/12/19
 * @date   2/21/19
 */


module FloodingP{
   
   uses interface Receive as FloodReceive;
   
   uses interface SimpleSend as FloodSender;
   
   uses interface List<pack> as sentList;
    
   provides interface Flooding;
}

implementation{
   uint8_t sequence = 1;

   pack floodPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
  
  //Added prototypes
   bool checkSentList(pack *Package);
   
   command void Flooding.floodSend(pack msg, uint16_t destination){
		msg.src = TOS_NODE_ID;
		msg.dest = destination;
		msg.TTL = 20;
		msg.seq = sequence++;
		call sentList.pushback(msg);
		call FloodSender.send(msg, AM_BROADCAST_ADDR);
   
   }
   
   event message_t* FloodReceive.receive(message_t* msg, void* payload, uint8_t len){  
      if(len==sizeof(pack)){
        pack* myMsg=(pack*) payload;
        if(myMsg->TTL != 0 && !checkSentList(myMsg)){ 
			if(TOS_NODE_ID == myMsg->dest && myMsg->protocol == 0){
				dbg(FLOODING_CHANNEL, "Packet Received at destination Node %d \n", TOS_NODE_ID);
				dbg(FLOODING_CHANNEL, "Package Payload: %s Sequence %d\n", myMsg->payload, myMsg->seq);
				
			}
			else if (myMsg->dest != myMsg->src && myMsg->dest != AM_BROADCAST_ADDR&& myMsg->protocol == 0){
				makePack(&floodPackage, myMsg->src, myMsg->dest, --myMsg->TTL, 0, myMsg->seq,(uint8_t*)myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
				call sentList.pushback(floodPackage);
				dbg(FLOODING_CHANNEL, "Flooding Packet Received at Node %d for Node %d. Resending..\n", TOS_NODE_ID, myMsg->dest);
				call FloodSender.send(floodPackage, AM_BROADCAST_ADDR);
				dbg(FLOODING_CHANNEL, "Flooding Packet sent from Node %d to Node %d \n" , TOS_NODE_ID, myMsg->dest);
				
			
			}
			
			
		}	
	  }
	  return msg;
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
		for(i = 0; i < call sentList.size(); i++){
			pack current = call sentList.get(i);
			if(current.src == Package->src)
				if(current.seq == Package->seq )
					return TRUE;
		}
		return FALSE;
    }

   
}
