scriptname _Frost_WetnessSystem extends _Frost_BaseSystem

import CampUtil
import FrostUtil
import _FrostInternal

float property COVERAGE_CAP     = 360.0 autoReadOnly
float property WET_SPEED 		= 27.0 autoReadOnly 		; Wetness gained when standing in rain.
float property DRY_SPEED 		= -6.25 autoReadOnly 		; Wetness lost ambiently.
float property DRYFIRE_SPEED 	= -75.0 autoReadOnly 		; Wetness lost near fires.
float property MAX_WETNESS 		= 750.0 autoReadOnly
float property WETNESS_LEVEL_3 	= 700.0 autoReadOnly
float property WETNESS_LEVEL_2 	= 550.0 autoReadOnly
float property WETNESS_LEVEL_1 	= 200.0 autoReadOnly
float property MIN_WETNESS 		= 0.0 autoReadOnly
int property WEATHERCLASS_RAIN 	= 2 autoReadOnly

Actor property PlayerRef auto
GlobalVariable property _Frost_AttributeWetness auto
GlobalVariable property _Frost_AttributeCoverage auto
GlobalVariable property _Frost_WetLevel auto
GlobalVariable property _Frost_Setting_ConditionMessages auto
Message property _Frost_WetStateMsg_Wet3 auto
Message property _Frost_WetStateMsg_Wet2 auto
Message property _Frost_WetStateMsg_Wet1 auto
Message property _Frost_WetStateMsg_Dry auto
Message property _Frost_WetStateMsg_LeakingWater auto
Formlist property _Frost_Waterfalls auto

int last_wet_level = 0
float last_update_time = 0.0
float this_update_time = 0.0

function Update()
	if last_update_time == 0.0
		; Skip the first update
		last_update_time = Game.GetRealHoursPassed()
		return
	endif

	this_update_time = Game.GetRealHoursPassed()
	UpdateWetState()
	UpdateWetLevel()
	last_update_time = this_update_time
endFunction

function RegisterForEvents()
	RegisterForModEvent("Frostfall_OnPlayerStartSwimming", "OnPlayerStartSwimming")
endFunction

Event OnPlayerStartSwimming()
	ModAttributeWetness(MAX_WETNESS, MAX_WETNESS)
	UpdateWetLevel()
endEvent

function ModAttributeWetness(float amount, float limit)
	; Note: Limit values above 0 will result in the system "pushing up" (increasing) against
	; it once it clamps to the limit.

	float wet_attr = _Frost_AttributeWetness.GetValue()
	if wet_attr == limit
		if limit == MIN_WETNESS && amount < 0
			; Already at minimum
			return
		elseif limit > MIN_WETNESS && amount > 0
			; Already at maximum
			return
		endif
	endif

	float wetness = wet_attr + amount
	if wetness > limit && amount > 0
		wetness = limit
		if limit < MAX_WETNESS && limit > MIN_WETNESS
			_Frost_WetStateMsg_LeakingWater.Show()
		endif
	elseif wetness < limit && amount < 0
		wetness = limit
		if limit < MAX_WETNESS && limit > MIN_WETNESS
			_Frost_WetStateMsg_LeakingWater.Show()
		endif
	endif
	_Frost_AttributeWetness.SetValue(wetness)
	FrostDebug(1, "~~~~ Wetness ::: Current Wetness: " + wetness + " (" + amount + ")")
endFunction

function UpdateWetLevel()
	float wetness = _Frost_AttributeWetness.GetValue()
	int wet_level = 0

	if wetness > WETNESS_LEVEL_3
		wet_level = 3
		ShowWetStateMessage(3)
	elseif wetness > WETNESS_LEVEL_2
		wet_level = 2
		ShowWetStateMessage(2)
	elseif wetness > WETNESS_LEVEL_1
		wet_level = 1
		ShowWetStateMessage(1)
	elseif wetness >= MIN_WETNESS
		wet_level = 0
		if wetness == MIN_WETNESS
			ShowWetStateMessage(0)
		endif
	endif

	_Frost_WetLevel.SetValueInt(wet_level)
	
	if wet_level > 0
		last_wet_level = _Frost_WetLevel.GetValueInt()
	elseif wetness == MIN_WETNESS
		last_wet_level = 0
	endif
endFunction

