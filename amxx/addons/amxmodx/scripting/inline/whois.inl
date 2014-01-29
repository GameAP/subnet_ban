/*	AMX Mod X script.

	Whois query functions by Lev.

	Version 1.1
*/

#if defined whois_inl
  #endinput
#endif
#define whois_inl

#include <amxmodx>
#include <amxmisc>
#include <sockets>

#include "inline/common_functions.inl"
#include "inline/ip_functions.inl"

// System constants
//#define _DEBUGWHOIS		// Enable debug output at server console.

// Whois provider
#define ARIN	0
#define RIPE	1
#define APNIC	2
#define LACNIC	3
#define AFRNIC	4
#define RADB	5

new const _whoisHosts[][] = {
	"whois.arin.net",
	"whois.ripe.net",
	"whois.apnic.net",
	"whois.lacnic.net",
	"whois.afrinic.net",
	"whois.radb.net"
};

new const _whoisQueries[][] = {
	"n %s",
	"-r -T inetnum %s",
	"-T inetnum %s",
	"%s",
	"-r -T inetnum %s",
	"-K -T route -r %s"
};

new const _whoisQueriesFull[][] = {
	"%s",
	"%s",
	"%s",
	"%s",
	"%s",
	"%s"
};

// MAX constants
#define MAX_PLAYERS			32
#define HANDLER_LENGTH		31
#define NETNAME_LENGTH		32
#define DESCR_LENGTH		150
#define COUNTRYCODE_LENGTH	2

// Constants
#define TASK_WHOIS_ANSWER_BASE		62100
#define TASK_WAIT_ANSWER_BASE		62200
#define TASK_WHOIS_MONITOR_BASE		62300
#define TASK_WHOIS_CALLBACK_BASE	62400
#define WHOIS_ANSWER_INTERVAL		2.0
#define WHOIS_ANSWER_STEP_INTERVAL	0.2
#define WHOIS_WAIT_WHOLE_ANSWER		0.6

// Whois data
new bool:_whoisInProgress[MAX_PLAYERS + 1];
new _whoisQueriesCount[MAX_PLAYERS + 1];
new _whoisStartIps[MAX_PLAYERS + 1][IP_LENGTH + 1];
new _whoisEndIps[MAX_PLAYERS + 1][IP_LENGTH + 1];
new _whoisNetnames[MAX_PLAYERS + 1][NETNAME_LENGTH + 1];
new _whoisDescriptions[MAX_PLAYERS + 1][DESCR_LENGTH + 1];
new _whoisCountryCodes[MAX_PLAYERS + 1][COUNTRYCODE_LENGTH + 1];
new _whoisError[MAX_PLAYERS + 1];



//****************************************
//*                                      *
//*  Whois query                         *
//*                                      *
//****************************************

/// Starts whois query for given IP.
/// If whois already started for given id then function will return false.
/// After whois queries finished handler will be called.
/// Handler should have format "public WhoisComplete(id)" and to get id it should perfom "id -= TASK_WHOIS_CALLBACK_BASE".
/// Returns: false on failure, true on success start.
public bool:Whois(id, const ipStr[], const handler[], bool:outputWhoisAnswer)
{
	if (id < 0 || id > MAX_PLAYERS)
		return false;

	// Check for whois in progress for given id
	if (_whoisInProgress[id])
	{
		console_print(id, "WHOIS_IN_PROGRESS");
		return false;
	}
	_whoisInProgress[id] = true;

	_whoisQueriesCount[0] = 0;
	_whoisStartIps[id][0] = 0;
	_whoisEndIps[id][0] = 0;
	_whoisNetnames[id][0] = 0;
	_whoisDescriptions[id][0] = 0;
	_whoisCountryCodes[id][0] = 0;
	_whoisError[id] = 0;

	// Arin
	WhoisQuery(id, ARIN, ipStr, outputWhoisAnswer);
	// RADb
	WhoisQuery(id, RADB, ipStr, outputWhoisAnswer);

	// Start monitoring for whois process to complete
	new data[HANDLER_LENGTH + 2];
	data[0] = sizeof(data);
	copy(data[1], HANDLER_LENGTH, handler);
	set_task(WHOIS_ANSWER_STEP_INTERVAL, "WhoisFinishMonitor", TASK_WHOIS_MONITOR_BASE + id, data, data[0]);

	return true;
}

