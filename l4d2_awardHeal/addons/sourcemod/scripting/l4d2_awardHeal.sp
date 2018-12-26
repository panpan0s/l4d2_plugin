#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:h_awardRescuerHP = INVALID_HANDLE;
new Handle:h_awardRescuerBufferHP = INVALID_HANDLE;

new Handle:h_awardRescuedHP = INVALID_HANDLE;
new Handle:h_awardRescuedBufferHP = INVALID_HANDLE;

new Handle:h_awardHealerHP = INVALID_HANDLE;
new Handle:h_awardHealerBufferHP = INVALID_HANDLE;

new Handle:h_awardPillHP = INVALID_HANDLE;
new Handle:h_awardPillBufferHP = INVALID_HANDLE;

new Handle:h_awardAdrenalineHP = INVALID_HANDLE;
new Handle:h_awardAdrenalineBufferHP = INVALID_HANDLE;

new Handle:h_awardIncapacitated = INVALID_HANDLE;

new Handle:h_awardMedkitHP = INVALID_HANDLE;
new Handle:h_awardMedkitBufferHP = INVALID_HANDLE;

new Handle:h_player_max_hp = INVALID_HANDLE;
new Handle:h_player_max_all_hp = INVALID_HANDLE;

new Handle:h_awarad_message = INVALID_HANDLE;

public Plugin myinfo = {
	name = "l4d2_awardHeal",
	description = "giving award heal when player who used first-aid kit , adrenaline or pills",
	author = "panos(帕諾)",
	version = "1.0",
	url = "https://github.com/panpan0s/l4d2_plugin"
};

public void OnPluginStart(){
	LoadTranslations("awardHP.phrases");
	
	h_awardRescuerHP = CreateConVar("award_rescuer_hp","5","獎勵救起倒地隊友者多少HP 0=不獎勵",_,true,0.0,true,100.0);
	h_awardRescuerBufferHP = CreateConVar("award_rescuer_buffer","0","獎勵救起倒地隊友者多少暫時性HP 0=不獎勵",_,true,0.0,true,100.0);
	
	h_awardRescuedHP = CreateConVar("award_rescued_hp","2","倒地者被救起後獎勵多少HP 0=不獎勵",_,true,0.0,true,100.0);
	h_awardRescuedBufferHP = CreateConVar("award_rescued_buffer","20","倒地者被救起後獎勵多少暫時性HP 0=不獎勵",_,true,0.0,true,100.0);
	
	h_awardHealerHP = CreateConVar("award_healer_hp","5","獎勵包紮者多少HP 0=不獎勵",_,true,0.0,true,100.0);
	h_awardHealerBufferHP = CreateConVar("award_healer_buffer","0","獎勵包紮者多少HP暫時性 0=不獎勵",_,true,0.0,true,100.0);
	
	h_awardPillHP = CreateConVar("award_pill_hp","5","用止痛藥額外獎勵多少HP 0=不獎勵.",_,true,0.0,true,100.0);
	h_awardPillBufferHP = CreateConVar("award_pill_buffer","20","用止痛藥額外獎勵多少暫時性HP 0=不獎勵",_,true,0.0,true,100.0);
	
	h_awardAdrenalineHP = CreateConVar("award_adrenaline_hp","5","用腎上線素額外獎勵多少HP 0=不獎勵",_,true,0.0,true,100.0);
	h_awardAdrenalineBufferHP = CreateConVar("award_adrenaline_buffer","15","用腎上線素額外獎勵多少暫時性HP 0=不獎勵",_,true,0.0,true,100.0);

	h_awardIncapacitated = CreateConVar("award_incapacitated_hp","300","獎勵倒地者多少額外暫時性HP 0=不獎勵",_,true,0.0,true,649.0);
	
	h_awardMedkitHP = CreateConVar("award_medkit_hp","100","被使用醫療包者獎勵多少HP, 100=直接滿血+移除暫時性HP",_,true,0.0,true,100.0);
	h_awardMedkitBufferHP = CreateConVar("award_medkit_hp","0","被使用醫療包者獎勵多少暫時性HP, 0=不獎勵",_,true,0.0,true,100.0);
	
	h_player_max_hp = CreateConVar("player_max_hp","100","若獎勵後HP大於此值，則獎勵減少至不會超過此值的HP",_,true,0.0,true,100.0);
	h_player_max_all_hp = CreateConVar("player_max_all_hp","100","被獎勵後的玩家最大HP(HP+暫時性HP)﹐大於此數值不會獎勵",_,true,0.0,true,100.0);
	
	h_awarad_message = CreateConVar("award_message","1","獎勵提示 0=不開 1=開",_,true,0.0,true,1.0);
	
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("revive_success", event_ReviveSuccess);
	HookEvent("pills_used", event_PillsUsed);
	HookEvent("adrenaline_used", event_AdrenUsed);
	HookEvent("player_incapacitated", event_incapacitated);
	
	AutoExecConfig(true,"l4d2_awardheal");
}

