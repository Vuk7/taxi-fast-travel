/*
		Taxi fast travel filterscript
		                	by Vuk7
		                	
		Potrebno je:
		- kreirati mapu Taxi u mapi scriptfiles
		- promjeniti vrijednosti MAX_TAXIES (maksimalni broj taxi stanica za kreirati),
		  TAXI_CIJENA (cijena jedne voznje) i DIALOG_TAXI (id dialoga za taxi)

*/
#include <a_samp>
#include <zcmd>
#include <YSI\y_ini>
#include <sscanf2>
#include <streamer>

#define SCM SendClientMessage

#define plava "{00BFFF}"
#define crvena "{FF0000}"
#define zuta "{FFFF00}"
#define bijela "{FFFFFF}"

#define TPATH "/Taxi/%d.ini"
#define MAX_TAXIES 10
#define TAXI_CIJENA 3000
#define DIALOG_TAXI 1

enum tInfo
{
    tName[24],
	tID,
	Float:tX,
	Float:tY,
	Float:tZ,
	tVW,
	tInt,
	Float:tCarX,
	Float:tCarY,
	Float:tCarZ,
	Float:tCarAZ
}
new TaxiInfo[MAX_TAXIES][tInfo];
new Text3D:tTxt[MAX_TAXIES];
new Taxi[MAX_PLAYERS];
new TaxiVehicle[MAX_PLAYERS];
new PlayerText:TaxiTD[MAX_PLAYERS];
new TaxiState[MAX_PLAYERS];
new TaxiTimer[MAX_PLAYERS];

forward LoadTaxi(id,name[],value[]);
public LoadTaxi(id,name[],value[])
{
    INI_String("Name",TaxiInfo[id][tName],24);
	INI_Int("ID",TaxiInfo[id][tID]);
	INI_Float("X",TaxiInfo[id][tX]);
    INI_Float("Y",TaxiInfo[id][tY]);
    INI_Float("Z",TaxiInfo[id][tZ]);
	INI_Int("VW",TaxiInfo[id][tVW]);
    INI_Int("Interior",TaxiInfo[id][tInt]);
	INI_Float("CarX",TaxiInfo[id][tCarX]);
    INI_Float("CarY",TaxiInfo[id][tCarY]);
    INI_Float("CarZ",TaxiInfo[id][tCarZ]);
    INI_Float("CarAZ",TaxiInfo[id][tCarAZ]);
 	return 1;
}

TaxiPath(id)
{
	new str[30];
	format(str,sizeof(str),TPATH,id);
	return str;
}

SacuvajTaxi(id)
{
    new INI:File = INI_Open(TaxiPath(id));
	INI_SetTag(File,"data");
    INI_WriteString(File,"Name",TaxiInfo[id][tName]);
	INI_WriteInt(File,"ID",TaxiInfo[id][tID]);
	INI_WriteFloat(File,"X",TaxiInfo[id][tX]);
    INI_WriteFloat(File,"Y",TaxiInfo[id][tY]);
    INI_WriteFloat(File,"Z",TaxiInfo[id][tZ]);
	INI_WriteInt(File,"VW",TaxiInfo[id][tVW]);
    INI_WriteInt(File,"Interior",TaxiInfo[id][tInt]);
	INI_WriteFloat(File,"CarX",TaxiInfo[id][tCarX]);
    INI_WriteFloat(File,"CarY",TaxiInfo[id][tCarY]);
    INI_WriteFloat(File,"CarZ",TaxiInfo[id][tCarZ]);
    INI_WriteFloat(File,"CarAZ",TaxiInfo[id][tCarAZ]);
	INI_Close(File);
	return 1;
}