/// Repeatedly check for all whois queries to finish
public WhoisFinishMonitor(const data[], id)
{
	id -= TASK_WHOIS_MONITOR_BASE;

    // Return if no whois is in progress for given id
	if (!_whoisInProgress[id])
		return;

	// Check if all queries are processed
	if (_whoisQueriesCount[id] == 0)
	{
		// If handler specified call it
		if (data[1] != 0)
			set_task(0.1, data[1], TASK_WHOIS_CALLBACK_BASE + id);
		// End monitoring
		_whoisInProgress[id] = false;
		return;
	}

    // Repeat monitor
	set_task(WHOIS_ANSWER_STEP_INTERVAL, "WhoisFinishMonitor", TASK_WHOIS_MONITOR_BASE + id, data, data[0]);
}

WhoisQuery(id, whoisProvider, const ipStr[], outputWhoisAnswer)
{
	if (id < 0 || id > MAX_PLAYERS)
		return;

	_whoisQueriesCount[id]++;

	// Preparing query
	new query[128];
	if (!outputWhoisAnswer) format(query, charsmax(query), _whoisQueries[whoisProvider], ipStr);
	else format(query, charsmax(query), _whoisQueriesFull[whoisProvider], ipStr);
	
#if defined _DEBUGWHOIS
	server_print("WhoisQuery: host: %s, query: %s", _whoisHosts[whoisProvider], query);
#endif

	// Open socket
	new error;
	new socket = socket_open(_whoisHosts[whoisProvider], 43, SOCKET_TCP, error);
	if (socket < 1 || error != 0)
	{
		server_print("Socket Error: %d", error);
		_whoisError[id] = error;
		_whoisQueriesCount[id]--;
		return;
	}
#if defined _DEBUGWHOIS
	server_print("WhoisQuery: socket opened: %u", socket);
#endif
    // Send query
	new queryLength = strlen(query);
	socket_send(socket, query, queryLength);
	socket_send(socket, "\r\n", 2);
#if defined _DEBUGWHOIS
	server_print("WhoisQuery: query sent.");
#endif
    // Start waiting for an answer
	new data[IP_LENGTH + 5];
	data[0] = sizeof(data);
	data[1] = socket;
	data[2] = whoisProvider;
	data[3] = outputWhoisAnswer;
	copy(data[4], IP_LENGTH, ipStr);
	set_task(WHOIS_ANSWER_STEP_INTERVAL, "WaitAnswer", TASK_WAIT_ANSWER_BASE + id, data, data[0]);
}

public WaitAnswer(data[], id)
{
	id -= TASK_WAIT_ANSWER_BASE;
	new socket = data[1];

	// Check if data is received
	new change = socket_change(socket, 1);

	if (!change)
		// Continue waiting for an answer
		set_task(WHOIS_ANSWER_STEP_INTERVAL, "WaitAnswer", TASK_WAIT_ANSWER_BASE + id, data, data[0]);
	else
		// Wait to receive whole answer
		set_task(WHOIS_WAIT_WHOLE_ANSWER, "WhoisAnswer", TASK_WHOIS_ANSWER_BASE + id, data, data[0]);
}

