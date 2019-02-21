

interface NeighborDiscovery{
	command void run();
	command void printNeighbors();
	command moteN* neighborList();
	command uint16_t neighborListSize();
}