/*	AMX Mod X script.

	Common functions by Lev.

	Version 1.0
*/

#if defined common_functions_inl
  #endinput
#endif
#define common_functions_inl

#define MAX_PLAYERS		32

/// Outputs long text in console.
stock PrintLongText(id, text[])
{
	new maxLineLen = 79;
	new len = strlen(text);
	// Print lines while left size is more than maxLineLen
	new pos, lineEnd, lineLen, c;
	while (pos + maxLineLen < len)
	{
		lineEnd = strfind(text[pos], "\n");
		lineLen = lineEnd >= 0 && lineEnd < maxLineLen ? lineEnd : maxLineLen;
		lineEnd = pos + lineLen;
		c = text[lineEnd];
		text[lineEnd] = 0;
		console_print(id, "%s", text[pos]);
		text[lineEnd] = c;
		pos = lineEnd;
		if (c == '\n') pos++;
		if (text[pos] == '\r') pos++;
	}
    // Print last line
	console_print(id, "%s", text[pos]);
}

/// Converts string of flags into int.
/// Only chars from 'a' to 'z' are converted, others are skipped.
stock read_flags_fixed(const flags[])
{
	new result, i = 0;
	while (flags[i] != 0)
	{
		if (flags[i] >= 'a' && flags[i] <= 'z')
			result |= 1 << (flags[i] - 'a');
		i++;	
	}
	return result;
}

/// Compare two integes as unsigned.
/// Retruns:
/// -1 if first is smaller than second;
///  0 if first is equal to second;
///  1 if first is greater than second.
stock CompareUnsigned(first, second)
{
	if (first == second)
		return 0;
	new bool:highFirst, bool:highSecond;
	if (first < 0)
	{
		highFirst = true;
		first = first & (~(1 << 31));
	}
	if (second < 0)
	{
		highSecond = true;
		second = second & (~(1 << 31));
	}
	if (highFirst && !highSecond)
		return 1;
	if (!highFirst && highSecond)
		return -1;
	if (first > second)
		return 1;
	return -1;
}

/// Plays given sound for all players excluding bots.
stock PlaySoundForAll(const snd[], excludePlayer)
{
	if (snd[0] == 0)
		return;
	new players[MAX_PLAYERS], num;
	get_players(players, num);
	for (new i = 0; i < num; i++)
	{
		new id = players[i];
		if (!is_user_bot(id) && id != excludePlayer)
			client_cmd(id, "spk %s", snd);
	}
}
