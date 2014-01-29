/*	AMX Mod X script.

	SubnetBan plugin by Lev.
	http://aghl.ru/forum/viewtopic.php?f=19&t=282 - Russian AG and HL Community

	Features:
		automatically resolve subnet for given IP with geoip db and whois queries;
		sql db or ini file for storing banned subnets;
		makes backup of ini file on unban command;
		store:
			subnet start IP;
			subnet end IP;
			allowed clients flags;
			ban datetime;
			last datetime connection from subnet was blocked;
			reason of a ban;
		logs commands usage;
		by default commands require 'n' access flag (you can change that in cmdaccess.ini file);
		inform players about newly connected player and his country;
		integration with dproto, so when player connects and his IP is in banned subnet:
			we look at which client he use and allow him to enter if client is allowed
			or tell him which clients he can use and give him a link to download client;
		you can use it without dproto if you wish so;
		automatic database and(or) table creation (requires correct rights for mysql user).

	Commands:
		sb_help		shows help on other command parameters;
		sb_ban		bans subnet specified by user (his IP will be used to detect subnet), IP (will be used to detect subnet),
					start IP and end IP or subnet in CIDR format;
		sb_unban	unbans subnet specified by IP (will process one or all subnets containing given IP) or
					start IP and end IP (will process exactly matching subnet or all intersecting subnets);
		sb_list		lists subnets specified by IP (will process one or all subnets containing given IP) or
					start IP and end IP (will process exactly matching subnet or all intersecting subnets);
		sb_search	list subnets containing given reason substring;
		sb_whois	quiries whois databases with given IP or IP of given player and outputs answers in console
					(pity, but using of non-threaded sockets leads to lag in game);
		sb_stat		outputs list of users currently on server with info about: user id, name, IP, 
					used protocol, auth provaider, country, city, network name, additional info from whois database
					(last two fields require sb_use_whois_on_connect "1", which leads to lag on player connection).

	CVARs:
		sb_sql_host "127.0.0.1"		// Host running MySql
		sb_sql_user "root"			// User name used to connect to MySql
		sb_sql_pass ""				// Password used to connect to MySql
		sb_sql_db "subnetbans"		// Database name to use
		sb_sql_create_db "0"		// Automatically create database and table (set to 2) or only table (set to 1) if they not exists

		sb_def_allowed_clients "bdghj"	// Allowed clients value used by default with ban command ("bdghj" = Native Steam, RevEmu, SC2009, AVSMP and RevEmu 2013)
		sb_allowed_flags "ab"			// If player has one of these access rights flags we allow him to enter without checking for a subnet ban
		sb_downloadurl "http://aghl.ru/files/patches/updater.exe"	// URL where user can download new client
		sb_download_clienttype "d"		// Type of client specified for download in URL
		sb_announce_connected "1"		// Enable/disable announce about newly connected user
		sb_use_whois_on_connect "0"		// Enable/disable use of whois for getting user net info in connect
		sb_use_whois_for_ban "1"		// Enable/disable use of whois for resolving subnet on ban command

	Requirements:
		module GeoIpMax: geoipmax_amxx.dll (Windows) / geoipmax_amxx_i386.so (Linux) is required (or disable its usage via compilation option);
		if you want to use whois you need to allow connection from server to TCP 43 port and have working DNS client;
		if you want to use geoip you need to download GeoLiteCity database and put it in addons\amxmodx\data\ folder.

	Compilation:
		put subnetban.sma in addons\amxmodx\scripting\ folder;
		put common_functions.inl, ip_functions.inl and whois.inl in addons\amxmodx\scripting\inline\ folder;
		for sql version uncomment line "#define USING_SQL" in subnetban.sma;
		for ini file version comment out line with "#define USING_SQL" in subnetban.sma;
		to disable GeoIpMax module usage comment out line with "#define USING_GEOIP" in subnetban.sma;
		to enable GeoIpMax module usage uncomment line with "#define USING_GEOIP" in subnetban.sma;
		type "compile.exe subnetban.sma" (Windows) or "compile.sh subnetban.sma" (Linux);
		compiled plugin (subnetban.amxx) will be in addons\amxmodx\scripting\compiled\ folder;
		it is recommended to rename compiled file of sql version to subnetban_sql.amxx.

	Installation:
		put subnetban.txt in addons\amxmodx\data\lang\ folder;
		for ini file version:
			put subnetban.amxx to addons\amxmodx\plugins\ folder;
			add subnetban.amxx to addons\amxmodx\config\plugins.ini file;
		for sql version:
			put subnetban_sql.amxx to addons\amxmodx\plugins\ folder;
			add subnetban_sql.amxx to addons\amxmodx\config\plugins.ini file;
			create MySql database with script included below;
			set db access info using cvars in any config file executed at server (server.cfg for example);
		put geoipmax_amxx.dll (Windows) or geoipmax_amxx_i386.so (Linux) in addons\amxmodx\modules\ folder;
		download GeoLiteCity database from http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz and extract it into addons\amxmodx\data\ folder;
		also you can update GeoLiteCountry database, download from http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz and extract to same folder as GeoLiteCity;
		sound buttons\bell1.wav is used for announcement of connecting player, so check that you have it in valve\sounds\buttons\ folder.

	Database creation script:
		CREATE DATABASE IF NOT EXISTS `subnetbans` DEFAULT CHARACTER SET latin1 COLLATE latin1_general_ci;
		CREATE TABLE IF NOT EXISTS `subnetbans`.`subnetbans` (
		`startip` INT UNSIGNED NOT NULL,
		`endip` INT UNSIGNED NOT NULL,
		`allowedclients` SMALLINT UNSIGNED NOT NULL,
		`datetimebanned` INT UNSIGNED NOT NULL,
		`datetimelastblocked` INT UNSIGNED NOT NULL,
		`reason` VARCHAR( 64 ) NOT NULL ,
		UNIQUE `startip_endip` ( `startip`, `endip` ),
		INDEX `startip` ( `startip` ),
		INDEX `endip` ( `endip` )
		);

	ChangeLog:
		v0.6a [2009.10.28]
			Alpha release.
		v0.7a [2009.11.17]
			+ Added: ini supporting version.
		v0.8a [2009.11.18]
			+ Added: now store reason for a ban.
		v0.9a [2009.11.20]
			+ Added: sb_whois command.
			+ Added: sb_stat command.
			+ Added: log commands usage.
		v1.0a [2009.11.20]
			+ Added: announce about newly connected user.
			+ Added: now store datetime subnet was banned, last datetime connection from subnet was blocked.
		v1.0b [2009.11.21]
			Beta release.
		v1.0b [2009.11.21]
			+ Added: compile option: USING_GEOIP.
		v1.1b [2009.12.22]
			! Fixed: ban stopped if sb_use_whois 0.
			+ Added: now two cvars to control use of whois.
		v1.2b [2009.04.08]
			! Fixed: sb_stat command now correctly working with new auth type (HLTV) and also with feature auth types.
		v1.3 [2011.02.15]
			Release vesion.
			+ Added: support for new dproto authproviders: SC2009 and AVSMP. Recommended DB update: UPDATE `subnetbans` SET `allowedclients`=202 WHERE `allowedclients`=10
			! Fixed: client now will be kicked if disconnect will not do work.
			! Fixed: small potential bugs.
			! Fixed: small texts corrections.
			! Changed: default clients in CVAR sb_def_allowed_clients now are (used for ban): "bdgh".
			+ Added: new CVAR sb_download_clienttype - used to show download URL if that client type is allowed.
			! Fixed: ban command parameters parsing (in case client flags are empty).
			+ Added: sb_search command - search for specified reason substring. Update DB with: ALTER TABLE `subnetbans` CHANGE `reason` `reason` VARCHAR( 64 ) CHARACTER SET latin COLLATE latin1_general_ci NOT NULL
		v1.4 [2011.02.23]
			+ Added: CVAR sb_sql_create_db - use it to automatically create database and(or) table for bans.
			! Fixed: little correction to help text.
		v1.5 [2013.08.07]
			+ Added: support for new dproto authprovider: sXe Injected.
		v1.6 [2013.08.12]
			+ Added: support for new dproto authprovider: RevEmu 2013.
			! Changed: default clients in CVAR sb_def_allowed_clients now are (used for ban): "bdghj".
			+ Recommended DB update: ALTER TABLE `subnetbans` CHANGE `allowedclients` `allowedclients` SMALLINT UNSIGNED NOT NULL; UPDATE `subnetbans` SET `allowedclients`=714 WHERE `allowedclients`=202
		v1.7 [2013.10.08]
			! Fixed: bug with limited flags in the code.
		v1.8 [2013.10.21]
			! Fixed: bug with parsing CIDR with spaces.

	To convert DB to file you can use following select command and find&replace regexes:
		SELECT INET_NTOA(`startip`),INET_NTOA(`endip`),'bd',FROM_UNIXTIME(`datetimebanned`),FROM_UNIXTIME(`datetimelastblocked`),`reason` FROM `subnetbans`
		(.*?) [\s]*(.*?) [\s]*(.*?) [\s]*(.*? [\s]*.*?) [\s]*(.*? [\s]*.*?) [\s]*(.*)
		\1 \2 \3 "\4" "\5" "\6"

	Todo:
		work with whois so it stop on error and return error
		check all players on ban
		write whois module with threaded sockets
		add support for AS query
		ban all subnets in AS with the same (or close) description
		autoban on info field
		configure for autoban with smallest, widest or AS ban
		! Changed: moved DB to use int in client types field for feature client types support. Update DB with: ALTER TABLE `subnetbans` CHANGE `allowedclients` `allowedclients` INT UNSIGNED NOT NULL

*/

#pragma semicolon 1
#pragma ctrlchar '\'

// Compilation options
// Uncomment for SQL version
//#define USING_SQL
// Uncomment to use GeoIpMax module
#define USING_GEOIP
// Uncomment to debug
//#define _DEBUG			// Enable debug output at server console.
//#define _DEBUGSQL		// Enable debug output of SQL commands at server console.

#include <amxmodx>
#include <amxmisc>
#if defined USING_GEOIP
	#include <geoipmax>
#endif
#include <sockets>
#if defined USING_SQL
	#include <sqlx>
#endif

#include "inline/common_functions.inl"
#include "inline/ip_functions.inl"
#include "inline/whois.inl"

#define AUTHOR "Lev"
#if defined USING_SQL
	#define PLUGIN "SubnetBan (Sql)"
#else
	#define PLUGIN "SubnetBan"
#endif
#define PLUGIN_TAG "SubnetBan"
#define VERSION "1.7"
#define VERSION_CVAR "subnetban_version"