public event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast){
	new rescuer = GetClientOfUserId(GetEventInt(event,"userid")); // get id of rescuer
	new rescued = GetClientOfUserId(GetEventInt(event,"subject")); // get id of rescued
	new rescuedCurHP = GetClientHealth(rescued); // get rescuer current hp
	new Float:rescuedCurBufferHP = GetEntPropFloat(rescued, Prop_Send, "m_healthBuffer");
	new bool:isLedgeHang = GetEventBool(event, "ledge_hang");  // check ledeg hang
	new messageType = 0;
	
	if(!isLedgeHang){
		new awardRescuerHP = actAwardHP(rescuer,GetConVarInt(h_awardRescuerHP));
		new awardRescuerBufferHP = actAwardBufferHP(rescuer,GetConVarInt(h_awardRescuerBufferHP));
		bufferToHP(rescuer,awardRescuerHP);
		
		if(awardRescuerHP>0)
			messageType++;
		if(awardRescuerBufferHP>0)
			messageType+=2;
		
		showMessage(rescuer,awardRescuerHP,awardRescuerBufferHP,"Award rescuer",messageType);
		
		SetEntProp(rescued, Prop_Send, "m_iHealth", rescuedCurHP + GetConVarInt(h_awardRescuedHP));
		SetEntPropFloat(rescued, Prop_Send, "m_healthBuffer", rescuedCurBufferHP + float(GetConVarInt(h_awardRescuedBufferHP)));
		showMessage(rescued,GetConVarInt(h_awardRescuedHP),GetConVarInt(h_awardRescuedBufferHP),"Award rescued",3);
	}
}

public event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast){
	new healer = GetClientOfUserId(GetEventInt(event,"userid")); // get id of rescuer
	new healed = GetClientOfUserId(GetEventInt(event,"subject"));
	new messageType = 0;
	if(healer != healed){
		new awardHealerHP = actAwardHP(healer,GetConVarInt(h_awardHealerHP));
		new awardHealerBuffHP = actAwardBufferHP(healer,GetConVarInt(h_awardHealerBufferHP));
		bufferToHP(healer,awardHealerHP);
		
		if(awardHealerHP>0)
			messageType++;
		if(awardHealerBuffHP>0)
			messageType+=2;
		
		showMessage(healer,awardHealerHP,awardHealerBuffHP,"Award healer",messageType);
	}
	if(GetConVarInt(h_awardMedkitHP)==100){
		SetEntProp(healed, Prop_Send, "m_iHealth", 100, 1);
		SetEntPropFloat(healed, Prop_Send, "m_healthBuffer", float(0));
		showMessage(healed,0,0,"Award healed",99);
	}else{
		new awardHealedHP = actAwardHP(healed,GetConVarInt(h_awardMedkitHP));
		new awardHealedBufferHP = actAwardBufferHP(healed,GetConVarInt(h_awardMedkitBufferHP));
		bufferToHP(healed,awardHealedHP);
		
		if(awardHealedHP>0)
			messageType++;
		if(awardHealedBufferHP>0)
			messageType+=2;
		
		showMessage(healed,awardHealedHP,0,"Award healed",messageType);
	}
}

public event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"subject"));
	new messageType = 0;
	
	new awardPillHP = actAwardHP(client,GetConVarInt(h_awardPillHP));
	new awardPillBufferHP = actAwardBufferHP(client,GetConVarInt(h_awardPillBufferHP));
	bufferToHP(client,awardPillHP);
	
	if(awardPillHP>0) 
		messageType++;
	
	if(awardPillBufferHP>0) 
		messageType+=2;
	
	showMessage(client,awardPillHP,awardPillBufferHP,"Award user of pill",messageType);
}