UcitajTaxi()
{
	new x = 0;
	new str[200];
	for(new i=0;i<MAX_TAXIES;i++)
	{
	    if(fexist(TaxiPath(i)))
	    {
    		INI_ParseFile(TaxiPath(i), "LoadTaxi", .bExtra = true, .extra = i);
		    TaxiInfo[i][tID] = CreateDynamicPickup(19308,1,TaxiInfo[i][tX],TaxiInfo[i][tY],TaxiInfo[i][tZ],TaxiInfo[i][tVW]);
		    format(str,sizeof(str),""crvena"[ TAXI ]\n"crvena"Lokacija: "plava"%s\n"bijela"Da pozovete taxi upisite '"zuta"/taxi"bijela"'.\n"crvena"ID: "bijela"%d",TaxiInfo[i][tName],i);
			tTxt[i] = Create3DTextLabel(str,-1,TaxiInfo[i][tX],TaxiInfo[i][tY],TaxiInfo[i][tZ],5.0,TaxiInfo[i][tVW],0);
			x++;
		}
	}
	printf("Kreirano %d taxija!",x);
	return 1;
}

public OnFilterScriptInit()
{
	UcitajTaxi();
	return 1;
}


public OnPlayerConnect(playerid)
{
    Taxi[playerid] = -1; TaxiVehicle[playerid] = INVALID_VEHICLE_ID;
    TaxiState[playerid] = 0;
    
    TaxiTD[playerid] = CreatePlayerTextDraw(playerid, 1.333214, -0.400045, "box");
	PlayerTextDrawLetterSize(playerid, TaxiTD[playerid], 0.000000, 49.900001);
	PlayerTextDrawTextSize(playerid, TaxiTD[playerid], 642.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, TaxiTD[playerid], 1);
	PlayerTextDrawColor(playerid, TaxiTD[playerid], -1);
	PlayerTextDrawUseBox(playerid, TaxiTD[playerid], 1);
	PlayerTextDrawBoxColor(playerid, TaxiTD[playerid], 170);
	PlayerTextDrawSetShadow(playerid, TaxiTD[playerid], 0);
	PlayerTextDrawSetOutline(playerid, TaxiTD[playerid], 0);
	PlayerTextDrawBackgroundColor(playerid, TaxiTD[playerid], 255);
	PlayerTextDrawFont(playerid, TaxiTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, TaxiTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, TaxiTD[playerid], 0);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(TaxiVehicle[playerid] != INVALID_VEHICLE_ID) DestroyVehicle(TaxiVehicle[playerid]);
	return 1;
}

CMD:kreirajtaxi(playerid,params[])
{
	if(!IsPlayerAdmin(playerid)) return 1;
	new Float:x,Float:y,Float:z,name[24];
 	if(sscanf(params,"s[24]",name)) return SCM(playerid,-1,"/kreirajtaxi [Ime]");
 	GetPlayerPos(playerid,x,y,z);
    for(new i=0;i<MAX_TAXIES;i++) { if(IsPlayerInRangeOfPoint(playerid,6.0,TaxiInfo[i][tX],TaxiInfo[i][tY],TaxiInfo[i][tZ])) { SCM(playerid,-1,"U blizini nekog taxija ste!"); return 1; } }
    new id = -1;
	for(new i=0;i<MAX_TAXIES;i++)
	{
	    if(!fexist(TaxiPath(i)))
	    {
	        id = i;
	        break;
	    }
	}
	if(id == -1) return SCM(playerid,-1,"Maksimalni broj taxija je kreiran!");
	TaxiInfo[id][tX] = x;
    TaxiInfo[id][tY] = y;
    TaxiInfo[id][tZ] = z;
	TaxiInfo[id][tVW] = GetPlayerVirtualWorld(playerid);
    TaxiInfo[id][tInt] = GetPlayerInterior(playerid);
	TaxiInfo[id][tCarX] =
    TaxiInfo[id][tCarY] =
    TaxiInfo[id][tCarZ] =
    TaxiInfo[id][tCarAZ] = 0.0;
    strmid(TaxiInfo[id][tName], name, 0, strlen(name), MAX_PLAYER_NAME);
    TaxiInfo[id][tID] = CreateDynamicPickup(19308,1,TaxiInfo[id][tX],TaxiInfo[id][tY],TaxiInfo[id][tZ],TaxiInfo[id][tVW]);
    new str[200];
    format(str,sizeof(str),""crvena"[ TAXI ]\n"crvena"Lokacija: "plava"%s\n"bijela"Da pozovete taxi upisite '"zuta"/taxi"bijela"'.\n"crvena"ID: "bijela"%d",TaxiInfo[id][tName],id);
	tTxt[id] = Create3DTextLabel(str,-1,TaxiInfo[id][tX],TaxiInfo[id][tY],TaxiInfo[id][tZ],5.0,TaxiInfo[id][tVW],0);
	SacuvajTaxi(id);
	SCM(playerid,-1,"Uspjesno ste postavili taxi! Sad postavite vozilo sa komandom /postavitaxivozilo!");
	return 1;
}