// Constants
#define DEF_ADMIN_LEVEL			ADMIN_LEVEL_B	// Default access level for commands (flag n).
#define TABLE_SUBNETBANS		"subnetbans"
#define TASK_CHECKIP_BASE		200
#define TASK_KICK_BASE			300
#define CHECKIP_DELAY			0.1
#define KICK_DELAY				1.0
#define TOO_WIDE_SUBNET			1 << 24	// If auto resolved subnet length is more than this then banning is canceled.

// MAX constants
#define MAX_PLAYERS				32
#define MAX_REASON_LENGTH		64
#define MAX_FLAGS				10
#define MAX_FILE_NAME_LENGTH	64
#define MAX_COUNTRY_NAME_LENGTH 32
#define MAX_CITY_LENGTH			32
#define MAX_DATETIME_LENGTH		19

// Dproto constants
#define DP_AUTH_NONE 		0	// flag	// "N/A" - slot is free
#define DP_AUTH_DPROTO		1	// a	// dproto
#define DP_AUTH_STEAM		2	// b	// Native Steam
#define DP_AUTH_STEAMEMU	3	// c	// SteamEmu
#define DP_AUTH_REVEMU		4	// d	// RevEmu
#define DP_AUTH_OLDREVEMU	5	// e	// Old RevEmu
#define DP_AUTH_HLTV		6	// f	// HLTV
#define DP_AUTH_SC2009		7	// g	// SteamClient2009
#define DP_AUTH_AVSMP		8	// h	// AVSMP
#define DP_AUTH_SXEI		9	// i	// sXe Inhected
#define DP_AUTH_REVEMU2013	10	// j	// RevEmu 2013

// Authprov names
new _authprovStr[][] = {
	"Unknown",
	"Non steam",
	"Steam",
	"SteamEmu",
	"RevEmu",
	"Old RevEmu",
	"HLTV",
	"SteamClient2009",
	"AVSMP",
	"sXe Injected",
	"RevEmu 2013"
};

// Sound that will be played on connection announcement
new const _connectionSound[] = "buttons/bell1.wav";

// Datetime format for storing datetime in ini file
new const _datetimeFormat[] = "%Y.%m.%d %H:%M:%S";

// Players' data
new bool:_playerPutOrAuth[MAX_PLAYERS + 1];	// Player was put in server or auth.
new _playerProto[MAX_PLAYERS + 1];
new _playerAuthprov[MAX_PLAYERS + 1];
new _playerNetname[MAX_PLAYERS + 1][NETNAME_LENGTH + 1];
new _playerDescr[MAX_PLAYERS + 1][DESCR_LENGTH + 1];
new _playerCountryCode[MAX_PLAYERS + 1][COUNTRYCODE_LENGTH + 1];
new _playerCity[MAX_PLAYERS + 1][MAX_CITY_LENGTH + 1];

// CVARs
#if defined USING_SQL
new pcvar_sb_sql_host;
new pcvar_sb_sql_user;
new pcvar_sb_sql_pass;
new pcvar_sb_sql_db;
new pcvar_sb_sql_create_db;
#endif
#if defined USING_GEOIP
new pcvar_sb_announce_connected;
#endif
new pcvar_sb_def_allowed_clients;
new pcvar_sb_allowed_flags;
new pcvar_sb_downloadurl;
new pcvar_sb_download_ct;
new pcvar_sb_use_whois_on_connect;
new pcvar_sb_use_whois_for_ban;
new pcvar_dp_r_protocol;
new pcvar_dp_r_id_provider;

// Bans data
#if defined USING_SQL
new Handle:_sqlHandle;
new Handle:_sqlHandleWithoutDb;
#else
new _subnetBanFile[MAX_FILE_NAME_LENGTH + 1];
new _bansCount;
new Array:_bansStartIps;
new Array:_bansEndIps;
new Array:_bansAllowedClients;
new Array:_bansDatetimeBanned;
new Array:_bansDatetimeLastBlocked;
new Array:_bansReasons;
#endif

// Ban data
new bool:_banningInProgress;
new _banStartIpStr[IP_LENGTH + 1];
new _banEndIpStr[IP_LENGTH + 1];
new _banAllowedClients;
new _banReason[MAX_REASON_LENGTH + 1];
new _banPlayerId;	// Will recheck that player after completing ban process

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar(VERSION_CVAR, VERSION, FCVAR_SPONLY | FCVAR_SERVER | FCVAR_UNLOGGED);

	register_dictionary("subnetban.txt");

#if defined USING_SQL
	pcvar_sb_sql_host = register_cvar("sb_sql_host", "127.0.0.1");
	pcvar_sb_sql_user = register_cvar("sb_sql_user", "root");
	pcvar_sb_sql_pass = register_cvar("sb_sql_pass", "");
	pcvar_sb_sql_db = register_cvar("sb_sql_db", "subnetbans");
	pcvar_sb_sql_create_db = register_cvar("sb_sql_create_db", "0");
#else
	get_datadir(_subnetBanFile, charsmax(_subnetBanFile));
	add(_subnetBanFile, charsmax(_subnetBanFile), "/subnetban.ini");
	_bansStartIps = ArrayCreate(1);
	_bansEndIps = ArrayCreate(1);
	_bansAllowedClients = ArrayCreate(1);
	_bansDatetimeBanned = ArrayCreate(1);
	_bansDatetimeLastBlocked = ArrayCreate(1);
	_bansReasons = ArrayCreate(MAX_REASON_LENGTH + 1);

	LoadBannedSubnets();
#endif

	pcvar_sb_def_allowed_clients = register_cvar("sb_def_allowed_clients", "bdghj");	// Allowed clients value used by default (Native Steam, RevEmu, SC2009, AVSMP and RevEmu 2013).
	pcvar_sb_allowed_flags = register_cvar("sb_allowed_flags", "ab");	// If player has one of these flags we allow him to enter.
	pcvar_sb_downloadurl = register_cvar("sb_downloadurl", "http://aghl.ru/files/patches/updater.exe");	// URL where new client with emulator reside.
	pcvar_sb_download_ct = register_cvar("sb_download_clienttype", "d");	// Type of client specified for download in URL.

#if defined USING_GEOIP
	pcvar_sb_announce_connected = register_cvar("sb_announce_connected", "1");	// Enable/disable announce about newly connected user.
#endif
	pcvar_sb_use_whois_on_connect = register_cvar("sb_use_whois_on_connect", "0");	// Enable/disable use of whois on connect.
	pcvar_sb_use_whois_for_ban = register_cvar("sb_use_whois_for_ban", "1");		// Enable/disable use of whois for ban.

	pcvar_dp_r_protocol = get_cvar_pointer("dp_r_protocol");		// Dproto interface.
	pcvar_dp_r_id_provider = get_cvar_pointer("dp_r_id_provider");	// Dproto interface.

	register_concmd("sb_help", "CmdHelp", DEF_ADMIN_LEVEL, "(Shows help on SubnetBan commands)");
	register_concmd("sb_ban", "CmdBan", DEF_ADMIN_LEVEL, "(Bans subnet. Use sb_help to get info about command usage)");
	register_concmd("sb_unban", "CmdUnban", DEF_ADMIN_LEVEL, "(Unbans subnet. Use sb_help to get info about command usage)");
	register_concmd("sb_list", "CmdList", DEF_ADMIN_LEVEL, "(List subnets. Use sb_help to get info about command usage)");
	register_concmd("sb_search", "CmdSearch", DEF_ADMIN_LEVEL, "(Search subnets. Use sb_help to get info about command usage)");
	register_concmd("sb_whois", "CmdWhois", DEF_ADMIN_LEVEL, "(Makes whois query. Use sb_help to get info about command usage)");
	register_concmd("sb_stat", "CmdStat", DEF_ADMIN_LEVEL, "(Outputs users info)");

#if defined USING_SQL
	set_task(0.5, "InitSql");
}

public InitSql()
{
	new host[64], user[32], pass[32], db[128];

	get_pcvar_string(pcvar_sb_sql_host, host, charsmax(host));
	get_pcvar_string(pcvar_sb_sql_user, user, charsmax(user));
	get_pcvar_string(pcvar_sb_sql_pass, pass, charsmax(pass));
	get_pcvar_string(pcvar_sb_sql_db, db, charsmax(db));
#if defined _DEBUG
	server_print("host: %s, user: %s, pass: %s, db: %s", host, user, pass, db);
#endif

	_sqlHandle = SQL_MakeDbTuple(host, user, pass, db);

	// Return if not permit to create database or table
	if (get_pcvar_num(pcvar_sb_sql_create_db) == 0)
		return;

	if (get_pcvar_num(pcvar_sb_sql_create_db) == 2)
	{
		_sqlHandleWithoutDb = SQL_MakeDbTuple(host, user, pass, "");
		// Create database if not exists
		new data[1];
		CreateDbIfNotExists("AfterDbCreate", data, sizeof(data));
	}
	else
	{
		// Create table if not exists
		new data[1];
		CreateTableIfNotExists("AfterTableCreate", data, sizeof(data));
	}
}

/// Handles errors in database creation.
public AfterDbCreate(failstate, Handle:query, error[], errnum, data[], size)
{
	SQL_FreeHandle(_sqlHandleWithoutDb);

	// Log on error
	if (failstate)
	{
		log_amx("%L", LANG_SERVER, "SB_DB_CREATE_FAILED");
		MySqlX_ThreadError(error, errnum, failstate, 08);
	}

	// Create table if not exists
	new data[1];
	CreateTableIfNotExists("AfterTableCreate", data, sizeof(data));
}

/// Handles errors in DB creation.
public AfterTableCreate(failstate, Handle:query, error[], errnum, data[], size)
{
	// Log on error
	if (failstate)
	{
		log_amx("%L", LANG_SERVER, "SB_TABLE_CREATE_FAILED");
		MySqlX_ThreadError(error, errnum, failstate, 09);
	}
#endif // #if defined USING_SQL
}

public plugin_precache()
{
	precache_sound(_connectionSound);
}

public client_connect(id)
{
	_playerPutOrAuth[id] = false;

	// Get user proto and authprov
	if (pcvar_dp_r_protocol && pcvar_dp_r_id_provider)
	{
		server_cmd("dp_clientinfo %d", id);
		server_exec();
		_playerProto[id] = get_pcvar_num(pcvar_dp_r_protocol);
		_playerAuthprov[id] = get_pcvar_num(pcvar_dp_r_id_provider);
	}
#if defined _DEBUG
	server_print("Player proto: %u, authprov: %u", _playerProto[id], _playerAuthprov[id]);
#endif

	// Get user IP
	new ipStr[IP_LENGTH + 1];
	get_user_ip(id, ipStr, charsmax(ipStr), 1);

#if defined USING_GEOIP
	// Get user geo info
	geoip_country_code2(ipStr, _playerCountryCode[id]);
	geoip_city_name(ipStr, _playerCity[id], MAX_CITY_LENGTH);
#endif

	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	_playerProto[id] = 0;
	_playerAuthprov[id] = 0;
	_playerNetname[id][0] = 0;
	_playerDescr[id][0] = 0;
	_playerCountryCode[id][0] = 0;
	_playerCity[id][0] = 0;
}

