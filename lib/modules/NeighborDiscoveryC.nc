/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * Adam Pluguez CSE160 Project1 Updated 2/12/19
 */

//#include "includes/CommandMsg.h"
//#include "includes/packet.h"
#define MAX_NODES 255

configuration NeighborDiscoveryC{
	provides interface NeighborDiscovery;
}
implementation {
	components NeighborDiscoveryP;
    components new AMReceiverC(AM_PACK);
	components new TimerMilliC() as DiscoveryTimer;
	components new ListC(moteN,MAX_NODES) as neighborList;
	components new SimpleSendC(AM_PACK);
	components RandomC as Random;
    
	NeighborDiscoveryP.Random -> Random;
	NeighborDiscoveryP.DiscoveryReceive -> AMReceiverC;
    NeighborDiscoveryP.neighborList ->neighborList;
	NeighborDiscoveryP.DiscoverySender -> SimpleSendC;
	NeighborDiscoveryP.DiscoveryTimer -> DiscoveryTimer;
	
	NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;
	
}