CMD:postavitaxivozilo(playerid,params[])
{
	if(!IsPlayerAdmin(playerid)) return 1;
	new Float:x,Float:y,Float:z,Float:az,id;
 	if(sscanf(params,"d",id)) return SendClientMessage(playerid,-1,"/postavitaxivozilo [Id]");
 	if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid,-1,"Niste u vozilu!");
 	GetVehiclePos(GetPlayerVehicleID(playerid),x,y,z);
 	GetVehicleZAngle(GetPlayerVehicleID(playerid),az);
    if(!IsPlayerInRangeOfPoint(playerid,20.0,TaxiInfo[id][tX],TaxiInfo[id][tY],TaxiInfo[id][tZ])) return SCM(playerid,-1,"Niste u blizini taksi znaka!");
    if(GetPlayerInterior(playerid) != TaxiInfo[id][tInt]) return SCM(playerid,-1,"Niste u blizini taksi znaka!");
    if(GetPlayerVirtualWorld(playerid) != TaxiInfo[id][tVW]) return SCM(playerid,-1,"Niste u blizini taksi znaka!");
	TaxiInfo[id][tCarX] = x;
    TaxiInfo[id][tCarY] = y;
    TaxiInfo[id][tCarZ] = z;
    TaxiInfo[id][tCarAZ] = az;
	SacuvajTaxi(id);
	SCM(playerid,-1,"Uspjesno ste postavili taxi vozilo!");
	return 1;
}

CMD:taxi(playerid,params[])
{
    #pragma unused params
	if(!IsPlayerConnected(playerid)) return 1;
	if(IsPlayerInAnyVehicle(playerid)) return 1;
	new id = -1;
	new str1[1000],str[200];
	for(new i;i<MAX_TAXIES;i++)
	{
	    if(IsPlayerInRangeOfPoint(playerid,6.0,TaxiInfo[i][tX],TaxiInfo[i][tY],TaxiInfo[i][tZ])) { id = i; }
	    if(fexist(TaxiPath(i)))
	    {
	        if(TaxiInfo[i][tCarX] == 0.0 && TaxiInfo[i][tCarY] == 0.0 && TaxiInfo[i][tCarZ] == 0.0 && TaxiInfo[i][tCarAZ] == 0.0)
	        {
	            format(str,sizeof(str),""zuta"[%d] "bijela"PRAZNO\n",i);
	      		strcat(str1,str);
	        }
	        else
	        {
		    	format(str,sizeof(str),""zuta"[%d] "bijela"Lokacija: %s - Cijena: %d$\n",i,TaxiInfo[i][tName],TAXI_CIJENA);
				strcat(str1,str);
			}
		}
		else
		{
		    format(str,sizeof(str),""zuta"[%d] "bijela"PRAZNO\n",i);
      		strcat(str1,str);
		}
	}
	if(id == -1) return SCM(playerid,-1,"Niste u blizini taksi znaka!");
	if(TaxiInfo[id][tCarX] == 0.0 && TaxiInfo[id][tCarY] == 0.0 && TaxiInfo[id][tCarZ] == 0.0 && TaxiInfo[id][tCarAZ] == 0.0) return SCM(playerid,-1,"Taxi trenutno nije u funkciji!");
	Taxi[playerid] = id;
	ShowPlayerDialog(playerid,DIALOG_TAXI,DIALOG_STYLE_LIST,"Taxi",str1,"Pozovi","Odustani");
	return 1;
}