public WhoisAnswer(const data[], id)
{
	id -= TASK_WHOIS_ANSWER_BASE;
	new socket = data[1];

	new whoisProvider = data[2];
	new outputWhoisAnswer = data[3];
	new ipStr[IP_LENGTH + 1];
	copy(ipStr, charsmax(ipStr), data[4]);

	// Get answer
	new answer[2048];
	socket_recv(socket, answer, charsmax(answer));
	socket_close(socket);
#if defined _DEBUGWHOIS
	server_print("WhoisAnswer: id: %u, answer len: %u", id, strlen(answer));
#endif

	// Output the answer
	if (outputWhoisAnswer)
	{
		console_print(id, "=======================================================");
		console_print(id, "    Whois answer from: %s", _whoisHosts[whoisProvider]);
		console_print(id, "=======================================================");
		PrintLongText(id, answer);
		console_print(id, "=======================================================");
	}

	// Parse answer
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 2], netname[NETNAME_LENGTH + 1], description[DESCR_LENGTH + 1], countryCode[COUNTRYCODE_LENGTH + 1];
	new value[128];
	switch(whoisProvider)
	{
		case ARIN:
		{
			GetAtributeValue(answer, "ReferralServer:", value, charsmax(value));
            // Check if ARIN is referring
			if (value[0] != 0)
			{
				// Query other whois server
				if (contain(value, "ripe.net") > 0)
				{
#if defined _DEBUGWHOIS
					server_print("WhoisAnswer: starting subquery to ripe");
#endif
					WhoisQuery(id, RIPE, ipStr, outputWhoisAnswer);
					_whoisQueriesCount[id]--;
					return;
				}
				if (contain(value, "apnic.net") > 0)
				{
#if defined _DEBUGWHOIS
					server_print("WhoisAnswer: starting subquery to apnic");
#endif
					WhoisQuery(id, APNIC, ipStr, outputWhoisAnswer);
					_whoisQueriesCount[id]--;
					return;
				}
				if (contain(value, "lacnic.net") > 0)
				{
#if defined _DEBUGWHOIS
					server_print("WhoisAnswer: starting subquery to lacnic");
#endif
					WhoisQuery(id, LACNIC, ipStr, outputWhoisAnswer);
					_whoisQueriesCount[id]--;
					return;
				}
				if (contain(value, "afrinic.net") > 0)
				{
#if defined _DEBUGWHOIS
					server_print("WhoisAnswer: starting subquery to afrnic");
#endif
					WhoisQuery(id, AFRNIC, ipStr, outputWhoisAnswer);
					_whoisQueriesCount[id]--;
					return;
				}
			}
			// Ip range
			GetAtributeValue(answer, "NetRange:", value, charsmax(value));
            // Check if more then 1 entries found
			if (value[0] == 0)
			{
				// Search for object handler in ARIN answer
				new pos, offcet, lastpos = -1;
				while((offcet = strfind(answer[pos], "NET-")) >= 0)
				{
					pos += offcet;
					lastpos = pos;
					pos++;
				}
				if (lastpos > 0)
				{
					copyc(value, charsmax(value), answer[lastpos], ')');
#if defined _DEBUGWHOIS
					server_print("WhoisAnswer: starting subquery");
#endif
					WhoisQuery(id, ARIN, value, outputWhoisAnswer);
				}
				_whoisQueriesCount[id]--;
				return;
			}
			strtok(value, startIpStr, IP_LENGTH, endIpStr, IP_LENGTH + 1, '-');
			trim(startIpStr);
			trim(endIpStr);
			// Netname
			GetAtributeValue(answer, "NetName:", netname, NETNAME_LENGTH);
			// Descr
			GetAtributeValue(answer, "OrgName:", description, DESCR_LENGTH);
			if (description[0] == 0)
				GetAtributeValue(answer, "CustName:", description, DESCR_LENGTH);
			// Country code
			GetAtributeValue(answer, "Country:", countryCode, COUNTRYCODE_LENGTH);
		}
		case RIPE:
		{
			// Ip range
			GetAtributeValue(answer, "inetnum:", value, charsmax(value));
			strtok(value, startIpStr, IP_LENGTH, endIpStr, IP_LENGTH + 1, '-');
			trim(startIpStr);
			trim(endIpStr);
			// Netname
			GetAtributeValue(answer, "netname:", netname, NETNAME_LENGTH);
			// Descr
			GetAtributeValue(answer, "descr:", description, DESCR_LENGTH);
			// Country code
			GetAtributeValue(answer, "country:", countryCode, COUNTRYCODE_LENGTH);
		}
		case APNIC:
		{
			// Ip range
			GetAtributeValue(answer, "inetnum:", value, charsmax(value));
			strtok(value, startIpStr, IP_LENGTH, endIpStr, IP_LENGTH + 1, '-');
			trim(startIpStr);
			trim(endIpStr);
			// Netname
			GetAtributeValue(answer, "netname:", netname, NETNAME_LENGTH);
			// Descr
			GetAtributeValue(answer, "descr:", description, DESCR_LENGTH);
			// Country code
			GetAtributeValue(answer, "country:", countryCode, COUNTRYCODE_LENGTH);
		}
		case LACNIC:
		{
			// Ip range
			GetAtributeValue(answer, "inetnum:", value, charsmax(value));
			ParseCidr(value, startIpStr, charsmax(startIpStr), endIpStr, IP_LENGTH);
			// Netname
			//GetAtributeValue(answer, "netname:", netname, NETNAME_LENGTH);
			// Descr
			GetAtributeValue(answer, "owner:", description, DESCR_LENGTH);
			// Country code
			GetAtributeValue(answer, "country:", countryCode, COUNTRYCODE_LENGTH);
		}
		case AFRNIC:
		{
			// Ip range
			GetAtributeValue(answer, "inetnum:", value, charsmax(value));
			strtok(value, startIpStr, IP_LENGTH, endIpStr, IP_LENGTH + 1, '-');
			trim(startIpStr);
			trim(endIpStr);
			// Netname
			GetAtributeValue(answer, "netname:", netname, NETNAME_LENGTH);
			// Descr
			GetAtributeValue(answer, "descr:", description, DESCR_LENGTH);
			// Country code
			GetAtributeValue(answer, "country:", countryCode, COUNTRYCODE_LENGTH);
		}
		case RADB:
		{
			// Ip range
			GetAtributeValue(answer, "route:", value, charsmax(value));
#if defined _DEBUGWHOIS
			server_print("routes: \"%s\"", value);
#endif
			new subnet[IP_LENGTH + 4], subnetEnd[IP_LENGTH + 1];
			new rangeLength, rangeLengthSelected;
            // Select most narrow subnet from routes
			strtok(value, subnet, charsmax(subnet), value, charsmax(value), ';');
			while (subnet[0] != 0)
			{
#if defined _DEBUGWHOIS
				server_print("subnet: \"%s\"", subnet);
				server_print("left routes: \"%s\"", value);
#endif
				if (ParseCidr(subnet, subnet, charsmax(subnet), subnetEnd, IP_LENGTH))
				{
#if defined _DEBUGWHOIS
					server_print("subnet: \"%s\", subnetEnd: \"%s\"", subnet, subnetEnd);
#endif
					rangeLength = CalcRangeLength(subnet, subnetEnd);
#if defined _DEBUGWHOIS
					server_print("rangeLengthSelected: %u, rangeLength: %u", rangeLengthSelected, rangeLength);
#endif
					if (rangeLengthSelected == 0 || CompareUnsigned(rangeLengthSelected, rangeLength) > 0)
					{
#if defined _DEBUGWHOIS
						server_print("Copying...");
#endif
						copy(startIpStr, IP_LENGTH, subnet);
						copy(endIpStr, IP_LENGTH, subnetEnd);
						rangeLengthSelected = rangeLength;
					}
				}
#if defined _DEBUGWHOIS
				server_print("startIpStr: \"%s\"", startIpStr);
				server_print("endIpStr: \"%s\"", endIpStr);
#endif
				strtok(value, subnet, charsmax(subnet), value, charsmax(value), ';');
			}
		}
	}
