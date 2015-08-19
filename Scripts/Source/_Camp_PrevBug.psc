scriptname _Camp_PrevBug extends ObjectReference

ObjectReference property myController auto hidden

Event OnActivate(ObjectReference akActionRef)
    debug.trace("Prev clicked")
    (myController as _Camp_PerkNavController).PrevClicked()
EndEvent

function AssignController(ObjectReference akController)
	myController = akController
endFunction