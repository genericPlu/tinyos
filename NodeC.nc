/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *-
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new TimerMilliC() as Timer0;
    components new ListC(pack,40) as list;
	components new ListC(uint16_t*,40) as neighborList;
	components new HashmapC(uint16_t,40) as neighborMap;
	components RandomC as Random;
    

    Node -> MainC.Boot;
	
    Node.Receive -> GeneralReceive;
	
	
    Node.Timer0 -> Timer0;        
    Node.list -> list; 
	Node.neighborList ->neighborList;
	Node.Random -> Random;
    Node.neighborMap ->neighborMap;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;
}
