/* GeoIP module functions for AMX Mod X
   by David "BAILOPAN" Anderson
   (C)Copyrighted under the GNU General Public License, Version 2
 */

#if defined geoipmax_included
  #endinput
#endif
#define _geoipmax_included

#if AMXX_VERSION_NUM >= 175
 #pragma reqlib geoipmax
 #if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib geoipmax
 #endif
#else
 #pragma library geoipmax
#endif

/// IP addresses passed to these natives can contain ports, the ports will be ignored.

/**
 * @deprecated
 * Lookup the two character country code for a given IP address.
 *
 * @note This native will overflow the buffer by one cell on an unknown ip lookup!
 * @note Use geoip_code2_ex instead!
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.
 */
native geoip_code2(const ip[], ccode[3]);

/**
 * @deprecated
 * Lookup the three character country code for a given IP address.
 *
 * @note This native will overflow the buffer by one cell on an unknown ip lookup!
 * @note Use geoip_code3_ex instead!
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.
 */
native geoip_code3(const ip[], result[4]);

/**
 * @deprecated
 * Lookup the full country name for the given IP address.  Sets the buffer to "error" on
 * an unsuccessful lookup.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result of the geoip lookup.
 * @param len		The maximum length of the result buffer.
 */
native geoip_country(const ip[], result[], len);




/**
 * Lookup the two character country code for a given IP address.
 * e.g: "US", "CA", etc.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer is not modified.
 * @return			true on a successful lookup, false on a failed lookup.
 */
native bool:geoip_code2_ex(const ip[], result[3]);

/**
 * Lookup the three character country code for a given IP address.
 * e.g: "USA", "CAN", etc.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer is not modified.
 * @return			true on a successful lookup, false on a failed lookup.
 */
native bool:geoip_code3_ex(const ip[], result[4]);




/**
 * Lookup the two character country code for a given IP address.
 * e.g: "US", "CA", etc.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer will contain "--".
 * @return			true on a successful lookup, false on a failed lookup.
 */
native bool:geoip_country_code2(const ip[], result[3]);

/**
 * Lookup the three character country code for a given IP address.
 * e.g: "USA", "CAN", etc.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer will contain "--".
 * @return			true on a successful lookup, false on a failed lookup.
 */
native bool:geoip_country_code3(const ip[], result[4]);

/**
 * Lookup the full country name for the given IP address.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer will contain "N/A".
 * @param len		The maximum length of the result buffer.
 * @return			true on a successful lookup, false on a failed lookup.
 */
native geoip_country_name(const ip[], result[], len);

/**
 * Lookup the full country name for the given two character country code.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer will contain "N/A".
 * @param len		The maximum length of the result buffer.
 * @return			true on a successful lookup, false on a failed lookup.
 */
native geoip_country_name_by_cc(const cc[], result[], len);

/**
 * Lookup the region name for the given IP address.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer will contain "N/A".
 * @param len		The maximum length of the result buffer.
 * @return			true on a successful lookup, false on a failed lookup.
 */
native geoip_region_name(const ip[], result[], len);

/**
 * Lookup the city name for the given IP address.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result buffer.  If the lookup does not succeed, the buffer will contain "N/A".
 * @param len		The maximum length of the result buffer.
 * @return			true on a successful lookup, false on a failed lookup.
 */
native geoip_city_name(const ip[], result[], len);

/**
 * Lookup the city's coordinates for the given IP address.
 *
 * @param ip			The IP address to lookup.
 * @param latitude		latitude passed by ref. If the lookup does not succeed, will contain 0.
 * @param longitude		longitude passed by ref. If the lookup does not succeed, will contain 0.
 * @return				true on a successful lookup, false on a failed lookup.
 */
native geoip_coords(const ip[], &Float:lat, &Float:lng);

/**
 * Lookup IP range for the given IP address.
 *
 * @param ip			The IP address to lookup.
 * @param start_ip		The start IP buffer.  If the lookup does not succeed, the buffer will contain "".
 * @param start_ip_len	The maximum length of the start IP buffer.
 * @param end_ip		The end IP buffer.  If the lookup does not succeed, the buffer will contain "".
 * @param end_ip_len	The maximum length of the end IP buffer.
 * @return				true on a successful lookup, false on a failed lookup.
 */
native geoip_range(const ip[], start_ip[], start_ip_len, end_ip[], end_ip_len);

/**
 * Lookup GeoIP information about given IP address.
 *
 * @param ip				The IP address to lookup.
 * @param country_code2		The two digit country code. If the lookup does not succeed, the buffer will contain "--".
 * @param country_code3		The three digit country code. If the lookup does not succeed, the buffer will contain "--".
 * @param country_name		The country name buffer. If the lookup does not succeed, the buffer will contain "N/A".
 * @param country_name_len	The maximum length of the country name buffer.
 * @param region_name		The region name buffer. If the lookup does not succeed, the buffer will contain "N/A".
 * @param region_name_len	The maximum length of the region name buffer.
 * @param city_name			The city name buffer. If the lookup does not succeed, the buffer will contain "N/A".
 * @param city_name_len		The maximum length of the city name buffer.
 * @param latitude			Latitude passed by ref. If the lookup does not succeed, will contain 0.
 * @param longitude			Longitude passed by ref. If the lookup does not succeed, will contain 0.
 * @param start_ip			The start IP buffer. If the lookup does not succeed, the buffer will contain "".
 * @param start_ip_len		The maximum length of the start IP buffer.
 * @param end_ip			The end IP buffer. If the lookup does not succeed, the buffer will contain "".
 * @param end_ip_len		The maximum length of the end IP buffer.
 * @return					true on a successful lookup, false on a failed lookup.
 */
native geoip_fullinfo(const ip[], country_code2[3], country_code3[4], country_name[], country_name_len, region_name[], region_name_len, city_name[], city_name_len, &Float:latitude, &Float:longitude, start_ip[], start_ip_len, end_ip[], end_ip_len);
