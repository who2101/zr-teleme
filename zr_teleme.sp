#pragma semicolon 1
#pragma newdecls required

#include <multicolors>
#include <sdktools>

ConVar hCvar[2];
bool bInfect;
float iInfectTime;

int iUses[MAXPLAYERS + 1],
	iMaxUses;
	
#define VERSION 1.0

public Plugin myinfo = {
	name = "[ZR] TeleME",
	author = "who",
	version = VERSION,
	url = "https://github.com/who2101/zr-teleme"
};

public void OnPluginStart() {
	LoadTranslations("zr_teleme.phrases.txt");
	
	hCvar[0] = CreateConVar("zr_teleme_count", "1");
	iMaxUses = hCvar[0].IntValue;
	hCvar[0].AddChangeHook(OnChangeUses);

	RegConsoleCmd("sm_teleme", Command);

	hCvar[1] = FindConVar("zr_infect_spawntime_min");
	
	if(!hCvar[1])
		SetFailState("Zombie Reloaded is not loaded");

	iInfectTime = hCvar[1].FloatValue;
	hCvar[1].AddChangeHook(OnChangeTime);

	HookEvent("round_start", OnRoundStart);
}

public void OnChangeTime(ConVar cvar, const char[] oldValue, const char[] newValue) {
	iInfectTime = StringToFloat(newValue);
}

public void OnChangeUses(ConVar cvar, const char[] oldValue, const char[] newValue) {
	iMaxUses = StringToInt(newValue);
}

public void OnClientPutInServer(int client) {
	iUses[client] = 0;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	bInfect = false;

	CreateTimer(iInfectTime, Timer_CB, TIMER_FLAG_NO_MAPCHANGE);

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) iUses[i] = 0;
}

public Action Timer_CB(Handle timer) {
	bInfect = true;
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
			CPrintToChat(i, "%t %t", "Prefix", "UnlockTeleport");
	
	return Plugin_Stop;
}

void ShowMenu(int client) {
	Menu menu = new Menu(Menu_Handler);
	
	char title[72];
	FormatEx(title, sizeof(title), "%T", "MenuTitle", client);
	menu.SetTitle(title);

	char name[MAX_NAME_LENGTH], userid[8];

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && i != client) {
			GetClientName(i, name, MAX_NAME_LENGTH);
			
			IntToString(GetClientUserId(i), userid, 8);
			menu.AddItem(userid, name);
		}
	}
	
	if(!menu.ItemCount) {
		CPrintToChat(client, "%t %t", "Prefix", "NoHumans");

		return;
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Handler(Menu menu, MenuAction action, int param, int param2) {
	if(action == MenuAction_Select) {
		if(!bInfect) {
			CPrintToChat(param, "%t %t", "Prefix", "BeforeInfect");

			return 0;
		}
		
		if(GetClientTeam(param) != 3) {
			CPrintToChat(param, "%t %t", "Prefix", "OnlyHuman");
		
			return 0;
		}
		
		char item[32];
		menu.GetItem(param2, item, sizeof(item));
		
		int target = GetClientOfUserId(StringToInt(item));
		
		if(GetClientTeam(target) != 3) {
			CPrintToChat(param, "%t %t", "Prefix", "IsZombie");

			ShowMenu(param);
			
			return 0;
		}
		
		float vec[3];
		GetClientAbsOrigin(target, vec);
		TeleportEntity(param, vec, NULL_VECTOR, NULL_VECTOR);
		
		CPrintToChat(param, "%t %t", "Prefix", "ToClient", target);
		CPrintToChat(target, "%t %t", "Prefix", "ToTarget", param);
		
		iUses[param]++;
	}
	if(action == MenuAction_End)
		delete menu;
		
	return 0;
}

public Action Command(int client, int args) {
	if(!bInfect) {
		CPrintToChat(client, "%t %t", "Prefix", "BeforeInfect");
		
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) != 3) {
		CPrintToChat(client, "%t %t", "Prefix", "OnlyHuman");
		
		return Plugin_Handled;
	}
	
	if(iUses[client] >= iMaxUses) {
		CPrintToChat(client, "%t %t", "Prefix", "MaxUses", iUses[client], iMaxUses);
		
		return Plugin_Handled;
	}
	
	ShowMenu(client);
	
	return Plugin_Handled;
}
