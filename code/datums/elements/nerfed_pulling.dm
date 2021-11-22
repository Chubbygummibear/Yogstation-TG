//these exist because our movement datum does not match TG's method
#define NERFED_BUMP "nerfed_bump"
#define NERFED_PULL "nerfed_pull"

/// This living will be slower when pulling/moving anything in the given typecache
/datum/element/nerfed_pulling
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH
	id_arg_index = 2

	/// The typecache of things that shouldn't be easily movable
	var/list/typecache

/datum/element/nerfed_pulling/Attach(datum/target, list/typecache)
	. = ..()

	if (!isliving(target))
		return ELEMENT_INCOMPATIBLE

	src.typecache = typecache

	RegisterSignal(target, COMSIG_LIVING_PUSHING_MOVABLE, .proc/on_push_movable)
	RegisterSignal(target, COMSIG_LIVING_UPDATING_PULL_MOVESPEED, .proc/on_updating_pull_movespeed)

/datum/element/nerfed_pulling/Detach(mob/living/source)
	// source.remove_movespeed_modifier(/datum/movespeed_modifier/nerfed_bump) again this is tg's method. someday we can uncomment this
	// source.remove_movespeed_modifier(/datum/movespeed_modifier/nerfed_pull)

	source.remove_movespeed_modifier(NERFED_BUMP)
	source.remove_movespeed_modifier(NERFED_PULL)

	UnregisterSignal(source, list(COMSIG_LIVING_PUSHING_MOVABLE, COMSIG_LIVING_UPDATING_PULL_MOVESPEED))

	return ..()

/datum/element/nerfed_pulling/proc/on_push_movable(mob/living/source, atom/movable/being_pushed)
	//SIGNAL_HANDLER

	if (!will_slow_down(being_pushed))
		return
	//source.add_movespeed_modifier(/datum/movespeed_modifier/nerfed_bump) this is what the tg version is with updated movespeed datum
	source.add_movespeed_modifier(NERFED_BUMP, update=TRUE, priority=101, multiplicative_slowdown=5.5)	
	//addtimer(CALLBACK(source, /mob/proc/remove_movespeed_modifier, /datum/movespeed_modifier/nerfed_bump), 1 SECONDS, TIMER_OVERRIDE | TIMER_UNIQUE) tg version
	addtimer(CALLBACK(source, /mob.proc/remove_movespeed_modifier, NERFED_BUMP), 1 SECONDS, TIMER_OVERRIDE | TIMER_UNIQUE)

/datum/element/nerfed_pulling/proc/on_updating_pull_movespeed(mob/living/source)
	//SIGNAL_HANDLER

	if (!will_slow_down(source.pulling))
		source.remove_movespeed_modifier(NERFED_PULL)
		return

	source.add_movespeed_modifier(NERFED_BUMP, update=TRUE, priority=101, multiplicative_slowdown=5.5)

/datum/element/nerfed_pulling/proc/will_slow_down(datum/input)
	return !isnull(input) && typecache[input.type]

// /datum/movespeed_modifier/nerfed_pull
// 	multiplicative_slowdown = 5.5

// /datum/movespeed_modifier/nerfed_bump
// 	multiplicative_slowdown = 5.5

#undef NERFED_BUMP
#undef NERFED_PULL