public client_authorized(id)
{
	if (_playerPutOrAuth[id])
	{
		set_task(CHECKIP_DELAY, "CheckIp", TASK_CHECKIP_BASE + id);
		return PLUGIN_CONTINUE;
	}
	_playerPutOrAuth[id] = true;
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	if (_playerPutOrAuth[id])
	{
		set_task(CHECKIP_DELAY, "CheckIp", TASK_CHECKIP_BASE + id);
		return PLUGIN_CONTINUE;
	}
	_playerPutOrAuth[id] = true;
	return PLUGIN_CONTINUE;
}

#if defined USING_SQL
public plugin_end()
{
	if (_sqlHandle != Handle:0)
		SQL_FreeHandle(_sqlHandle);
}
#endif



//****************************************
//*                                      *
//*  Check Player's IP                   *
//*                                      *
//****************************************

public CheckIp(id)
{
	id -= TASK_CHECKIP_BASE;
	// Skip cheking on error id or user not connected or user is a bot
	if (id <= 0 || id >= MAX_PLAYERS || !is_user_connected(id) || is_user_bot(id))
		return PLUGIN_CONTINUE;

	// If player has rights then bypass checking
	if (access(id, get_sb_allowed_flags()))
		return PlayerIn(id);

	// Get user IP
	new ipStr[IP_LENGTH + 1];
	get_user_ip(id, ipStr, charsmax(ipStr), 1);

#if defined USING_SQL

	// Query database for banned subnet
	new data[1];
	data[0] = id;
	SelectSubnets("CheckIp2", ipStr, true, data, sizeof(data));

	return PLUGIN_CONTINUE;
}

public CheckIp2(failstate, Handle:query, error[], errnum, data[], dataSize)
{
	new id = data[0];
	
	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 01);
		return PlayerIn(id);
	}

	// Return if no bans found for player's IP
	if (!SQL_NumResults(query))
		return PlayerIn(id);

	// Get allowed clients from results
	new allowedClients = SQL_ReadResult(query, SQL_FieldNameToNum(query, "allowedclients"));

#else // #if defined USING_SQL

	// Seek for banned subnet
	new Array:results = SelectSubnets(ipStr, true);

	// Return if no bans found for player's IP
	if (!ArraySize(results))
		return PlayerIn(id);

	// Get allowed clients from results
	new banid = ArrayGetCell(results, 0);
	new allowedClients = ArrayGetCell(_bansAllowedClients, banid);

#endif // #if defined USING_SQL

#if defined _DEBUG
	server_print("Allowed Clients: %u", allowedClients);
#endif

	// Check client type is it allowed or not
	if (_playerAuthprov[id] > 0 && _playerAuthprov[id] < 33 && isClientSet(allowedClients, _playerAuthprov[id]))
		return PlayerIn(id);

	// Get subnet IPs bounds
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1], reason[MAX_REASON_LENGTH + 1];
#if defined USING_SQL
	SQL_ReadResult(query, SQL_FieldNameToNum(query, "startipstr"), startIpStr, charsmax(startIpStr));
	SQL_ReadResult(query, SQL_FieldNameToNum(query, "endipstr"), endIpStr, charsmax(endIpStr));
	SQL_ReadResult(query, SQL_FieldNameToNum(query, "reason"), reason, charsmax(reason));
#else
	IpToStr(ArrayGetCell(_bansStartIps, banid), startIpStr, charsmax(startIpStr));
	IpToStr(ArrayGetCell(_bansEndIps, banid), endIpStr, charsmax(endIpStr));
	ArrayGetString(_bansReasons, banid, reason, charsmax(reason));
#endif
#if defined _DEBUG
	server_print("Range: %s - %s", startIpStr, endIpStr);
#endif

	// Show ban info
	new clientDownloadUrl[256], allowed[25], disallowed[25];
	format(allowed, charsmax(allowed), "[%L]", id, "SB_ALLOWED");
	format(disallowed, charsmax(disallowed), "[%L]", id, "SB_DISALLOWED");
	get_pcvar_string(pcvar_sb_downloadurl, clientDownloadUrl, charsmax(clientDownloadUrl));

	client_cmd(id, "clear");
	if (reason[0] != 0)
	{
		client_cmd(id, "echo \"[SubnetBan] ===============================================\"");
		client_cmd(id, "echo \"[SubnetBan] %s\"", reason);
	}
	client_cmd(id, "echo \"[SubnetBan] ===============================================\"");
	client_cmd(id, "echo \"[SubnetBan] %L\"", id, "SUBNET_BANNED", startIpStr, endIpStr);
	client_cmd(id, "echo \"[SubnetBan] %L\"", id, "SB_ALLOWED_CLIENTS");
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_STEAM], isClientSet(allowedClients, DP_AUTH_STEAM) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_REVEMU], isClientSet(allowedClients, DP_AUTH_REVEMU) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_OLDREVEMU], isClientSet(allowedClients, DP_AUTH_OLDREVEMU) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_STEAMEMU], isClientSet(allowedClients, DP_AUTH_STEAMEMU) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_SC2009], isClientSet(allowedClients, DP_AUTH_SC2009) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_AVSMP], isClientSet(allowedClients, DP_AUTH_AVSMP) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_SXEI], isClientSet(allowedClients, DP_AUTH_SXEI) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_REVEMU2013], isClientSet(allowedClients, DP_AUTH_REVEMU2013) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_OTHER_CLIENT", isClientSet(allowedClients, DP_AUTH_DPROTO) ? allowed : disallowed);
	client_cmd(id, "echo \"[SubnetBan]    %L\"", id, "SB_CLIENT_STATE", _authprovStr[DP_AUTH_HLTV], isClientSet(allowedClients, DP_AUTH_HLTV) ? allowed : disallowed);
	if ((allowedClients & get_sb_download_ct()) && clientDownloadUrl[0] != 0)
	{
		client_cmd(id, "echo \"[SubnetBan] ===============================================\"");
		client_cmd(id, "echo \"[SubnetBan] %L\"", id, "DOWNLOAD_CLIENT");
		client_cmd(id, "echo \"[SubnetBan] %s\"", clientDownloadUrl);
		client_cmd(id, "echo \"[SubnetBan] %L\"", id, "USE_OTHER_CLIENT");
	}
	client_cmd(id, "echo \"[SubnetBan] ===============================================\"");

	// Show console and disconnect
	client_cmd(id, "toggleconsole;disconnect");

	// Kick user if disconnect will not do work
	set_task(KICK_DELAY, "KickUser", TASK_KICK_BASE + id);

	// Update datetime this subnet has blocked entry
#if defined USING_SQL
	new data[1];
	data[0] = id;
	UpdateSubnet("BanUpdated", startIpStr, endIpStr, allowedClients, reason, true, data, sizeof(data));

	return PLUGIN_CONTINUE;
}

public BanUpdated(failstate, Handle:query, error[], errnum, data[], size)
{
	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 02);
		return PLUGIN_CONTINUE;
	}

#else // #if defined USING_SQL

	UpdateSubnet(ArrayGetCell(results, 0), allowedClients, reason, true);

#endif // #if defined USING_SQL

	return PLUGIN_CONTINUE;
}

public PlayerIn(id)
{
#if defined USING_GEOIP
	// Inform all players about entered player
	if (get_pcvar_num(pcvar_sb_announce_connected) > 0)
	{
		new name[32], country[MAX_COUNTRY_NAME_LENGTH + 1];
		get_user_name(id, name, charsmax(name));
		geoip_country_name_by_cc(_playerCountryCode[id], country, charsmax(country));
		set_hudmessage(180, 240, 150, 0.02, 0.02, 0, 0.0, 3.0, 0.3, 0.6, -1);
		show_hudmessage(0, "%L", id, "CONNECTED_FROM", name, country);
		PlaySoundForAll(_connectionSound, id);
	}
#endif
	// Get info about client
	if (get_pcvar_num(pcvar_sb_use_whois_on_connect) > 0)
	{
		new ipStr[IP_LENGTH + 1];
		get_user_ip(id, ipStr, charsmax(ipStr), 1);
		Whois(id, ipStr, "GetPlayerInfoAnswer", false);
	}
	return PLUGIN_CONTINUE;
}

public GetPlayerInfoAnswer(id)
{
	id -= TASK_WHOIS_CALLBACK_BASE;
	if (id <= 0 || id >= MAX_PLAYERS)
		return;
	copy(_playerNetname[id], NETNAME_LENGTH, _whoisNetnames[id]);
	copy(_playerDescr[id], DESCR_LENGTH, _whoisDescriptions[id]);
	copy(_playerCountryCode[id], COUNTRYCODE_LENGTH, _whoisCountryCodes[id]);
}

public KickUser(id)
{
	id -= TASK_KICK_BASE;
	if (id <= 0 || id >= MAX_PLAYERS || !is_user_connected(id))
		return;
	new userid = get_user_userid(id);
	server_cmd("kick #%d \"%L\"", userid, id, "SUBNET_BANNED_CONSOLE");
}



//****************************************
//*                                      *
//*  Help command                        *
//*                                      *
//****************************************

