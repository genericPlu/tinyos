/**
 * ANDES Lab - University of California, Merced
   This class provides Routing via neighbor discovery and a routing table.
 *
 * @author Adam Pluguez CSE160 Project1 Updated 2/12/19
 * @date   2/21/19
 */


#define MAX_NODES 255
#define AM_ROUTE 75

configuration RoutingC{
	provides interface Routing;
}
implementation {
	components RoutingP;
    components new AMReceiverC(AM_ROUTE);
	components new SimpleSendC(AM_ROUTE);
	components new TimerMilliC() as RouteTimer;
	components RandomC as Random;
    
	RoutingP.Random -> Random;
	RoutingP.RouteReceive -> AMReceiverC;
	RoutingP.RouteSender -> SimpleSendC;
	RoutingP.RouteTimer -> RouteTimer;
	
	Routing = RoutingP.Routing;
	
}
