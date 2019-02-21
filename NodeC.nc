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
//#include "includes/moteN.h"

#define MAX_NODES 255

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new TimerMilliC() as Timer0;
    components new ListC(pack,MAX_NODES) as sentlist;
	components new ListC(moteN,MAX_NODES) as neighborList;
	components new ListC(moteN,MAX_NODES) as neighborList2;
	components new HashmapC(moteN,MAX_NODES) as neighborMap;
	components RandomC as Random;
    

    Node -> MainC.Boot;
	
    Node.Receive -> GeneralReceive;
	
	
    Node.Timer0 -> Timer0;        
    Node.sentlist -> sentlist; 
	Node.neighborList ->neighborList;
	Node.neighborList ->neighborList2;
	Node.Random -> Random;
    Node.neighborMap ->neighborMap;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;
}