CMD:izbrisitaxi(playerid,params[])
{
    if(!IsPlayerConnected(playerid)) return 1;
	new id;
	if(sscanf(params,"d",id)) return SCM(playerid,-1,"/izbrisitaxi [Id]");
	if(!fexist(TaxiPath(id)))
	{
	    SCM(playerid,-1,"Taj id ne postoji");
	}
	else
	{
	    TaxiInfo[id][tVW] = 0;
	    TaxiInfo[id][tInt] = 0;
	 	TaxiInfo[id][tX] =
	    TaxiInfo[id][tY] =
	    TaxiInfo[id][tZ] =
		TaxiInfo[id][tCarX] =
	    TaxiInfo[id][tCarY] =
	    TaxiInfo[id][tCarZ] =
	    TaxiInfo[id][tCarAZ] = 0.0;
    	strmid(TaxiInfo[id][tName], "~n~", 0, strlen("~n~"), MAX_PLAYER_NAME);
    	DestroyDynamicPickup(TaxiInfo[id][tID]);
	 	Delete3DTextLabel(tTxt[id]);
	 	fremove(TaxiPath(id));
	}
	return 1;
}

CMD:portdotaxija(playerid,params[])
{
    if(!IsPlayerConnected(playerid)) return 1;
	new id;
	if(sscanf(params,"d",id)) return SCM(playerid,-1,"/portdotaxija [Id]");
	if(!fexist(TaxiPath(id))) return SCM(playerid,-1,"Taj id ne postoji");
	SetPlayerVirtualWorld(playerid, TaxiInfo[id][tVW]);
	SetPlayerInterior(playerid, TaxiInfo[id][tInt]);
	SetPlayerPos(playerid,TaxiInfo[id][tX], TaxiInfo[id][tY], TaxiInfo[id][tZ]);
	new str[50];
	format(str,sizeof(str),""zuta"Portali ste se do taxija! ID:%d",id);
	SCM(playerid,-1,str);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_TAXI)
	{
	    if(!response) return 1;
	    if(Taxi[playerid] == -1) return 1;
		new i = listitem;
		if(!fexist(TaxiPath(i))) return 1;
		if(TaxiInfo[i][tCarX] == 0.0 && TaxiInfo[i][tCarY] == 0.0 && TaxiInfo[i][tCarZ] == 0.0 && TaxiInfo[i][tCarAZ] == 0.0) return 1;
		if(GetPlayerMoney(playerid) < TAXI_CIJENA) return SCM(playerid,-1,"Nemate dovoljno novca!");
		if(i == Taxi[playerid]) return SCM(playerid,-1,"Ne mozete na istu lokaciju!");
		TaxiVehicle[playerid] = CreateVehicle(420,TaxiInfo[Taxi[playerid]][tCarX],TaxiInfo[Taxi[playerid]][tCarY],TaxiInfo[Taxi[playerid]][tCarZ],TaxiInfo[Taxi[playerid]][tCarAZ],6,6,10);
		SetVehicleVirtualWorld(TaxiVehicle[playerid], TaxiInfo[Taxi[playerid]][tVW]);
		LinkVehicleToInterior(TaxiVehicle[playerid], TaxiInfo[Taxi[playerid]][tInt]);
		TogglePlayerControllable(playerid,0);
		PutPlayerInVehicle(playerid,TaxiVehicle[playerid],2);
		PlayerTextDrawHide(playerid, TaxiTD[playerid]);
		PlayerTextDrawBoxColor(playerid, TaxiTD[playerid], 0x000000AA);
		PlayerTextDrawShow(playerid, TaxiTD[playerid]);
		TaxiState[playerid] = 1;
		TaxiTimer[playerid] = SetTimerEx("taxi2",3000,true,"dd",playerid,i);
		return 1;
	}
	return 1;
}