/// Format: sb_help
public CmdHelp(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	console_print(id, "[SubnetBan] Usage:");
	console_print(id, "sb_ban:");
	console_print(id, "  <steamID | nickname | user ID | IP> [allowed clients flags] [reason]");
	console_print(id, "  <start IP> <end IP> [allowed clients flags] [reason]");
	console_print(id, "  <subnet in CIDR format> [allowed clients flags] [reason]");
	console_print(id, "sb_unban:");
	console_print(id, "  <IP> [limit (default 1)]");
	console_print(id, "  <start IP> <end IP> [exact match (default 1)]");
	console_print(id, "  <subnet in CIDR format> [exact match (default 1)]");
	console_print(id, "sb_list:");
	console_print(id, "  <IP> [limit (default 0)]");
	console_print(id, "  <start IP> <end IP> [exact match (default 0)]");
	console_print(id, "  <subnet in CIDR format> [exact match (default 0)]");
	console_print(id, "sb_search:");
	console_print(id, "  <reason substring>");
	console_print(id, "sb_whois:");
	console_print(id, "  <steamID | nickname | user ID | IP>");
	console_print(id, "");

	console_print(id, "Meaning of parameters:");
	console_print(id, "  <> - required parameter");
	console_print(id, "  [] - optional parameter");
	console_print(id, "  steamID - \"STEAM_0:x:xxxxxxxx\", will seek for player with this steamID");
	console_print(id, "  nickname - \"pl\", will seek for player with name containing this substring");
	console_print(id, "  user ID - #245, will seek for player with this user ID");
	console_print(id, "  IP - \"1.2.3.4\", will use this IP to resolve subnet");
	console_print(id, "  subnet in CIDR format - \"1.2.3.4/16\", will use this subnet");
	console_print(id, "  start IP - \"1.2.3.4\", start border of a subnet; should be followed by end IP");
	console_print(id, "  end IP - \"1.2.3.4\", end border of a subnet; should be forestalled by start IP");
	console_print(id, "  allowed clients flags - \"abcdefgh\", clients allowed to enter from a subnet");
	console_print(id, "  reason - \"Bye!\", custom text that will be shown to banned players");
	console_print(id, "  exact match - 0 or 1, this parameter is used only if subnet was specified");
	console_print(id, "    0 - all subnets intersecting given subnet will be processed");
	console_print(id, "    1 - only exactly matching subnet will be processed");
	console_print(id, "  limit - 0 or 1, this parameter is used only if alone IP was specified");
	console_print(id, "    0 - all subnets that include given IP will be processed");
	console_print(id, "    1 - will process most narrow subnet that include given IP");
	//console_print(id, "    n - list of processed subnets is sorted by subnet length (most narrow will be first)");
	//console_print(id, "        and only first n subnets will be processed");
	
	console_print(id, "Allowed clients flags: (they are based on dproto authprov)");
	console_print(id, "  a - dproto (clients without an emulator)");
	console_print(id, "  b - Native Steam");
	console_print(id, "  c - SteamEmu");
	console_print(id, "  d - RevEmu");
	console_print(id, "  e - Old RevEmu");
	console_print(id, "  f - HLTV");
	console_print(id, "  g - SteamClient2009");
	console_print(id, "  h - AVSMP");
	console_print(id, "  i - sXe Injected");
	console_print(id, "  j - RevEmu 2013");

	console_print(id, "Notes:");
	console_print(id, "  when specifying steamID, nickname or user ID for sb_ban command:");
	console_print(id, "    if multiple players will be found then banning will be cancelled");
	console_print(id, "    if one player will be found then his IP will be used to resolve subnet");

	return PLUGIN_HANDLED;
}



//****************************************
//*                                      *
//*  Ban command                         *
//*                                      *
//****************************************

/// Format: sb_ban
/// <steamID | nickname | user ID | IP | subnet in CIDR format> [allowed clients flags] [reason]
/// <start IP> <end IP> [allowed clients flags] [reason]
public CmdBan(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	// Parse command
	new cmd[128], param[64], bool:isRange, firstParamIsIp, playerId;
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1], allowedClientsStr[MAX_FLAGS + 1], reason[MAX_REASON_LENGTH + 1];
	read_args(cmd, charsmax(cmd));

	// First parameter
	strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
	// Try to parse CIDR format
	if (ParseCidr(param, startIpStr, charsmax(startIpStr), endIpStr, charsmax(endIpStr)))
	{
		isRange = true;
	}
	// Check if first parameter is IP or not
	else if (IsIpValid(param))
	{
		copy(startIpStr, charsmax(startIpStr), param);
		firstParamIsIp = 1;
	}
	else
	{
		// Try to find a player that should be banned
		playerId = LocatePlayer(id, param, true, true);
		if (playerId <= 0 || playerId >= MAX_PLAYERS)
			// Player is a BOT or has immunity (-1) or just out of boundary
			return PLUGIN_HANDLED;
		get_user_ip(playerId, startIpStr, charsmax(startIpStr), 1);
	}

	// Second and following parameters
	if (cmd[0] != 0)
	{
		strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
		// If first parameter is IP then check if second parameter is IP or not
		if (firstParamIsIp && IsIpValid(param))
		{
			copy(endIpStr, charsmax(endIpStr), param);
			isRange = true;
			// Get next parameter
			strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
		}

		// Allowed Clients
		if (param[0] != 0)
			copy(allowedClientsStr, charsmax(allowedClientsStr), param);

		// Reason
		if (cmd[0] != 0)
			strbreak(cmd, reason, charsmax(reason), cmd, charsmax(cmd));
	}

	new allowedClients = read_flags_fixed(allowedClientsStr);
	// If allowed clients not specified set default allowed clients
	if (allowedClients == 0)
		allowedClients = get_sb_def_allowed_clients();
	// Convert allowed clients flags to TINYINT (current DB column size)
	allowedClients = allowedClients & 65535;

#if defined _DEBUG
	server_print("CmdBan: start ip: %s, end ip: %s, allowed clients: %s, %u, isRange: %u", startIpStr, endIpStr, allowedClientsStr, allowedClients, isRange);
	server_print("CmdBan: reason: \"%s\"", reason);
#endif

	// Check for ban in progress
	if (_banningInProgress)
	{
		console_print(id, "[SubnetBan] %L", id, "SB_BAN_IN_PROGRESS");
		return PLUGIN_HANDLED;
	}
	_banningInProgress = true;

	// Get subnet by IP and prepare data for ban
	_banAllowedClients = allowedClients;
	copy(_banReason, charsmax(_banReason), reason);
	_banPlayerId = playerId;
	if (isRange)
	{
		copy(_banStartIpStr, charsmax(_banStartIpStr), startIpStr);
		copy(_banEndIpStr, charsmax(_banEndIpStr), endIpStr);
		SearchSubnetBan(id);
	}
	else
	{
		_banStartIpStr[0] = _banEndIpStr[0] = 0;
		GetSubnetByIp(id, startIpStr);
	}

	return PLUGIN_HANDLED;
}

/// Find subnet bounds by IP.
public GetSubnetByIp(id, const ipStr[])
{
#if defined USING_GEOIP
	// Resolve subnet via maxmind DB
	new success = geoip_range(ipStr, _banStartIpStr, charsmax(_banStartIpStr), _banEndIpStr, charsmax(_banEndIpStr));
	if (!success) _banStartIpStr[0] = _banEndIpStr[0] = 0;
	else console_print(id, "[SubnetBan] %L", id, "MAXMIND_DB_RESULT", _banStartIpStr, _banEndIpStr);
#endif

	// Resolve subnet via whois
	if (get_pcvar_num(pcvar_sb_use_whois_for_ban) > 0)
	{
		console_print(id, "[SubnetBan] %L", id, "WHOIS_QUERY_STARTING");
		Whois(id, ipStr, "WhoisComplete", false);
	}
	else
	{
		WhoisComplete(id + TASK_WHOIS_CALLBACK_BASE);
	}
}

/// Handle whois complete event.
public WhoisComplete(id)
{
	id -= TASK_WHOIS_CALLBACK_BASE;

#if defined _DEBUG
	server_print("WhoisComplete: id: %u", id);
	server_print("startIpStr: \"%s\"", _whoisStartIps[id]);
	server_print("endIpStr: \"%s\"", _whoisEndIps[id]);
	server_print("netname: \"%s\"", _whoisNetnames[id]);
	server_print("descr: \"%s\"", _whoisDescriptions[id]);
	server_print("country: \"%s\"", _whoisCountryCodes[id]);
#endif
	// Show result at console
	console_print(id, "[SubnetBan] %L", id, "WHOIS_RESULT", _whoisStartIps[id], _whoisEndIps[id]);

	// Decide which subnet is more narrow
	new rangeLength1 = CalcRangeLength(_banStartIpStr, _banEndIpStr);
	new rangeLength2 = CalcRangeLength(_whoisStartIps[id], _whoisEndIps[id]);
	if ((_banStartIpStr[0] == 0 || rangeLength1 == 0 || CompareUnsigned(rangeLength1, rangeLength2) > 0) && 
		_whoisStartIps[id][0] != 0 && _whoisEndIps[id][0] != 0)
	{
		copy(_banStartIpStr, IP_LENGTH, _whoisStartIps[id]);
		copy(_banEndIpStr, IP_LENGTH, _whoisEndIps[id]);
		rangeLength1 = rangeLength2;
	}

	// Check subnet width
	if (CompareUnsigned(rangeLength1, TOO_WIDE_SUBNET) >= 0)
	{
		console_print(id, "[SubnetBan] %L", id, "SUBNET_TOO_WIDE", _banStartIpStr, _banEndIpStr);
		_banningInProgress = false;
		return;
	}

	// Check if subnet was successfully resolved
	if (_banStartIpStr[0] == 0 || _banEndIpStr[0] == 0)
	{
		console_print(id, "[SubnetBan] %L", id, "UNABLE_RESOLVE_SUBNET");
		_banningInProgress = false;
		return;
	}

	SearchSubnetBan(id);
}

/// Search for that subnet is already banned.
public SearchSubnetBan(id)
{
#if defined _DEBUG
	server_print("SearchSubnetBan: banStartIpStr: \"%s\"", _banStartIpStr);
	server_print("SearchSubnetBan: banEndIpStr: \"%s\"", _banEndIpStr);
#endif

	// Search for that subnet is already banned
#if defined USING_SQL
	new data[1];
	data[0] = id;
	SelectSubnets2("InsertSubnetBan", _banStartIpStr, _banEndIpStr, true, data, sizeof(data));
}

/// Inserts or updates subnet ban.
public InsertSubnetBan(failstate, Handle:query, error[], errnum, data[], size)
{
	new id = data[0];

	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 03);
		console_print(id, "[SubnetBan] %L", id, "SB_BAN_FAILED");
		_banningInProgress = false;
		return;
	}

	new data[2];
	data[0] = id;
	data[1] = SQL_NumResults(query);
	if (data[1])
	{
		// Update ban
		UpdateSubnet("BanFinished", _banStartIpStr, _banEndIpStr, _banAllowedClients, _banReason, false, data, sizeof(data));
	}
	else
	{
		// Insert new ban
		InsertSubnet("BanFinished", _banStartIpStr, _banEndIpStr, _banAllowedClients, _banReason, data, sizeof(data));
	}
}

public BanFinished(failstate, Handle:query, error[], errnum, data[], size)
{
	new id = data[0];
	new numResults = data[1];

	_banningInProgress = false;

	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 04);
		console_print(id, "[SubnetBan] %L", id, "SB_BAN_FAILED");
		return;
	}

#else // #if defined USING_SQL

	new Array:results = SelectSubnets2(_banStartIpStr, _banEndIpStr, true);
	new numResults = ArraySize(results);
	new bool:result;
	if (numResults)
	{
		// Update ban
		result = UpdateSubnet(ArrayGetCell(results, 0), _banAllowedClients, _banReason, false);
	}
	else
	{
		// Insert new ban
		result = InsertSubnet(_banStartIpStr, _banEndIpStr, _banAllowedClients, _banReason);
	}

	_banningInProgress = false;

	if (!result)
	{
		console_print(id, "[SubnetBan] %L", id, "SB_BAN_FAILED");
		return;
	}

