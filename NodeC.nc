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
/*Added Timer, Random, Two Lists, and Hashmap (not all used)*/
configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new TimerMilliC() as Timer0;
    components new ListC(pack,40) as sentlist;
	components new ListC(uint16_t*,19) as neighborList;
	components new ListC(moteN*,19) as neighborList2;
	components new HashmapC(uint16_t,40) as neighborMap;
	components RandomC as Random;
    

    Node -> MainC.Boot;
	
    Node.Receive -> GeneralReceive;
	
	/*Added Timer, Random, Two Lists, and Hashmap (not all used)*/
    Node.Timer0 -> Timer0;        
    Node.sentlist -> sentlist; 
	Node.neighborList ->neighborList;
	Node.neighborList2 ->neighborList2;
	Node.Random -> Random;
    Node.neighborMap ->neighborMap;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;
}