forward taxi2(playerid,id);
public taxi2(playerid,id)
{
	if(TaxiState[playerid] == 1)
	{
	    PlayerTextDrawHide(playerid, TaxiTD[playerid]);
		PlayerTextDrawBoxColor(playerid, TaxiTD[playerid], 0x000000EE);
		PlayerTextDrawShow(playerid, TaxiTD[playerid]);
		PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
	    TaxiState[playerid]++;
	}
	else if(TaxiState[playerid] == 2)
	{
	    PlayerTextDrawHide(playerid, TaxiTD[playerid]);
		PlayerTextDrawBoxColor(playerid, TaxiTD[playerid], 0x000000FF);
		PlayerTextDrawShow(playerid, TaxiTD[playerid]);
    	SetVehiclePos(TaxiVehicle[playerid],TaxiInfo[id][tCarX],TaxiInfo[id][tCarY],TaxiInfo[id][tCarZ]);
    	SetVehicleZAngle(TaxiVehicle[playerid],TaxiInfo[id][tCarAZ]);
    	SetVehicleVirtualWorld(TaxiVehicle[playerid], TaxiInfo[id][tVW]);
		LinkVehicleToInterior(TaxiVehicle[playerid], TaxiInfo[id][tInt]);
		SetPlayerVirtualWorld(playerid, TaxiInfo[id][tVW]);
		SetPlayerInterior(playerid, TaxiInfo[id][tInt]);
    	PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
    	TaxiState[playerid]++;
    }
    else if(TaxiState[playerid] == 3)
	{
	    PlayerTextDrawHide(playerid, TaxiTD[playerid]);
		PlayerTextDrawBoxColor(playerid, TaxiTD[playerid], 0x000000EE);
		PlayerTextDrawShow(playerid, TaxiTD[playerid]);
		PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
    	TaxiState[playerid]++;
    }
    else if(TaxiState[playerid] == 4)
	{
	    PlayerTextDrawHide(playerid, TaxiTD[playerid]);
		PlayerTextDrawBoxColor(playerid, TaxiTD[playerid], 0x000000AA);
		PlayerTextDrawShow(playerid, TaxiTD[playerid]);
		PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
    	TaxiState[playerid]++;
    }
    else if(TaxiState[playerid] == 5)
	{
	    PlayerTextDrawHide(playerid, TaxiTD[playerid]);
	    Taxi[playerid] = -1;
	    RemovePlayerFromVehicle(playerid);
		TogglePlayerControllable(playerid,1);
		RemovePlayerFromVehicle(playerid);
		GivePlayerMoney(playerid,-TAXI_CIJENA);
		PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
		TaxiState[playerid]++;
    }
    else if(TaxiState[playerid] == 6)
	{
	    DestroyVehicle(TaxiVehicle[playerid]);
		TaxiVehicle[playerid] = INVALID_VEHICLE_ID;
		KillTimer(TaxiTimer[playerid]);
		PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
		TaxiState[playerid]=0;
	}
	else
	{
	    PlayerTextDrawHide(playerid, TaxiTD[playerid]);
	    Taxi[playerid] = -1;
	    RemovePlayerFromVehicle(playerid);
		TogglePlayerControllable(playerid,1);
		RemovePlayerFromVehicle(playerid);
	    DestroyVehicle(TaxiVehicle[playerid]);
		TaxiVehicle[playerid] = INVALID_VEHICLE_ID;
		KillTimer(TaxiTimer[playerid]);
		PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
		TaxiState[playerid]=0;
	}
	return 1;
}
