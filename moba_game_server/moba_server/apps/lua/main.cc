#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <iostream>
#include <string>
using namespace std;

#include "../../netbus/netbus.h"
#include "../../lua_wrapper/lua_wrapper.h"

int main(int argc, char** argv) {
	netbus::instance()->init();
	lua_wrapper::init();

	if (argc != 3) { // ����
		std::string search_path = "../../apps/lua/scripts/";
		lua_wrapper::add_search_path(search_path);
		//std::string lua_file = search_path + "auth_server/main.lua";
		std::string lua_file = search_path + "gateway/main.lua";
		//std::string lua_file = search_path + "logic_server/main.lua";
		lua_wrapper::do_file(lua_file);
		// end 
	}
	else {
		std::string search_path = argv[1];
		if (*(search_path.end() - 1) != '/') {
			search_path += "/";
		}
		lua_wrapper::add_search_path(search_path);

		std::string lua_file = search_path + argv[2];
		lua_wrapper::do_file(lua_file);
	}
	netbus::instance()->run();
	lua_wrapper::exit();

	system("pause");
	return 0;
}