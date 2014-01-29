/*	AMX Mod X script.

	IP functions by Lev.

	Version 1.1
*/

#if defined ip_functions_inl
  #endinput
#endif
#define ip_functions_inl

#include "inline/common_functions.inl"

#define IP_LENGTH 15

/// Parses subnet in CIDR format given in "subnetCidr" parameter.
/// and place starting IP in "startIpStr" parameter and ending IP in "endIpStr" parameter.
/// Returns true on success and false otherwise.
stock bool:ParseCidr(const subnetCidr[], startIpStr[], startIpStrLen, endIpStr[], endIpStrLen)
{
	new left[IP_LENGTH + 1], right[IP_LENGTH + 1];
	strtok(subnetCidr, left, charsmax(left), right, charsmax(right), '/');
	trim(left);
	if (!IsIpValid(left, true) || !right[0])
		return false;
	new mask = str_to_num(right);
	if (mask < 0 || mask > 32)
		return false;
	if (mask == 32)
	{
		trim(left);
		copy(startIpStr, startIpStrLen, left);
		copy(endIpStr, endIpStrLen, left);
		return true;
	}
	new ip = ParseIp(left);
	if (mask != 0)
		mask = (1 << 31) >> (mask - 1);
	new startIp = ip & mask;
	new endIp = ip | (~mask);

	IpToStr(startIp, startIpStr, startIpStrLen);
	IpToStr(endIp, endIpStr, endIpStrLen);
	return true;
}

/// Calculates range length for given starting and ending IPs.
/// Note: It returns 0 if range is "0.0.0.0" - "255.255.255.255".
stock CalcRangeLength(const startIpStr[], const endIpStr[])
{
	new startIp = ParseIp(startIpStr);
	new endIp = ParseIp(endIpStr);
	new rangeLength = endIp - startIp + 1;
	return rangeLength;
}

/// Checks if given IP is valid.
/// If shortForm is true then short form of IP is also valid (for example: 12.24.6).
stock bool:IsIpValid(const ipStr[], bool:shortForm = false)
{
	new i, ip[IP_LENGTH + 1], part[4], count = 0;
	strtok(ipStr, part, charsmax(part), ip, charsmax(ip), '.');
	while (part[0] != 0)
	{
		i = str_to_num(part);
		if (i < 0 || i > 255)
			return false;
		count++;
		strtok(ip, part, charsmax(part), ip, charsmax(ip), '.');
	}
	return shortForm ? count <= 4 : count == 4;
}

/// Converts string representation of IP to int.
/// String should contain a valid IP without space characters.
/// Short form of IP is also ok (for example: 12.24.6).
stock ParseIp(const ipStr[])
{
	new right[IP_LENGTH + 1], part[4];
	strtok(ipStr, part, charsmax(part), right, charsmax(right), '.');
	new ip = 0, octet;
	for (new i = 0; i < 4; i++)
	{
		octet = str_to_num(part);
		if (octet < 0) octet = 0;
		if (octet > 255) octet = 255;
		ip += octet;
		if (i == 3) break;
		strtok(right, part, charsmax(part), right, charsmax(right), '.');
		ip = ip << 8;
	}
	return ip;
}

/// Converts int to string representation of IP.
stock IpToStr(ip, ipStr[], ipStrLen)
{
	new octet[4], bool:high;
	if (ip < 0)
	{
		high = true;
		ip = ip & (~(1 << 31));
	}
	for (new i = 0; i < 4; i++)
	{
		octet[i] = ip & 255;
		ip = ip >> 8;
	}
	if (high) octet[3] += 128;
	format(ipStr, ipStrLen, "%i.%i.%i.%i", octet[3], octet[2], octet[1], octet[0]);
}
