/**
 * ANDES Lab - University of California, Merced
   This class provides Flooding.
 *
 * @author Adam Pluguez CSE160 Project1 Updated 2/12/19
 * @date   2/21/19
 */



#define MAX_NODES 255
#define AM_FLOOD 80
configuration FloodingC{
	provides interface Flooding;
}

implementation {
	components FloodingP;
    components new AMReceiverC(AM_FLOOD);
    components new ListC(pack,MAX_NODES) as sentList;

    FloodingP.FloodReceive -> AMReceiverC;	        
    FloodingP.sentList -> sentList; 

    components new SimpleSendC(AM_FLOOD);
    FloodingP.FloodSender -> SimpleSendC;

	Flooding = FloodingP.Flooding;
}