public event_AdrenUsed(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"subject"));
	new messageType = 0;
	
	new awardAdrHP = actAwardHP(client,GetConVarInt(h_awardAdrenalineHP));
	new awardAdrBufferHP = actAwardBufferHP(client,GetConVarInt(h_awardAdrenalineBufferHP));
	bufferToHP(client,awardAdrHP);
	
	if(awardAdrHP>0)
		messageType++;
	
	if(awardAdrBufferHP>0)
		messageType+=2;
	
	showMessage(client,awardAdrHP,awardAdrBufferHP,"Award user of adrenaline",messageType);
}

public event_incapacitated(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new clientCurHP = GetClientHealth(client);
	new awardHP = GetConVarInt(h_awardIncapacitated);
	SetEntProp(client, Prop_Send, "m_iHealth", clientCurHP + awardHP, 1);
	if(awardHP>0){
		showMessage(client,awardHP,0,"Award Incapaciatated",1);
	}
}

public showMessage(int client, int awardHP, int awardBuffHP, const char[] stringArg, int message){
	if(GetConVarInt(h_awarad_message)!=1) 
		return;
	int len = strlen(stringArg) + 255;
	char[] awardReason = new char[len];
	VFormat(awardReason, len, stringArg, 2);
	char bufferSign = awardBuffHP>0 ? '+' : '\0';
	switch(message){
		case 0:{
			PrintHintText(client,"%t","Award Error Message");
		}
		case 1:{
			PrintHintText(client,"[%t] %t",awardReason,"Award HP",awardHP);
		}
		case 2:{
			PrintHintText(client,"[%t] %c%t",awardReason, bufferSign,"Award Buff HP",awardBuffHP);
		}
		case 3:{
			PrintHintText(client,"[%t] %t %c%t",awardReason,"Award HP",awardHP , bufferSign,"Award Buff HP",awardBuffHP);
		}
		case 99:{
			PrintHintText(client,"[%t] %t",awardReason, "Full HP");
		}
	}
}


public bool checkHP(int client, int awardHP,int awardBuffHP, int hpType){
	new clientCurHP = GetClientHealth(client);
	new Float:clientCurBufferHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	switch(hpType){
		case 0:{
			if(clientCurHP+awardHP > GetConVarInt(h_player_max_all_hp)){
				return false;
			}
		}
		case 1:{
			if(clientCurBufferHP + clientCurHP + awardBuffHP > GetConVarInt(h_player_max_all_hp)){
				return false;
			}
		}
	}
	return true;
}

public int actAwardHP(int client, int awardHP){
	new clientCurHP = GetClientHealth(client);
	new minAward = GetConVarInt(h_player_max_hp)-clientCurHP;

	if(checkHP(client,awardHP,0,0)){
		SetEntProp(client, Prop_Send, "m_iHealth", clientCurHP + awardHP, 1);
		return awardHP;
	}else if(checkHP(client,minAward,0,0)){
		SetEntProp(client, Prop_Send, "m_iHealth", clientCurHP + minAward, 1);
		return minAward;
	}
	return 0;
}

public int actAwardBufferHP(int client, int awardBufferHP){
	new clientCurHP = GetClientHealth(client);
	new Float:clientCurBufferHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	new minAward = RoundToZero(GetConVarFloat(h_player_max_all_hp) - (clientCurBufferHP + float(clientCurHP)));

	if(checkHP(client,0,awardBufferHP,1)){
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", clientCurBufferHP + float(awardBufferHP));
		return awardBufferHP;
	}else if(checkHP(client,0,minAward,1)){
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", clientCurBufferHP + float(minAward));
		return minAward;
	}
	return 0;
}

public void bufferToHP(int client,int awardHP){
	new clientCurHP = GetClientHealth(client);
	new Float:clientCurBufferHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	new bool:awardedBufferHP = (clientCurHP + clientCurBufferHP)>GetConVarInt(h_player_max_all_hp);
	if(awardedBufferHP){
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", clientCurBufferHP - float(awardHP-1));
	}
}