#if defined _DEBUGWHOIS
	server_print("startIpStr: \"%s\"", startIpStr);
	server_print("endIpStr: \"%s\"", endIpStr);
	server_print("netname: \"%s\"", netname);
	server_print("descr: \"%s\"", description);
	server_print("country: \"%s\"", countryCode);
#endif

	// Store new range if it is smaller then queried before
	new rangeLength1 = CalcRangeLength(_whoisStartIps[id], _whoisEndIps[id]);
	new rangeLength2 = CalcRangeLength(startIpStr, endIpStr);
#if defined _DEBUGWHOIS
	server_print("rangeLength1: %u, rangeLength2: %u", rangeLength1, rangeLength2);
#endif
	if ((_whoisStartIps[id][0] == 0 || rangeLength1 == 0 || CompareUnsigned(rangeLength1, rangeLength2) >= 0) && 
		startIpStr[0] != 0 && endIpStr[0] != 0)
	{
		copy(_whoisStartIps[id], IP_LENGTH, startIpStr);
		copy(_whoisEndIps[id], IP_LENGTH, endIpStr);
		if (netname[0] != 0)
			copy(_whoisNetnames[id], NETNAME_LENGTH, netname);
		if (description[0] != 0)
			copy(_whoisDescriptions[id], DESCR_LENGTH, description);
		if (countryCode[0] != 0)
			copy(_whoisCountryCodes[id], COUNTRYCODE_LENGTH, countryCode);
    }
	if (_whoisNetnames[id][0] == 0)
		copy(_whoisNetnames[id], NETNAME_LENGTH, netname);
	if (_whoisDescriptions[id][0] == 0)
		copy(_whoisDescriptions[id], DESCR_LENGTH, description);
	if (_whoisCountryCodes[id][0] == 0)
		copy(_whoisCountryCodes[id], COUNTRYCODE_LENGTH, countryCode);

	_whoisQueriesCount[id]--;
}

GetAtributeValue(const text[], attr[], value[], valueSize)
{
	value[0] = 0;
	new temp[100];
	new searchpos = 0;
	new start = 0;
	new pos = 0;
#if defined _DEBUGWHOIS
	server_print("attr: %s", attr);
#endif
	while ((start = strfind(text[searchpos], attr)) >= 0)
	{
		if (strlen(value) > 0)
		{
			copy(value[pos], valueSize - pos, "; ");
			pos += 2;
		}
		searchpos += start + strlen(attr);
#if defined _DEBUGWHOIS
		server_print("searchpos: %i", searchpos);
#endif
		copyc(temp, charsmax(temp), text[searchpos], '\n');
		searchpos += strlen(temp);
		trim(temp);
#if defined _DEBUGWHOIS
		server_print("temp: %s", temp);
#endif
		copy(value[pos], valueSize - pos, temp);
		pos = strlen(value);
		if (pos >= valueSize - 2)
			return;
	}
}