function ShowWetStateMessage(int wet_level)
	if _Frost_Setting_ConditionMessages.GetValueInt() == 2 && FrostUtil.IsPlayerVampire() == false
		if wet_level == 3 && last_wet_level != 3
			_Frost_WetStateMsg_Wet3.Show()
		elseif wet_level == 2 && last_wet_level != 2
			_Frost_WetStateMsg_Wet2.Show()
		elseif wet_level == 1 && last_wet_level != 1
			_Frost_WetStateMsg_Wet1.Show()
		elseif wet_level == 0 && last_wet_level != 0
			_Frost_WetStateMsg_Dry.Show()
		endif
	endif
endFunction

bool function IsNearWaterfall()
	ObjectReference waterfall = Game.FindClosestReferenceOfAnyTypeInListFromRef(_Frost_Waterfalls, PlayerRef, 85.0)
	if waterfall && waterfall.IsEnabled()
		return true
	else
		return false
	endif
endFunction

function UpdateWetState()
	if PlayerRef.IsSwimming()
		return
	endif
	
	bool near_waterfall = IsNearWaterfall()
	if near_waterfall
		ModAttributeWetness(MAX_WETNESS, MAX_WETNESS)
		return
	endif

	;@TODO: Possibly pull from Weather System
	int weather_class = GetWeatherClassificationActual(Weather.GetCurrentWeather())

	bool wet_conditions = false
	if weather_class == WEATHERCLASS_RAIN && Weather.GetOutgoingWeather() == none && \
	   !IsRefInOblivion(PlayerRef) && !IsRefInInterior(PlayerRef)
		wet_conditions = true
	endif

	bool inside_tent = GetCurrentTent()
	bool inside_waterproof_tent = IsCurrentTentWaterproof()
	bool taking_shelter = IsPlayerTakingShelter()
	; FrostDebug(0, "~~~~ WetSystem ::: wet conditions: " + wet_conditions + ", inside tent " + inside_tent + ", waterproof " + inside_waterproof_tent + ", taking shelter: " + taking_shelter)
	if wet_conditions
		if inside_waterproof_tent || taking_shelter
			DryOff(MIN_WETNESS)
		elseif inside_tent && !inside_waterproof_tent
			GetWetter(300.0)
		elseif !inside_tent && !taking_shelter
			GetWetter(MAX_WETNESS)
		else
			DryOff(MIN_WETNESS)
		endif
	else
		DryOff(MIN_WETNESS)
	endif
	
	;Less exposure drain in warmer weather.
	;/ int theTemp = _DE_CurrentTemp.GetValueInt()
	if theTemp >= 15
		WetFactor /= 4
	elseif theTemp > 10
		WetFactor /= 2
	endif
	/;
endFunction

function DryOff(float limit)
	FrostDebug(1, "~~~~ Wetness ::: DryOff : Limit " + limit)
	
	float update_freq = UpdateFrequencyGlobal.GetValue()
	float time_delta_seconds = (this_update_time - last_update_time) * 3600.0
	if time_delta_seconds > (update_freq * 2)
		time_delta_seconds = (update_freq * 2)
	endif

	float amount
	if IsPlayerNearFire()
		 amount = (((DRYFIRE_SPEED * GetPlayerHeatSourceLevel()) * time_delta_seconds) / update_freq)
    else
    	 amount = ((DRY_SPEED * time_delta_seconds) / update_freq)
    endif
    ModAttributeWetness(amount, limit)
endFunction

function GetWetter(float limit)
	if _Frost_AttributeWetness.GetValue() > limit
		FrostDebug(1, "~~~~ Wetness ::: Wetness greater than limit, drying off.")
		DryOff(limit)
	else
		float update_freq = UpdateFrequencyGlobal.GetValue()
		float time_delta_seconds = (this_update_time - last_update_time) * 3600.0
		if time_delta_seconds > (update_freq * 2)
			time_delta_seconds = (update_freq * 2)
		endif

		; Reduce the player's wetness rate by up to 80%.
		float rain_protect_modifier = 1.0 - (((_Frost_AttributeCoverage.GetValueInt() * 80.0) / COVERAGE_CAP) / 100.0)
		float amount = ((WET_SPEED * time_delta_seconds) / update_freq) * rain_protect_modifier

		FrostDebug(1, "~~~~ Wetness ::: GetWetter : Limit " + limit + ", Rain protection modifier " + rain_protect_modifier)
		ModAttributeWetness(amount, limit)
	endif
endFunction