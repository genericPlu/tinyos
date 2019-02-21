#ifndef __MOTEN_H__
#define MOTEN

typedef struct moteN{
		uint16_t id;
		uint16_t tls;
}moteN; 

  
typedef struct LinkState{
		uint16_t node;
	    moteN* neighborList;
}LinkState; 

#endif
