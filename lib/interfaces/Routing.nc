
interface Routing{
	command void createTable();
	command void printRoutingTable();
	command void printLinkState();
	command void removeLink(uint16_t id);
	command uint16_t nextHop(uint16_t destination);
}