#endif // #if defined USING_SQL

	if (numResults)
		console_print(id, "[SubnetBan] %L", id, "SB_BAN_UPDATED");
	else
		console_print(id, "[SubnetBan] %L", id, "SB_BAN_INSERTED");

	// Log command usage
	new authid[32], name[32], allowedClientsStr[MAX_FLAGS + 1];
	get_flags(_banAllowedClients, allowedClientsStr, charsmax(allowedClientsStr));
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	log_amx("CmdBan: \"%s<%d><%s><>\" banned subnet: %s - %s, allowing clients: \"%s\", with reason \"%s\"", name, get_user_userid(id), authid, _banStartIpStr, _banEndIpStr, allowedClientsStr, _banReason);

	// Recheck banned player
	if (_banPlayerId)
		set_task(CHECKIP_DELAY, "CheckIp", TASK_CHECKIP_BASE + _banPlayerId);
}



//****************************************
//*                                      *
//*  Unban command                       *
//*                                      *
//****************************************

/// Format: sb_unban
/// <IP> [limit (default 1)]
/// <start IP> <end IP> [exact match (default 1)]
/// <subnet in CIDR format> [exact match (default 1)]
public CmdUnban(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	// Parse command
	new cmd[128], param[64], cmdType, bool:isRange;
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1], optionStr[2];
	read_args(cmd, charsmax(cmd));

	// First parameter
	strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
	// Try to parse CIDR format
	if (ParseCidr(param, startIpStr, charsmax(startIpStr), endIpStr, charsmax(endIpStr)))
	{
		isRange = true;
	}
	// Check if first parameter is IP or not
	else if (IsIpValid(param))
	{
		copy(startIpStr, charsmax(startIpStr), param);
		cmdType = 1;
	}
	else
	{
		console_print(id, "[SubnetBan] %L", id, "SB_INCORRECT_USAGE");
		return PLUGIN_HANDLED;
	}

	// Second parameter
	if (cmd[0] != 0)
	{
		strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
		// If first parameter is IP then check if second parameter is IP or not
		if (cmdType == 1 && IsIpValid(param))
		{
			copy(endIpStr, charsmax(endIpStr), param);
			isRange = true;
			// Get next parameter
			strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
		}

		// Limit or exact match
		if (param[0] != 0)
			copy(optionStr, charsmax(optionStr), param);
	}
	
	// By default exact match is true, so unbanning by default only exactly matching subnet
	// By default limit is true, so unbanning by default only most narrow subnet
	new bool:exactMatch = true, bool:limit = true;
	if (optionStr[0] != 0)
	{
		new option = ParseBool(optionStr);
		if (option < 0)
		{
			console_print(id, "[SubnetBan] %L", id, "SB_INCORRECT_USAGE");
			return PLUGIN_HANDLED;
		}
		exactMatch = limit = bool:option;
	}

#if defined _DEBUG
	server_print("CmdUnban: startIpStr: %s, endIpStr: %s, optionStr: %s, exactMatch: %u, limit: %u, isRange: %u", startIpStr, endIpStr, optionStr, exactMatch, limit, isRange);
#endif

	// Log command usage
	new authid[32], name[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	if (isRange)
		log_amx("CmdUnban: \"%s<%d><%s><>\" unbanning subnet: %s - %s, exact match: %u", name, get_user_userid(id), authid, startIpStr, endIpStr, exactMatch);
	else
		log_amx("CmdUnban: \"%s<%d><%s><>\" unbanning subnet: %s, limit: %u", name, get_user_userid(id), authid, startIpStr, limit);

	// Delete subnets
#if defined USING_SQL
	new data[1];
	data[0] = id;
	if (isRange)
		DeleteSubnets2("DeleteFinished", startIpStr, endIpStr, exactMatch, data, sizeof(data));
	else
		DeleteSubnets("DeleteFinished", startIpStr, limit, data, sizeof(data));

	return PLUGIN_HANDLED;
}

public DeleteFinished(failstate, Handle:query, error[], errnum, data[], dataSize)
{
	new id = data[0];

	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 05);
		console_print(id, "[SubnetBan] %L", id, "SB_UNBAN_FAILED");
		return PLUGIN_HANDLED;
	}

	new count = SQL_AffectedRows(query);

#else // #if defined USING_SQL

	new count;
	if (isRange)
		count = DeleteSubnets2(startIpStr, endIpStr, exactMatch);
	else
		count = DeleteSubnets(startIpStr, limit);

	// Break on error
	if (count < 0)
	{
		console_print(id, "[SubnetBan] %L", id, "SB_UNBAN_FAILED");
		return PLUGIN_HANDLED;
	}

#endif // #if defined USING_SQL

	// Output result
	if (count == 0)
		console_print(id, "[SubnetBan] %L", id, "SB_UNBAN_NOT_FOUND");
	else
		console_print(id, "[SubnetBan] %L", id, "SB_UNBAN_SUCCESSFULL", count);

	return PLUGIN_HANDLED;
}



//****************************************
//*                                      *
//*  List command                        *
//*                                      *
//****************************************

/// Format: sb_list
/// <IP> [limit (default 0)]
/// <start IP> <end IP> [exact match (default 0)]
/// <subnet in CIDR format> [exact match (default 0)]
public CmdList(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	// Parse command
	new cmd[128], param[64], cmdType, bool:isRange;
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1], optionStr[2];
	read_args(cmd, charsmax(cmd));

	// First parameter
	strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
	// Try to parse CIDR format
	if (ParseCidr(param, startIpStr, charsmax(startIpStr), endIpStr, charsmax(endIpStr)))
	{
		isRange = true;
	}
	// Check if first parameter is IP or not
	else if (IsIpValid(param))
	{
		copy(startIpStr, charsmax(startIpStr), param);
		cmdType = 1;
	}
	else
	{
		console_print(id, "[SubnetBan] %L", id, "SB_INCORRECT_USAGE");
		return PLUGIN_HANDLED;
	}

	// Second parameter
	if (cmd[0] != 0)
	{
		strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
		// If first parameter is IP then check if second parameter is IP or not
		if (cmdType == 1 && IsIpValid(param))
		{
			copy(endIpStr, charsmax(endIpStr), param);
			isRange = true;
			// Get next parameter
			strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
		}

		// Limit or exact match
		if (param[0] != 0)
			copy(optionStr, charsmax(optionStr), param);
	}
	
	// By default exact match is false, so list by default selecting all intersecting subnets
	// By default limit is false, so list by default selects all subnets containing given IP
	new bool:exactMatch = false, bool:limit = false;
	if (optionStr[0] != 0)
	{
		new option = ParseBool(optionStr);
		if (option < 0)
		{
			console_print(id, "[SubnetBan] %L", id, "SB_INCORRECT_USAGE");
			return PLUGIN_HANDLED;
		}
		exactMatch = limit = bool:option;
	}

#if defined _DEBUG
	server_print("CmdList: startIpStr: %s, endIpStr: %s, optionStr: %s, exactMatch: %u, limit: %u, isRange: %u", startIpStr, endIpStr, optionStr, exactMatch, limit, isRange);
#endif

	// Log command usage
	new authid[32], name[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	if (isRange)
		log_amx("CmdList: \"%s<%d><%s><>\" listing subnet: %s - %s, exact match: %u", name, get_user_userid(id), authid, startIpStr, endIpStr, exactMatch);
	else
		log_amx("CmdList: \"%s<%d><%s><>\" listing subnet: %s, limit: %u", name, get_user_userid(id), authid, startIpStr, limit);

	// Get subnets
#if defined USING_SQL
	new data[1];
	data[0] = id;
	if (isRange)
		SelectSubnets2("ListSubnetBans", startIpStr, endIpStr, exactMatch, data, sizeof(data));
	else
		SelectSubnets("ListSubnetBans", startIpStr, limit, data, sizeof(data));

	return PLUGIN_HANDLED;
}

public ListSubnetBans(failstate, Handle:query, error[], errnum, data[], dataSize)
{
	new id = data[0];

	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 06);
		console_print(id, "[SubnetBan] %L", id, "SB_SEARCH_FAILED");
		return PLUGIN_HANDLED;
	}

	new count = SQL_NumResults(query);

#else // #if defined USING_SQL

	new Array:results;
	if (isRange)
		results = SelectSubnets2(startIpStr, endIpStr, exactMatch);
	else
		results = SelectSubnets(startIpStr, limit);

	new count = ArraySize(results);

#endif // #if defined USING_SQL

	// Check results
	if (!count)
	{
		console_print(id, "[SubnetBan] %L", id, "NO_SUBNETS_FOUND");
		return PLUGIN_HANDLED;
	}

	// Output subnets
#if defined USING_SQL
	OutputSubnets(id, count, query);
#else // #if defined USING_SQL
	OutputSubnets(id, count, results);
#endif // #if defined USING_SQL

	return PLUGIN_HANDLED;
}



//****************************************
//*                                      *
//*  Search command                      *
//*                                      *
//****************************************

