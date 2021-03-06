scriptname _Frost_ExposureMeterInterfaceHandler extends CommonMeterInterfaceHandler

function RegisterForEvents()
	RegisterForModEvent("Frostfall_ForceExposureMeterDisplay", "ForceMeterDisplay")
	RegisterForModEvent("Frostfall_RemoveExposureMeter", "RemoveMeter")
	RegisterForModEvent("Frostfall_UpdateExposureMeter", "UpdateMeterDelegate")
	RegisterForModEvent("Frostfall_CheckMeterRequirements", "CheckMeterRequirements")

	; Special Frostfall indicator element
	RegisterForModEvent("Frostfall_UpdateExposureMeterIndicator", "UpdateMeterIndicator")
endFunction

Event UpdateMeterIndicator(float percent)
	(Meter as _Frost_Meter).SetIndicatorPercent(percent)
endEvent
