/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * Adam Pluguez CSE160 Project1 Updated 2/12/19
 */

#include "includes/CommandMsg.h"
#include "includes/packet.h"
configuration NeighborDiscoveryC{
}
implementation {

    components new AMReceiverC(AM_PACK) as DiscoveryReceive;

	components new ListC(moteN,MAX_NODES) as neighborList;
	
    NeighborDiscovery.DiscoveryReceive -> DiscoveryReceive;
 
	NeighborDiscovery.neighborList ->neighborList;
	
    components ActiveMessageC;
    NeighborDiscovery.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    NeighborDiscovery.DiscoverySender -> SimpleSendC;

    components CommandHandlerC;
    NeighborDiscovery.CommandHandler -> CommandHandlerC;
}