/// Format: sb_search
/// <reason substring>
public CmdSearch(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	// Parse command
	new cmd[128], reasonSubstr[64];
	read_args(cmd, charsmax(cmd));

	// First parameter
	strbreak(cmd, reasonSubstr, charsmax(reasonSubstr), cmd, charsmax(cmd));

#if defined _DEBUG
	server_print("CmdSearch: reasonSubstr: %s", reasonSubstr);
#endif

	// Log command usage
	new authid[32], name[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	log_amx("CmdSearch: \"%s<%d><%s><>\" searching subnets: %s", name, get_user_userid(id), authid, reasonSubstr);

	// Get subnets
#if defined USING_SQL
	// Quote string
	new Handle:sqlConnection, errorCode, error[128];
	sqlConnection = SQL_Connect(_sqlHandle, errorCode, error, charsmax(error));
	SQL_QuoteString(sqlConnection, cmd, charsmax(cmd), reasonSubstr);
	SQL_FreeHandle(sqlConnection);

	new data[1];
	data[0] = id;
	SelectSubnets3("SearchSubnetBans", cmd, data, sizeof(data));

	return PLUGIN_HANDLED;
}

public SearchSubnetBans(failstate, Handle:query, error[], errnum, data[], dataSize)
{
	new id = data[0];

	// Break on error
	if (failstate)
	{
		MySqlX_ThreadError(error, errnum, failstate, 07);
		console_print(id, "[SubnetBan] %L", id, "SB_SEARCH_FAILED");
		return PLUGIN_HANDLED;
	}

	new count = SQL_NumResults(query);

#else // #if defined USING_SQL

	new Array:results;
	results = SelectSubnets3(reasonSubstr);

	new count = ArraySize(results);

#endif // #if defined USING_SQL

	// Check results
	if (!count)
	{
		console_print(id, "[SubnetBan] %L", id, "NO_SUBNETS_FOUND");
		return PLUGIN_HANDLED;
	}

	// Output subnets
#if defined USING_SQL
	OutputSubnets(id, count, query);
#else // #if defined USING_SQL
	OutputSubnets(id, count, results);
#endif // #if defined USING_SQL

	return PLUGIN_HANDLED;
}



//****************************************
//*                                      *
//*  Whois command                       *
//*                                      *
//****************************************

/// Format: sb_whois
/// <steamID | nickname | user ID | IP>
public CmdWhois(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	// Parse command
	new cmd[128], param[64], ipStr[IP_LENGTH + 1], playerId;
	read_args(cmd, charsmax(cmd));

	// First parameter
	strbreak(cmd, param, charsmax(param), cmd, charsmax(cmd));
	// Check if parameter is IP or not
	if (IsIpValid(param))
	{
		copy(ipStr, charsmax(ipStr), param);
	}
	else
	{
		// Try to find the player to get IP from him
		playerId = LocatePlayer(id, param, false, true);
		if (playerId <= 0 || playerId >= MAX_PLAYERS)
			// Player is a BOT or has immunity (-1) or just out of boundary
			return PLUGIN_HANDLED;
		get_user_ip(playerId, ipStr, charsmax(ipStr), 1);
	}

#if defined _DEBUG
	server_print("CmdWhois: ipStr: %s", ipStr);
#endif

	// Log command usage
	new authid[32], name[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	log_amx("CmdWhois: \"%s<%d><%s><>\" ask for whois of IP: %s", name, get_user_userid(id), authid, ipStr);

	console_print(id, "[SubnetBan] %L", id, "WHOIS_QUERY_STARTING");
	Whois(id, ipStr, "", true);

	return PLUGIN_HANDLED;
}



//****************************************
//*                                      *
//*  Stat command                        *
//*                                      *
//****************************************

/// Format: sb_stat
public CmdStat(id, level, cid)
{
	// Check if the admin has the right access
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	// Log command usage
	new authid[32], name[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	log_amx("CmdStat: \"%s<%d><%s><>\" ask for players list", name, get_user_userid(id), authid);

	// Output table header
	console_print(id, "\n%L:\n #%-3s %-15.15s %-13s %-4s %-10s %-25.25s", id, "CLIENTS_ON_SERVER", 
		"uid", "name", "IP", "prot", "authprov", "country");
	console_print(id, "      %-25.25s %-32.32s", 
		"city", "netname");
	console_print(id, "      %-72.72s", 
		"description");

	// Output players' data
	new players[MAX_PLAYERS], num, ipStr[IP_LENGTH + 1], country[MAX_COUNTRY_NAME_LENGTH + 1];
	get_players(players, num);
	for (new i = 0; i < num; ++i)
	{
		get_user_name(players[i], name, charsmax(name));
		get_user_ip(players[i], ipStr, charsmax(ipStr), 1);
#if defined USING_GEOIP
		geoip_country_name_by_cc(_playerCountryCode[players[i]], country, charsmax(country));
#endif

		if (_playerAuthprov[players[i]] < sizeof(_authprovStr))
			console_print(id, "%5d %-15.15s %-15s %2u %-10s %-25.25s", 
				get_user_userid(players[i]), name, ipStr, _playerProto[players[i]], 
				_authprovStr[_playerAuthprov[players[i]]], country);
		else
			console_print(id, "%5d %-15.15s %-15s %2u %-10u %-25.25s", 
				get_user_userid(players[i]), name, ipStr, _playerProto[players[i]], 
				_playerAuthprov[players[i]], country);
		console_print(id, "      %-25.25s %-32.32s", 
			_playerCity[players[i]], _playerNetname[players[i]]);
		console_print(id, "      %-72.72s", 
			_playerDescr[players[i]]);
	}
	console_print(id, "%L", id, "TOTAL_NUM", num);

	return PLUGIN_HANDLED;
}



//****************************************
//*                                      *
//*  Output subnets to console           *
//*                                      *
//****************************************

#if defined USING_SQL
OutputSubnets(id, count, Handle:query)
#else // #if defined USING_SQL
OutputSubnets(id, count, Array:results)
#endif // #if defined USING_SQL
{
	// Output table header
	console_print(id, "\n[SubnetBan] %L\n %-15.15s %-15.15s %-5.5s %-19.19s %-19.19s", id, "SB_SEARCH_SUCCESSFULL", count, 
		"Start IP", "End IP", "Flags", "Datetime banned", "Datetime last blocked");
	console_print(id, "     %-72.72s", "Reason");

	// Iterate thru all subnets and print them
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1];
	new datetimeBannedStr[MAX_DATETIME_LENGTH + 1], datetimeLastBlockedStr[MAX_DATETIME_LENGTH + 1];
	new allowedClientsStr[MAX_FLAGS + 1], reason[MAX_REASON_LENGTH + 1];
#if defined USING_SQL
	new allowedClients, datetimeBanned, datetimeLastBlocked;
	while (SQL_MoreResults(query))
	{
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "startipstr"), startIpStr, charsmax(startIpStr));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "endipstr"), endIpStr, charsmax(endIpStr));

		allowedClients = SQL_ReadResult(query, SQL_FieldNameToNum(query, "allowedclients"));
		get_flags(allowedClients, allowedClientsStr, charsmax(allowedClientsStr));

		datetimeBanned = SQL_ReadResult(query, SQL_FieldNameToNum(query, "datetimebanned"));
		datetimeLastBlocked = SQL_ReadResult(query, SQL_FieldNameToNum(query, "datetimelastblocked"));
		format_time(datetimeBannedStr, charsmax(datetimeBannedStr), _datetimeFormat, datetimeBanned);
		format_time(datetimeLastBlockedStr, charsmax(datetimeLastBlockedStr), _datetimeFormat, datetimeLastBlocked);

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "reason"), reason, charsmax(reason));

		console_print(id, " %-15s %-15s %-5s %-19s %-19s", 
			startIpStr, endIpStr, allowedClientsStr, datetimeBannedStr, datetimeLastBlockedStr);
		if (reason[0] != 0)
			console_print(id, "    %-72.72s", reason);
		SQL_NextRow(query);
	}
#else // #if defined USING_SQL
	new banid;
	for (new i = 0; i < count; i++)
	{
		banid = ArrayGetCell(results, i);
		IpToStr(ArrayGetCell(_bansStartIps, banid), startIpStr, charsmax(startIpStr));
		IpToStr(ArrayGetCell(_bansEndIps, banid), endIpStr, charsmax(endIpStr));
		get_flags(ArrayGetCell(_bansAllowedClients, banid), allowedClientsStr, charsmax(allowedClientsStr));
		format_time(datetimeBannedStr, charsmax(datetimeBannedStr), _datetimeFormat, ArrayGetCell(_bansDatetimeBanned, banid));
		format_time(datetimeLastBlockedStr, charsmax(datetimeLastBlockedStr), _datetimeFormat, ArrayGetCell(_bansDatetimeLastBlocked, banid));
		ArrayGetString(_bansReasons, banid, reason, charsmax(reason));

		console_print(id, " %-15s %-15s %-5s %-19s %-19s", 
			startIpStr, endIpStr, allowedClientsStr, datetimeBannedStr, datetimeLastBlockedStr);
		if (reason[0] != 0)
			console_print(id, "    %-72.72s", reason);
	}
#endif // #if defined USING_SQL
	return PLUGIN_HANDLED;
}



#if defined USING_SQL

//****************************************
//*                                      *
//*  Sql queries                         *
//*                                      *
//****************************************

