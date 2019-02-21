/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * Adam Pluguez CSE160 Project1 Updated 2/12/19
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"


#define MAX_NODES 255

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new ListC(pack,MAX_NODES) as sentlist;
	
    

    Node -> MainC.Boot;
	
    Node.Receive -> GeneralReceive;
	      
    Node.sentlist -> sentlist; 
	
    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components NeighborDiscoveryC;
	Node.NeighborDiscovery->NeighborDiscoveryC;
}
