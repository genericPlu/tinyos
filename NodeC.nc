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


#define MAX_NODES 20

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
	
	//ADDed
	components new TimerMilliC() as neighborTimer;
	components new ListC(moteN,MAX_NODES) as neighborList;
	components new ListC(pack, MAX_NODES) as sentList;
	components new ListC(linkState, MAX_NODES) as linkStateList;
    Node.neighborTimer -> neighborTimer;
    Node.sentList -> sentList;
    Node.neighborList -> neighborList;
	Node.linkStateList -> linkStateList;

    Node -> MainC.Boot;
	
    Node.Receive -> GeneralReceive;
	
    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components NeighborDiscoveryC;
	Node.NeighborDiscovery->NeighborDiscoveryC;
	
	components FloodingC;
	Node.Flooding->FloodingC;
	
	components RoutingC;
	Node.Routing->RoutingC;
}