/// Create database if it doesn't exists.
CreateDbIfNotExists(const handler[], const data[], dataSize)
{
	new query[1024], db[128];
	get_pcvar_string(pcvar_sb_sql_db, db, charsmax(db));
	format(query, charsmax(query), "CREATE DATABASE IF NOT EXISTS `%s` DEFAULT CHARACTER SET latin1 COLLATE latin1_general_ci;", db);
#if defined _DEBUGSQL
	server_print("CreateDbIfNotExists Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandleWithoutDb, handler, query, data, dataSize);
}

/// Create table if it doesn't exists.
CreateTableIfNotExists(const handler[], const data[], dataSize)
{
	new query[1024], db[128];
	get_pcvar_string(pcvar_sb_sql_db, db, charsmax(db));
	format(query, charsmax(query), "CREATE TABLE IF NOT EXISTS `%s` (`startip` INT UNSIGNED NOT NULL, `endip` INT UNSIGNED NOT NULL, `allowedclients` SMALLINT UNSIGNED NOT NULL, `datetimebanned` INT UNSIGNED NOT NULL, `datetimelastblocked` INT UNSIGNED NOT NULL, `reason` VARCHAR(64) NOT NULL , UNIQUE `startip_endip` (`startip`, `endip`), INDEX `startip` (`startip`), INDEX `endip` (`endip`))", TABLE_SUBNETBANS);
#if defined _DEBUGSQL
	server_print("CreateTableIfNotExists Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Selects most narrow subnets (limit >= 1) or all subnets (limit == 0) that contains given IP.
SelectSubnets(const handler[], const ipStr[], limit, const data[], dataSize)
{
	new query[512], limitStr[20];
	if (limit)
		format(limitStr, charsmax(limitStr), "LIMIT %u", limit);
	format(query, charsmax(query), "SELECT startip, endip, endip - startip as rangelength, allowedclients, reason, datetimebanned, datetimelastblocked, INET_NTOA(startip) as startipstr, INET_NTOA(endip) as endipstr FROM `%s` WHERE startip <= INET_ATON('%s') AND INET_ATON('%s') <= endip ORDER BY rangelength, startip %s", TABLE_SUBNETBANS, ipStr, ipStr, limitStr);
#if defined _DEBUGSQL
	server_print("SelectSubnets Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Selects subnet exactly matching given start and end IPs (exactMatch == true).
/// Selects all subnets intersecting range given as start and end IPs (exactMatch == false).
SelectSubnets2(const handler[], const startIpStr[], const endIpStr[], bool:exactMatch, const data[], dataSize)
{
	new query[512];
	if (exactMatch)
		format(query, charsmax(query), "SELECT startip, endip, endip - startip as rangelength, allowedclients, reason, datetimebanned, datetimelastblocked, INET_NTOA(startip) as startipstr, INET_NTOA(endip) as endipstr FROM `%s` WHERE startip = INET_ATON('%s') AND INET_ATON('%s') = endip ORDER BY rangelength, startip", TABLE_SUBNETBANS, startIpStr, endIpStr);
	else
		format(query, charsmax(query), "SELECT startip, endip, endip - startip as rangelength, allowedclients, reason, datetimebanned, datetimelastblocked, INET_NTOA(startip) as startipstr, INET_NTOA(endip) as endipstr FROM `%s` WHERE endip >= INET_ATON('%s') AND INET_ATON('%s') >= startip ORDER BY rangelength, startip", TABLE_SUBNETBANS, startIpStr, endIpStr);
#if defined _DEBUGSQL
	server_print("SelectSubnets2 Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Selects all subnets that match given reason substring.
/// If reasonSubstr is empty returns subnets with empty reason.
SelectSubnets3(const handler[], const reasonSubstr[], const data[], dataSize)
{
	new query[512];
	if (reasonSubstr[0] == 0)
		format(query, charsmax(query), "SELECT startip, endip, endip - startip as rangelength, allowedclients, reason, datetimebanned, datetimelastblocked, INET_NTOA(startip) as startipstr, INET_NTOA(endip) as endipstr FROM `%s` WHERE reason = '' ORDER BY rangelength, startip", TABLE_SUBNETBANS);
	else
		format(query, charsmax(query), "SELECT startip, endip, endip - startip as rangelength, allowedclients, reason, datetimebanned, datetimelastblocked, INET_NTOA(startip) as startipstr, INET_NTOA(endip) as endipstr FROM `%s` WHERE reason LIKE '%%%s%%' ORDER BY rangelength, startip", TABLE_SUBNETBANS, reasonSubstr);
#if defined _DEBUGSQL
	server_print("SelectSubnets3 Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Inserts new subnet.
InsertSubnet(const handler[], const startIpStr[], const endIpStr[], allowedClients, const reason[], const data[], dataSize)
{
	new query[512];
	format(query, charsmax(query), "INSERT INTO `%s` (`startip`, `endip`, `allowedclients`, `reason`, `datetimebanned`, `datetimelastblocked`) VALUES (INET_ATON('%s'), INET_ATON('%s'), %u, '%s', %u, %u)", TABLE_SUBNETBANS, startIpStr, endIpStr, allowedClients, reason, get_systime(), 0);
#if defined _DEBUGSQL
	server_print("InsertSubnet Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Updates subnet.
UpdateSubnet(const handler[], const startIpStr[], const endIpStr[], allowedClients, const reason[], bool:updateBlockDatetime, const data[], dataSize)
{
	new query[512];
	if (updateBlockDatetime)
		format(query, charsmax(query), "UPDATE `%s` SET `allowedclients` = %u, `reason` = '%s', `datetimelastblocked` = %u WHERE `startip` = INET_ATON('%s') AND `endip` = INET_ATON('%s') LIMIT 1", TABLE_SUBNETBANS, allowedClients, reason, get_systime(), startIpStr, endIpStr);
	else
		format(query, charsmax(query), "UPDATE `%s` SET `allowedclients` = %u, `reason` = '%s' WHERE `startip` = INET_ATON('%s') AND `endip` = INET_ATON('%s') LIMIT 1", TABLE_SUBNETBANS, allowedClients, reason, startIpStr, endIpStr);
#if defined _DEBUGSQL
	server_print("UpdateSubnet Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Deletes most narrow subnets (limit >= 1) or all subnets (limit == 0) that contains given IP.
DeleteSubnets(const handler[], const ipStr[], bool:limit, const data[], dataSize)
{
	new query[512], limitStr[20];
	if (limit)
		format(limitStr, charsmax(limitStr), "LIMIT %u", limit);
	format(query, charsmax(query), "DELETE FROM `%s` WHERE startip <= INET_ATON('%s') AND INET_ATON('%s') <= endip ORDER BY endip - startip, startip %s", TABLE_SUBNETBANS, ipStr, ipStr, limitStr);
#if defined _DEBUGSQL
	server_print("DeleteSubnets Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}

/// Deletes subnet exactly matching given start and end IPs (exactMatch == true).
/// Deletes all subnets intersecting range given as start and end IPs (exactMatch == false).
DeleteSubnets2(const handler[], const startIpStr[], const endIpStr[], bool:exactMatch, const data[], dataSize)
{
	new query[512];
	if (exactMatch)
		format(query, charsmax(query), "DELETE FROM `%s` WHERE startip = INET_ATON('%s') AND INET_ATON('%s') = endip", TABLE_SUBNETBANS, startIpStr, endIpStr);
	else
		format(query, charsmax(query), "DELETE FROM `%s` WHERE endip >= INET_ATON('%s') AND INET_ATON('%s') >= startip", TABLE_SUBNETBANS, startIpStr, endIpStr);
#if defined _DEBUGSQL
	server_print("DeleteSubnets2 Sql Query:");
	PrintLongText(0, query);
#endif
	SQL_ThreadQuery(_sqlHandle, handler, query, data, dataSize);
}



//****************************************
//*                                      *
//*  Sql Error handler                   *
//*                                      *
//****************************************

/// Logs sql error information.
MySqlX_ThreadError(error[], errnum, failstate, location)
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED:	log_amx("%L", LANG_SERVER, "SQLCONNECTION_FAILED");
		case TQUERY_QUERY_FAILED:	log_amx("%L", LANG_SERVER, "SQLQUERY_FAILED");
		case TQUERY_SUCCESS:		return;
	}
	log_amx("%L", LANG_SERVER, "SQLQUERY_ERROR", location);
	log_amx("%L", LANG_SERVER, "SQLQUERY_MSG", error, errnum);
}

#else // #if defined USING_SQL



//****************************************
//*                                      *
//*  File storage                        *
//*                                      *
//****************************************

/// Loads banned subnets from file into dynamic arrays.
bool:LoadBannedSubnets()
{
	new file = fopen(_subnetBanFile, "rt");

	if (!file)
	{
		// Create empty file and return
		file = fopen(_subnetBanFile, "wt");
		if (!file) return false;
		fputs(file, "// <Start IP> <End IP> <Allowed Clients (flags)> <Ban Datetime> <Datetime of last blocked connection> \"<Reason>\"\n");
		fclose(file);
		return true;
	}

	// Read banned subnets
	new line[256], startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1], allowedClientsStr[MAX_FLAGS + 1];
	new reason[MAX_REASON_LENGTH], datetimeBannedStr[MAX_DATETIME_LENGTH + 1], datetimeLastBlockedStr[MAX_DATETIME_LENGTH + 1];
	while (!feof(file))
	{
		fgets(file, line, charsmax(line));

		// Skip empty lines and comments
		if (line[0] == 0 || line[0] == '/' || line[0] == ';') continue;

		// Parse line
		parse(line, 
			startIpStr, charsmax(startIpStr), 
			endIpStr, charsmax(endIpStr), 
			allowedClientsStr, charsmax(allowedClientsStr), 
			datetimeBannedStr, charsmax(datetimeBannedStr), 
			datetimeLastBlockedStr, charsmax(datetimeLastBlockedStr), 
			reason, charsmax(reason));
		
		ArrayPushCell(_bansStartIps, ParseIp(startIpStr));
		ArrayPushCell(_bansEndIps, ParseIp(endIpStr));
		ArrayPushCell(_bansAllowedClients, read_flags_fixed(allowedClientsStr) & 65535);
		ArrayPushCell(_bansDatetimeBanned, parse_time(datetimeBannedStr, _datetimeFormat));
		ArrayPushCell(_bansDatetimeLastBlocked, parse_time(datetimeLastBlockedStr, _datetimeFormat));
		ArrayPushString(_bansReasons, reason);

		_bansCount++;
#if defined _DEBUG
		server_print("LoadBannedSubnets: %s - %s, %u, %s", startIpStr, endIpStr, read_flags_fixed(allowedClientsStr) & 65535, reason);
#endif
	}
	
	fclose(file);
	return true;
}

/// Saves banned subnets from dynamic arrays into file.
bool:SaveBannedSubnets(bool:backup)
{
	// Backup old file
	if (backup)
	{
		new bakName[MAX_FILE_NAME_LENGTH + 1];
		format(bakName, charsmax(bakName), "%s.bak", _subnetBanFile);
		delete_file(bakName);
		rename_file(_subnetBanFile, bakName, 1);
	}

	// Open new file for writing
	new file = fopen(_subnetBanFile, "wt");
	if (!file) return false;

	fputs(file, "// <Start IP> <End IP> <Allowed Clients (flags)> <Ban Datetime> <Datetime of last blocked connection> \"<Reason>\"\n");

	// Write banned subnets
	new startIpStr[IP_LENGTH + 1], endIpStr[IP_LENGTH + 1], allowedClientsStr[MAX_FLAGS + 1];
	new datetimeBannedStr[MAX_DATETIME_LENGTH + 1], datetimeLastBlockedStr[MAX_DATETIME_LENGTH + 1];
	for (new i = 0; i < _bansCount; i++)
	{
		IpToStr(ArrayGetCell(_bansStartIps, i), startIpStr, charsmax(startIpStr));
		IpToStr(ArrayGetCell(_bansEndIps, i), endIpStr, charsmax(endIpStr));
		get_flags(ArrayGetCell(_bansAllowedClients, i), allowedClientsStr, charsmax(allowedClientsStr));
		format_time(datetimeBannedStr, charsmax(datetimeBannedStr), _datetimeFormat, ArrayGetCell(_bansDatetimeBanned, i));
		format_time(datetimeLastBlockedStr, charsmax(datetimeLastBlockedStr), _datetimeFormat, ArrayGetCell(_bansDatetimeLastBlocked, i));

		fprintf(file, "%s %s %s \"%s\" \"%s\" \"%a\"\n", startIpStr, endIpStr, allowedClientsStr, 
			datetimeBannedStr, datetimeLastBlockedStr, ArrayGetStringHandle(_bansReasons, i));
	}
	
	fclose(file);
	return true;
}



//****************************************
//*                                      *
//*  Dynamic arrays functions            *
//*                                      *
//****************************************

/// Sorts first given array ascending with order given in second array.
/// Returns sorted array truncated to be less or equal to limit.
/// "min" parameter should contain 
Array:ArraySortByArray(Array:data, Array:order, min, limit)
{
	new Array:results = ArrayCreate(1);
	new minNext = -1;
	for (new i = 0; i < ArraySize(data); i++)
	{
		for (new j = 0; j < ArraySize(data); j++)
		{
			new rangeLength = ArrayGetCell(order, j);
			if (CompareUnsigned(rangeLength, min) <= 0)
			{
				// Current length is less or equal to min length. Move to results
				new banid = ArrayGetCell(data, j);
				ArrayDeleteItem(data, j);
				ArrayDeleteItem(order, j);
				j--;
				i--;
				ArrayPushCell(results, banid);
				if (limit != 0 && ArraySize(results) >= limit)
					return results;
			}
			else
			{
				// Current length is more then min length. Test for next min length
				if (CompareUnsigned(minNext, rangeLength) > 0)
					minNext = rangeLength;
			}
		}
		min = minNext;
		minNext = -1;
	}
	return results;
}

/// Callback for sorting array of ints ascending.
/// Compares 2 items from array.
public SortCellsAscending(Array:arrayToSort, item1, item2)
{
	new a = ArrayGetCell(arrayToSort, item1);
	new b = ArrayGetCell(arrayToSort, item2);
	return CompareUnsigned(a, b);
}



//****************************************
//*                                      *
//*  Queries for bans in dynamic arrays  *
//*                                      *
//****************************************

/// Selects most narrow subnets (limit >= 1) or all subnets (limit == 0) that contains given IP.
/// Returns dynamic array with selected subnets numbers.
Array:SelectSubnets(const ipStr[], limit)
{
	new Array:foundSubnets = ArrayCreate(1);
	new Array:foundSubnetsLength = ArrayCreate(1);

	// Seek for subnets containing given IP
	new testStartIp, testEndIp;
	new ip = ParseIp(ipStr);
	new minLength = -1;
	for (new i = 0; i < _bansCount; i++)
	{
		// Check if range contains given IP
		testStartIp = ArrayGetCell(_bansStartIps, i);
		testEndIp = ArrayGetCell(_bansEndIps, i);
		if (CompareUnsigned(testStartIp, ip) <= 0 &&
			CompareUnsigned(testEndIp, ip) >= 0)
		{
			new rangeLength = testEndIp - testStartIp;
			ArrayPushCell(foundSubnets, i);
			ArrayPushCell(foundSubnetsLength, rangeLength);
			if (CompareUnsigned(minLength, rangeLength) > 0)
				minLength = rangeLength;
		}
	}

	// Sort and return found subnets
	return ArraySortByArray(foundSubnets, foundSubnetsLength, minLength, limit);
}

/// Selects subnet exactly matching given start and end IPs (exactMatch == true).
/// Selects all subnets intersecting range given as start and end IPs (exactMatch == false).
/// Returns dynamic array with selected subnets numbers.
Array:SelectSubnets2(const startIpStr[], const endIpStr[], bool:exactMatch)
{
	new Array:foundSubnets = ArrayCreate(1);
	new Array:foundSubnetsLength = ArrayCreate(1);

	// Seek for subnets containing given IP
	new testStartIp, testEndIp;
	new startIp = ParseIp(startIpStr);
	new endIp = ParseIp(endIpStr);
	new minLength = -1;
	for (new i = 0; i < _bansCount; i++)
	{
		// Check if range contains given IP
		testStartIp = ArrayGetCell(_bansStartIps, i);
		testEndIp = ArrayGetCell(_bansEndIps, i);
		if ((exactMatch && testStartIp == startIp && testEndIp == endIp) ||
			(!exactMatch && 
			CompareUnsigned(testStartIp, endIp) <= 0 &&
			CompareUnsigned(testEndIp, startIp) >= 0))
		{
			new rangeLength = testEndIp - testStartIp;
			ArrayPushCell(foundSubnets, i);
			ArrayPushCell(foundSubnetsLength, rangeLength);
			if (CompareUnsigned(minLength, rangeLength) > 0)
				minLength = rangeLength;
		}
	}

	// Sort and return found subnets
	return ArraySortByArray(foundSubnets, foundSubnetsLength, minLength, 0);
}

/// Selects all subnets that contains given reason substring.
/// If reasonSubstr is empty returns subnets with empty reason.
/// Returns dynamic array with selected subnets numbers.
Array:SelectSubnets3(const reasonSubstr[])
{
	new Array:foundSubnets = ArrayCreate(1);
	new Array:foundSubnetsLength = ArrayCreate(1);

	// Seek for subnets with specified reason substring
	new reason[64];
	new testStartIp, testEndIp;
	new minLength = -1;
	for (new i = 0; i < _bansCount; i++)
	{
		// Check if reason contains given substring
		ArrayGetString(_bansReasons, i, reason, charsmax(reason));
		if (containi(reason, reasonSubstr) >= 0)
		{
			testStartIp = ArrayGetCell(_bansStartIps, i);
			testEndIp = ArrayGetCell(_bansEndIps, i);
			new rangeLength = testEndIp - testStartIp;
			ArrayPushCell(foundSubnets, i);
			ArrayPushCell(foundSubnetsLength, rangeLength);
			if (CompareUnsigned(minLength, rangeLength) > 0)
				minLength = rangeLength;
		}
	}

	// Sort and return found subnets
	return ArraySortByArray(foundSubnets, foundSubnetsLength, minLength, 0);
}

/// Inserts new subnet.
/// Returns true on success saving and false otherwise.
bool:InsertSubnet(const startIpStr[], const endIpStr[], allowedClients, const reason[])
{
	ArrayPushCell(_bansStartIps, ParseIp(startIpStr));
	ArrayPushCell(_bansEndIps, ParseIp(endIpStr));
	ArrayPushCell(_bansAllowedClients, allowedClients & 65535);
	ArrayPushCell(_bansDatetimeBanned, get_systime());
	ArrayPushCell(_bansDatetimeLastBlocked, 0);
	ArrayPushString(_bansReasons, reason);

	_bansCount++;
	// Save bans and return
	return SaveBannedSubnets(false);
}

/// Updates subnet.
/// Returns true on success saving and false otherwise.
bool:UpdateSubnet(banid, allowedClients, const reason[], bool:updateBlockDatetime)
{
	if (banid >= _bansCount)
		return false;

	ArraySetCell(_bansAllowedClients, banid, allowedClients & 65535);
	ArraySetString(_bansReasons, banid, reason);
	if (updateBlockDatetime)
		ArraySetCell(_bansDatetimeLastBlocked, banid, get_systime());
	// Save bans and return
	return SaveBannedSubnets(false);
}

/// Deletes most narrow subnets (limit >= 1) or all subnets (limit == 0) that contains given IP.
/// Returns count of deleted subnets on success saving and -1 otherwise.
DeleteSubnets(const ipStr[], bool:limit)
{
	// Get subnets to delete
	new Array:subnetsToDelete = SelectSubnets(ipStr, limit);
	return DeleteSubnetsArray(subnetsToDelete);
}

/// Deletes subnet exactly matching given start and end IPs (exactMatch == true).
/// Deletes all subnets intersecting range given as start and end IPs (exactMatch == false).
/// Returns count of deleted subnets on success saving and -1 otherwise.
DeleteSubnets2(const startIpStr[], const endIpStr[], bool:exactMatch)
{
	// Get subnets to delete
	new Array:subnetsToDelete = SelectSubnets2(startIpStr, endIpStr, exactMatch);
	return DeleteSubnetsArray(subnetsToDelete);
}

/// Deletes subnet given in array containing subnets numbers.
/// Returns count of deleted subnets on success saving and -1 otherwise.
DeleteSubnetsArray(Array:subnetsToDelete)
{
	new count = ArraySize(subnetsToDelete);
	if (count == 0)
		return 0;
	// Sort them in ascending order
	ArraySort(subnetsToDelete, "SortCellsAscending");
	// Perfom deletion
	new banid;
	for (new i = 0; i < count; i++)
	{
		banid = ArrayGetCell(subnetsToDelete, i) - i;
		ArrayDeleteItem(_bansStartIps, banid);
		ArrayDeleteItem(_bansEndIps, banid);
		ArrayDeleteItem(_bansAllowedClients, banid);
		ArrayDeleteItem(_bansDatetimeBanned, banid);
		ArrayDeleteItem(_bansDatetimeLastBlocked, banid);
		ArrayDeleteItem(_bansReasons, banid);
		_bansCount--;
	}
	// Save bans and return
	new bool:saved = SaveBannedSubnets(true);
	if (!saved)
		return -1;
	return count;
}

#endif // #if defined USING_SQL



//****************************************
//*                                      *
//*  Other functions                     *
//*                                      *
//****************************************

get_sb_allowed_flags()
{
	new flags[27];
	get_pcvar_string(pcvar_sb_allowed_flags, flags, charsmax(flags));
	return read_flags_fixed(flags);
}

get_sb_def_allowed_clients()
{
	new flags[27];
	get_pcvar_string(pcvar_sb_def_allowed_clients, flags, charsmax(flags));
	return read_flags_fixed(flags);
}

get_sb_download_ct()
{
	new flags[27];
	get_pcvar_string(pcvar_sb_download_ct, flags, charsmax(flags));
	trim(flags);
	flags[1] = 0;
	return read_flags_fixed(flags);
}

/// Find player index based on Steam ID or partial player name or user IP or used ID.
/// If player not found or multiple players found returns -1.
/// If player has immunity and "checkImmunity" parameter is true then function returns -1.
/// If player is bot and "checkBot" parameter is true then function returns -1.
/// Returns player index on success and -1 othewise.
/// Remark: this function outputs information in console on unsuccess.
stock LocatePlayer(id, identStr[], bool:checkImmunity, bool:checkBot)
{
	new player, player1[4], player2[4];
	// Find based on steam ID
	player1[0] = find_player("c", identStr);
	player2[0] = find_player("cj", identStr);

	// Find based on a partial non-case sensitive name
	player1[1] = find_player("bl", identStr);
	player2[1] = find_player("blj", identStr);

	// Find based on IP address
	player1[2] = find_player("d", identStr);
	player2[2] = find_player("dj", identStr);

	// Find based on user ID
	if (identStr[0]=='#' && identStr[1])
		player1[3] = player2[3] = find_player("k", str_to_num(identStr[1]));

	// Check if multiple players found
	for (new i = 0; i < 4; i++)
	{
		if (player1[i] != 0)
		{
			if ((player != 0 && player != player1[i]) || player1[i] != player2[i])
			{
				console_print(id, "[%s] %L.", PLUGIN_TAG, id, "MORE_CL_MATCHT", identStr);
				return -1;
			}
			player = player1[i];
		}
	}

	// Check if player not found
	if (!player)
	{
		console_print(id, "[%s] %L.", PLUGIN_TAG, id, "CL_NOT_FOUND");
		return -1;
	}

	// Check for immunity
	if (checkImmunity && get_user_flags(player) & ADMIN_IMMUNITY)
	{
		new name[32];
		get_user_name(player, name, charsmax(name));
		console_print(id, "[%s] %L.", PLUGIN_TAG, id, "CLIENT_IMM", name);
		return -1;
	}

	// Check for a bot
	if (checkBot && is_user_bot(player))
	{
		new name[32];
		get_user_name(player, name, charsmax(name));
		console_print(id, "[%s] %L.", PLUGIN_TAG, id, "CANT_PERF_BOT", name);
		return -1;
	}

	return player;
}

/// Tries parse char as bool.
/// Returns 1 on yes and 0 on no.
/// If value is not detected as right bool then return -1.
ParseBool(const value[])
{
	if (value[0] == 0)
		return -1;
	if (value[0] == '0' || value[0] == 'n' || value[0] == '-')
		return false;
	else
	if (value[0] == '1' || value[0] == 'y' || value[0] == '+')
		return true;
	return -1;
}

stock isClientSet(clients, authprov)
{
	return (clients & (1 << (authprov - 1)));
}
