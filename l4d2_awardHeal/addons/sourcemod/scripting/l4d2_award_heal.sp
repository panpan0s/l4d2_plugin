#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <pan0s>

#pragma newdecls required

/*
Index:
0. 	reviver hp
1. 	reviver buffer hp
2. 	revived hp
3. 	revived buffer hp
4.	rescuer hp
5.	rescuer buffer hp
6.	rescued hp
7.	rescued buffer hp
8.	pill hp
9.	pill buffer hp
10.	adrenaline hp
11.	adrenaline buffer hp
12.	medkit healer hp
13.	medkit healer buffer hp
14.	medkit healed buffer hp
15.	medkit healed buffer hp
16.	defibrillator hp
17.	defibrillator buffer hp
18.	defibrillated hp
19.	defibrillated buffer hp
20.	Incapacitated hp
*/

ConVar cvar_awards[21];

ConVar cvar_player_max_hp;
ConVar cvar_player_max_all_hp;

ConVar cvar_awarad_message;

public Plugin myinfo = {
	name = "l4d2_award_Heal",
	description = "Award health for different events.",
	author = "pan0s",
	version = "2.1",
	url = "https://github.com/panpan0s/l4d2_plugin"
};

public void OnPluginStart(){
	LoadTranslations("l4d2_award_heal.phrases");
	RegAdminCmd("sm_hp2", HandleCmdRHp2, ADMFLAG_KICK);
	
	cvar_awards[0] = CreateConVar("award_reviver_hp","5","How many HP reward to player who helped Incapaciated player. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[1] = CreateConVar("award_reviver_buffer","0","How many HP reward to player who helped Incapaciated player. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[2] = CreateConVar("award_revived_hp","2","How many HP reward to player who was helped from Incapaciated. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[3] = CreateConVar("award_revived_buffer","20","How many buffer HP reward to player who was helped from Incapaciated. 0=No Reward",_,true,0.0,true,100.0);

	cvar_awards[4] = CreateConVar("award_rescuer_hp","5","How many HP reward to player who rescued someone. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[5] = CreateConVar("award_rescuer_buffer_hp","0","How many buffer HP reward to player who rescued someone. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[6] = CreateConVar("award_rescued_hp","0","How many HP reward to player who was rescued. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[7] = CreateConVar("award_rescued_buffer_hp","25","How many buffer HP reward to player who was rescued. 0=No Reward",_,true,0.0,true,100.0);

	cvar_awards[8] = CreateConVar("award_pill_hp","5","How many HP reward to player who used pills. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[9] = CreateConVar("award_pill_buffer","20","How many buffer HP reward to player who used pills. 0=No Reward",_,true,0.0,true,100.0);
	
	cvar_awards[10] = CreateConVar("award_adrenaline_hp","5","How many HP reward to player who used adrenaline. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[11] = CreateConVar("award_adrenaline_buffer","15","How many buffer HP reward to player who used adrenaline. 0=No Reward",_,true,0.0,true,100.0);

	cvar_awards[12] = CreateConVar("award_medkit_healer_hp","5","How many HP reward to player who healed someone. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[13] = CreateConVar("award_medkit_healer_buffer","0","How many buffer HP reward to player who healed someone. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[14] = CreateConVar("award_medkit_healed_hp","100","How many HP reward to player who used medkit. 0=No Reward, 100=Full HP",_,true,0.0,true,100.0);
	cvar_awards[15] = CreateConVar("award_medkit_healed_buffer","0","How many buffer HP reward to player who used medkit. 0=No Reward, 100=Full HP",_,true,0.0,true,100.0);
	
	cvar_awards[16] = CreateConVar("award_defibrillator_hp","10","How many HP reward to player who defibrillated someone. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[17] = CreateConVar("award_defibrillator_buffer_hp","0","How many buffer HP reward to player who defibrillated someone. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[18] = CreateConVar("award_defibrillated_hp","0","How many HP reward to player who was defibrillated. 0=No Reward",_,true,0.0,true,100.0);
	cvar_awards[19] = CreateConVar("award_defibrillated_buffer_hp","25","How many buffer HP reward to player who was defibrillated. 0=No Reward",_,true,0.0,true,100.0);

	cvar_awards[20] = CreateConVar("award_incapacitated_hp","50","How many buffer HP reward to player who Incapaciated. 0=No Reward",_,true,0.0,true,649.0);

	cvar_player_max_hp = CreateConVar("player_max_hp","100","Maximum HP after reward.",_,true,0.0,true,100.0);
	cvar_player_max_all_hp = CreateConVar("player_max_all_hp","100","Maximum buffer HP + HP after reward.",_,true,0.0,true,100.0);
	
	cvar_awarad_message = CreateConVar("award_message","1","Award message 0=Off 1=On",_,true,0.0,true,1.0);
	
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("adrenaline_used", Event_AdrenUsed);
	HookEvent("player_incapacitated", Event_Incapacitated);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("survivor_rescued", Event_Rescued);

	AutoExecConfig(true,"l4d2_award_heal");
}

public Action HandleCmdRHp2(int client, int args)
{
	// int messageType = 0;
	// int buffer[2];
	// messageType = Award(client, 1, 3, buffer);
	// float hp2[2];
	// hp2[0] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	// ShowMessage(client, buffer[0], buffer[1], "Award rescuer", messageType);
	// hp2[1] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float hp2[2];

	int iProp = FindSendPropInfo( "CTerrorPlayer", "m_healthBuffer" );
	hp2[0] = GetEntDataFloat(client, iProp);
	SetEntDataFloat( client, iProp, hp2[0] + 3, true );
	hp2[1] = GetEntDataFloat(client, iProp);
	PrintToChat(client, "B:%.0f, A:%.0f", hp2[0], hp2[1]);

	return Plugin_Handled;
}

public int Award(int client, int hp, int bufferHp, int[] buffer)
{
	int messageType = 0;
	buffer[0] = actAwardHP(client, hp);
	buffer[1] = actAwardBufferHP(client, bufferHp);
	bufferToHP(client, buffer[0]);
	
	if(buffer[0] > 0) 
		messageType++;
	
	if(buffer[1] > 0) 
		messageType+=2;

	return messageType;
}

public Action Event_ReviveSuccess(Handle event, const char[] event_name, bool dontBroadcast){
	int rescuer = GetClientOfUserId(GetEventInt(event,"userid")); // get id of rescuer
	int rescued = GetClientOfUserId(GetEventInt(event,"subject")); // get id of rescued

	if(IsInfected(rescuer) || IsInfected(rescued)) return Plugin_Handled;

	bool isLedgeHang = GetEventBool(event, "ledge_hang");  // check ledeg hang
	int messageType = 0;
	int buffer[2];
	if(!isLedgeHang){
		messageType = Award(rescuer, GetConVarInt(cvar_awards[0]), GetConVarInt(cvar_awards[1]), buffer);
		ShowMessage(rescuer, buffer[0], buffer[1], "Award rescuer", messageType);
		
		messageType = Award(rescued, GetConVarInt(cvar_awards[2]), GetConVarInt(cvar_awards[3]), buffer);
		ShowMessage(rescued, buffer[0], buffer[1],"Award rescued", messageType);
	}
	return Plugin_Handled;
}

public Action Event_HealSuccess(Handle event, const char[] event_name, bool dontBroadcast){
	int healer = GetClientOfUserId(GetEventInt(event,"userid")); // get id of rescuer
	int healed = GetClientOfUserId(GetEventInt(event,"subject"));
	
	if(IsInfected(healer) || IsInfected(healed)) return Plugin_Handled;
	

	int messageType = 0;
	int buffer[2];
	if(healer != healed){
		messageType = Award(healer, GetConVarInt(cvar_awards[12]), GetConVarInt(cvar_awards[13]), buffer);
		ShowMessage(healer, buffer[0], buffer[1], "Award healer", messageType);
	}
	if(GetConVarInt(cvar_awards[14])==100){
		SetEntProp(healed, Prop_Send, "m_iHealth", 100, 1);
		SetEntPropFloat(healed, Prop_Send, "m_healthBuffer", float(0));
		ShowMessage(healed,0,0,"Award healed",99);
	}else{
		messageType = Award(healed, GetConVarInt(cvar_awards[14]), GetConVarInt(cvar_awards[15]), buffer);
		ShowMessage(healed, buffer[0], buffer[1], "Award healed",messageType);
	}
	return Plugin_Handled;
}

public Action Event_PillsUsed(Handle event, const char[] event_name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "subject"));

	if(IsInfected(client)) return Plugin_Handled;

	int buffer[2];
	int messageType = Award(client, GetConVarInt(cvar_awards[8]), GetConVarInt(cvar_awards[9]), buffer);
	ShowMessage(client, buffer[0], buffer[1], "Award user of pill", messageType);

	return Plugin_Handled;
}

public Action Event_AdrenUsed(Handle event, const char[] event_name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event,"subject"));

	if(IsInfected(client)) return Plugin_Handled;

	int buffer[2];
	int messageType = Award(client, GetConVarInt(cvar_awards[10]), GetConVarInt(cvar_awards[11]), buffer);
	ShowMessage(client, buffer[0], buffer[1], "Award user of adrenaline", messageType);

	return Plugin_Handled;
}

public Action Event_DefibrillatorUsed(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));

	if(IsInfected(client) || IsInfected(target)) return Plugin_Handled;


	int buffer[2];
	int messageType = Award(client, GetConVarInt(cvar_awards[16]), GetConVarInt(cvar_awards[17]), buffer);
	ShowMessage(client, buffer[0], buffer[1], "AWARD_DEFIBRILLATOR_USED", messageType);

	// for client who was defibrillated
	messageType = Award(target, GetConVarInt(cvar_awards[18]), GetConVarInt(cvar_awards[19]), buffer);
	ShowMessage(target, buffer[0], buffer[1], "AWARD_DEFIBRILLATED", messageType);
	
	return Plugin_Handled;
}

public Action Event_Rescued(Event event, char[] event_name, bool dontBroadcast)
{
	int rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	// No award for same client.
	if(IsInfected(rescuer) || IsInfected(victim) || rescuer == victim) return Plugin_Handled;

	int buffer[2];
	int messageType = Award(rescuer, GetConVarInt(cvar_awards[4]), GetConVarInt(cvar_awards[5]), buffer);
	ShowMessage(rescuer, buffer[0], buffer[1], "AWARD_RESCUER", messageType);

	// for client who was rescued
	messageType = Award(victim, GetConVarInt(cvar_awards[6]), GetConVarInt(cvar_awards[7]), buffer);
	ShowMessage(victim, buffer[0], buffer[1], "AWARD_RESCUED", messageType);

	return Plugin_Handled;
}

public Action Event_Incapacitated(Handle event, const char[] event_name, bool dontBroadcast){
	int awardHP = GetConVarInt(cvar_awards[20]);
	if(awardHP<1) return Plugin_Handled;
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int clientCurHP = GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iHealth", clientCurHP + awardHP, 1);
	ShowMessage(client, 0, awardHP, "Incapacitated", 2);
	
	return Plugin_Handled;
}

public void ShowMessage(int client, int awardHP, int award_BuffHP, const char[] reason, int message){
	if(GetConVarInt(cvar_awarad_message) != 1 || IsInfected(client)) 
		return;
	char bufferSign = award_BuffHP>0 ? '+' : '\0';
	switch(message){
		case 0:{
			PrintHintText(client,"%T","Award Error Message", client);
		}
		case 1:{
			PrintHintText(client,"[%T] %T", reason, client,"Award HP", client, awardHP);
		}
		case 2:{
			PrintHintText(client,"[%T] %c%T", reason, client, bufferSign,"Award Buff HP", client,award_BuffHP);
		}
		case 3:{
			PrintHintText(client,"[%T] %T %c%T", reason, client,"Award HP", client,awardHP , bufferSign,"Award Buff HP", client,award_BuffHP);
		}
		case 99:{
			PrintHintText(client,"[%T] %T", reason, client, "Full HP", client);
		}
	}
}


public bool checkHP(int client, int awardHP,int award_BuffHP, int hpType){
	int clientCurHP = GetClientHealth(client);
	float clientCurBufferHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	switch(hpType){
		case 0:{
			if(clientCurHP + awardHP > GetConVarInt(cvar_player_max_all_hp)){
				return false;
			}
		}
		case 1:{
			if(clientCurBufferHP + clientCurHP + award_BuffHP > GetConVarFloat(cvar_player_max_all_hp)){
				return false;
			}
		}
	}
	return true;
}

public int actAwardHP(int client, int awardHP){
	int clientCurHP = GetClientHealth(client);
	int minAward = GetConVarInt(cvar_player_max_hp)-clientCurHP;

	if(checkHP(client, awardHP, 0, 0)){
		SetEntProp(client, Prop_Send, "m_iHealth", clientCurHP + awardHP, 1);
		return awardHP;
	}else if(checkHP(client, minAward, 0, 0)){
		SetEntProp(client, Prop_Send, "m_iHealth", clientCurHP + minAward, 1);
		return minAward;
	}
	return 0;
}

public int actAwardBufferHP(int client, int award_BufferHP){
	if(IsInfected(client)) return 0;

	int clientCurHP = GetClientHealth(client);
	float clientCurBufferHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int minAward = RoundToZero(GetConVarFloat(cvar_player_max_all_hp) - (clientCurBufferHP + float(clientCurHP)));

	if(checkHP(client,0,award_BufferHP,1)){
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", clientCurBufferHP + float(award_BufferHP));
		return award_BufferHP;
	}else if(checkHP(client,0,minAward,1)){
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", clientCurBufferHP + float(minAward));
		return minAward;
	}
	return 0;
}

public void bufferToHP(int client,int awardHP){
	int clientCurHP = GetClientHealth(client);
	float clientCurBufferHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	bool awardedBufferHP = (clientCurHP + clientCurBufferHP) > GetConVarInt(cvar_player_max_all_hp);
	if(awardedBufferHP){
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", clientCurBufferHP - float(awardHP-1));
	}
}