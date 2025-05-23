/datum/antagonist/revenant
	name = "Revenant"
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	greentext_achieve = /datum/achievement/greentext/revenant
	show_to_ghosts = TRUE
	count_towards_antag_cap = TRUE

/datum/antagonist/revenant/greet()
	owner.announce_objectives()

/datum/antagonist/revenant/proc/forge_objectives()
	var/datum/objective/revenant/objective = new
	objective.owner = owner
	objectives += objective
	var/datum/objective/revenantFluff/objective2 = new
	objective2.owner = owner
	objectives += objective2

/datum/antagonist/revenant/on_gain()
	forge_objectives()
	. = ..()

/datum/antagonist/revenant/get_preview_icon()
	return finish_preview_icon(icon('icons/mob/mob.dmi', "revenant_idle"))
