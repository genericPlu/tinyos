/**
 * ANDES Lab - University of California, Merced
   This class provides NeighborDiscovery.
 *
 * @author Adam Pluguez CSE160 Project1 Updated 2/12/19
 * @date   2/21/19
 */


#define MAX_NODES 20
#define AM_DISC 62
configuration NeighborDiscoveryC{
	provides interface NeighborDiscovery;
}
implementation {
	components NeighborDiscoveryP;
    components new AMReceiverC(AM_DISC);
	components new TimerMilliC() as DiscoveryTimer;
	components new ListC(moteN,MAX_NODES) as neighborList;
	components new ListC(pack, MAX_NODES) as sentList;
	components new SimpleSendC(AM_DISC);
	components RandomC as Random;
    
	NeighborDiscoveryP.Random -> Random;
	NeighborDiscoveryP.DiscoveryReceive -> AMReceiverC;
    NeighborDiscoveryP.neighborList ->neighborList;
	NeighborDiscoveryP.sentList ->sentList;
	NeighborDiscoveryP.DiscoverySender -> SimpleSendC;
	NeighborDiscoveryP.DiscoveryTimer -> DiscoveryTimer;
	
	components RoutingC;
	NeighborDiscoveryP.Routing->RoutingC;
	
	NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;
	
}
