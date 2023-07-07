#define COMSIG_RC_MOVE

/datum/component/remote_controllable
	var/mob/living/simple_animal/bot/controlled_bot = null
	var/obj/machinery/camera/botsight = null
	

/datum/component/remote_controllable/Initialize()
	if(!isbot(parent))
		return COMPONENT_INCOMPATIBLE
	controlled_bot = parent

	
////atom/movable/Move(atom/newloc, direct=0, glide_size_override = 0)
/datum/component/remote_controllable/proc/Move(atom/OldLoc, dir, Forced = FALSE)
	controlled_bot.Move(get_step(get_turf(controlled_bot), dir))
	

/datum/component/remote_controllable/RegisterWithParent()
	RegisterSignal(parent, COMSIG_RC_MOVE, PROC_REF(move))
	
	// RegisterSignal(parent, COMSIG_NOT_REAL, PROC_REF(signalproc))                                    // RegisterSignal can take a signal name by itself,
	// RegisterSignal(parent, list(COMSIG_NOT_REAL_EITHER, COMSIG_ALMOST_REAL), PROC_REF(otherproc))    // or a list of them to assign to the same proc

/datum/component/remote_controllable/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_RC_MOVE)
	
	// UnregisterSignal(parent, COMSIG_NOT_REAL)          // UnregisterSignal has similar behavior
	// UnregisterSignal(parent, list(                     // But you can just include all registered signals in one call
	// 	COMSIG_NOT_REAL,
	// 	COMSIG_NOT_REAL_EITHER,
	// 	COMSIG_ALMOST_REAL,
	// ))
/obj/item/clothing/neck/bodycam/proc/getMobhook(mob/to_hook) //This stuff is basically copypasta from RCL.dm, look there if you are confused
	bodcam.built_in = to_hook
	if(listeningTo == to_hook)//if it's already hooked, no need to do it again lol
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	listeningTo = to_hook
	RegisterSignal(listeningTo, COMSIG_MOVABLE_MOVED, PROC_REF(trigger))

/obj/item/clothing/neck/bodycam/proc/trigger(mob/user)
	if(!bodcam.status)//this is a safety in case of some fucky wucky shit. This SHOULD not ever be true but sometimes it is anyway :(
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		listeningTo = null
	GLOB.cameranet.updatePortableCamera(bodcam)
