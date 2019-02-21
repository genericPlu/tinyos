/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * Adam Pluguez CSE160 Project1 Updated 2/12/19
 */
#define MAX_NODES 255

configuration FloodingC{
	provides interface Flooding;
}

implementation {
	components FloodingP;
    components new AMReceiverC(AM_PACK) as FloodReceive;
    components new ListC(pack,MAX_NODES) as sentList;

    FloodingP.FloodReceive -> FloodReceive;	        
    FloodingP.sentList -> sentList; 

    components new SimpleSendC(AM_PACK);
    FloodingP.FloodSender -> SimpleSendC;

	Flooding = FloodingP.Flooding;
}
