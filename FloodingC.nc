/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * Adam Pluguez CSE160 Project1 Updated 2/12/19
 */

#include "includes/packet.h

configuration FloodingC{
}
implementation {

    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new ListC(pack,40) as list;

    Flooding.Receive -> GeneralReceive;	        
    Flooding.list -> list; 

    components new SimpleSendC(AM_PACK);
    Flooding.Sender -> SimpleSendC;

}
