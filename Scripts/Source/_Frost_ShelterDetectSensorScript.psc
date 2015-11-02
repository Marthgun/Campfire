Scriptname _Frost_ShelterDetectSensorScript extends ObjectReference

import _FrostInternal

GlobalVariable property _Frost_ShelterDetectLastSeenTime auto
Spell property _Frost_ShelterDetectBeam auto

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	FrostDebug(0, "Shelter detection sensor hit!")
	if akSource == _Frost_ShelterDetectBeam
		_Frost_ShelterDetectLastSeenTime.SetValue(Game.GetRealHoursPassed())
	endif
endEvent
