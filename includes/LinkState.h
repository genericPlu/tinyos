#ifndef LINKSTATE_H
#define LINKSTATE_H
  
typedef struct linkState{
		uint16_t id;
		uint16_t size;
		uint16_t tls;
	    moteN* neighborList;
}linkState; 

#endif
