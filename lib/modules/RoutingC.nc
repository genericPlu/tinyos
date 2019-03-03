/**
 * ANDES Lab - University of California, Merced
   This class provides Routing via neighbor discovery and a routing table.
 *
 * @author Adam Pluguez CSE160
 * @date   2/21/19
 */


#define AM_ROUTE 62

configuration RoutingC{
	provides interface Routing;
}
implementation {
	components RoutingP;
    components new AMReceiverC(AM_ROUTE);
	components new SimpleSendC(AM_ROUTE);
	components new TimerMilliC() as RouteTimer;
	components new ListC(linkState,MAX_NODES) as linkStateList;
	components new ListC(moteN,MAX_NODES) as neighborList;
	components new ListC(routeEntry,MAX_NODES) as routingTable;
	components new ListC(pack,MAX_NODES) as sentList;
	components RandomC as Random;

    
	RoutingP.Random -> Random;
	RoutingP.RouteReceive -> AMReceiverC;
	RoutingP.RouteSender -> SimpleSendC;
	RoutingP.RouteTimer -> RouteTimer;
	RoutingP.routingTable -> routingTable;
	RoutingP.linkStateList -> linkStateList;
	RoutingP.neighborList -> neighborList;
	RoutingP.sentList-> sentList;

	
	
	components NeighborDiscoveryC;
	RoutingP.NeighborDiscovery->NeighborDiscoveryC;
	
	Routing = RoutingP.Routing;
	
}
