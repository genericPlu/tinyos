#ifndef MOTEN_H
#define MOTEN_H

typedef struct moteN{
		uint16_t id;
		uint16_t tls;
}moteN; 

typedef struct linkState{
		uint16_t id;
		uint16_t size;
		uint16_t tls;
	    moteN* neighborList;
}linkState; 

typedef struct routeEntry{
		uint16_t id;
		uint16_t cost;
	    uint16_t nextHop;
}routeEntry; 


#endif
