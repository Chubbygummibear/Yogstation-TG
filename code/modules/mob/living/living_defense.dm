
/mob/living/proc/run_armor_check(def_zone = null, attack_flag = MELEE, absorb_text = null, soften_text = null, armour_penetration, penetrated_text)
	var/armor = getarmor(def_zone, attack_flag)

	//the if "armor" check is because this is used for everything on /living, including humans
	if(status_flags & GODMODE)
		visible_message(span_danger("A strange force protects [src], [p_they()] can't be damaged!"), span_userdanger("A strange force protects you!"))
		return armor
	if(armor > 0 && armour_penetration)	//WE HAVE ARMOR
		if(armour_penetration <= -100)	// < -100 AP, no penetration on anything
			armor = 100
		else if((-100 < armour_penetration) && (armour_penetration < 0))	// -100 to 0 AP, reduced penetration, nonlinear scaling
			armor = clamp(0, armor/(1 + (armour_penetration/100)), 100)
		else
			armor = max(0, armor - armour_penetration)						//Positive AP, actual armor penetration
		if(armour_penetration > 0 && armor < 100)	//WE HAVE INEFFECTIVE ARMOR
			if(penetrated_text)
				to_chat(src, span_userdanger("[penetrated_text]"))
			else
				to_chat(src, span_userdanger("Your armor was penetrated!"))
		else if(armor > 0)	//WE HAVE EFFECTIVE ARMOR
			if(soften_text)
				to_chat(src, span_userdanger("[soften_text]"))
			else
				to_chat(src, span_userdanger("Your armor softens the blow!"))
	if(armor >= 100)	//WE HAVE ALL THE ARMOR
		if(absorb_text)
			to_chat(src, span_userdanger("[absorb_text]"))
		else
			to_chat(src, span_userdanger("Your armor absorbs the blow!"))
	return armor


/mob/living/proc/getarmor(def_zone, type)
	return 0

//this returns the mob's protection against eye damage (number between -1 and 2) from bright lights
/mob/living/proc/get_eye_protection()
	return 0

//this returns the mob's protection against ear damage (0:no protection; 1: some ear protection; 2: has no ears)
/mob/living/proc/get_ear_protection()
	return 0

/mob/living/proc/is_mouth_covered(head_only = 0, mask_only = 0)
	return FALSE

/mob/living/proc/is_eyes_covered(check_glasses = 1, check_head = 1, check_mask = 1)
	return FALSE

/mob/living/proc/on_hit(obj/projectile/P)
	return BULLET_ACT_HIT

/mob/living/bullet_act(obj/projectile/P, def_zone)
	var/armor = run_armor_check(def_zone, P.armor_flag, "","",P.armour_penetration)

	// "Projectiles now ignore the holopara's master or any of their other holoparas."
	var/guardian_pass = FALSE
	if(istype(P, /obj/projectile/guardian))
		var/obj/projectile/guardian/G = P
		var/datum/mind/guardian_master = G.guardian_master
		if(guardian_master?.current)
			var/list/safe = list(guardian_master.current)
			safe += guardian_master.current.hasparasites()
			guardian_pass = (src in safe)
	if(guardian_pass)
		return BULLET_ACT_FORCE_PIERCE

	var/sig_return = SEND_SIGNAL(src, COMSIG_ATOM_BULLET_ACT, P, def_zone)
	if(sig_return != NONE)
		return sig_return
	
	if(!P.nodamage)
		last_damage = P.name
		if((istype(P, /obj/projectile/energy/nuclear_particle)) && (getarmor(null, RAD) >= 100))
			P.damage = 0
		else
			var/attack_direction = get_dir(P.starting, src)
			apply_damage(P.damage, P.damage_type, def_zone, armor, wound_bonus = P.wound_bonus, bare_wound_bonus = P.bare_wound_bonus, sharpness = P.sharpness, attack_direction = attack_direction)
		if(P.dismemberment)
			check_projectile_dismemberment(P, def_zone)
	if((P.penetration_flags & PENETRATE_MOBS) && P.penetrations > 0)
		P.penetrations -= 1
		return P.on_hit(src, armor) && BULLET_ACT_FORCE_PIERCE
	return P.on_hit(src, armor)? BULLET_ACT_HIT : BULLET_ACT_BLOCK

/mob/living/proc/check_projectile_dismemberment(obj/projectile/P, def_zone)
	return 0

/obj/item/proc/get_volume_by_throwforce_and_or_w_class()
		if(throwforce && w_class)
				return clamp((throwforce + w_class) * 5, 30, 100)// Add the item's throwforce to its weight class and multiply by 5, then clamp the value between 30 and 100
		else if(w_class)
				return clamp(w_class * 8, 20, 100) // Multiply the item's weight class by 8, then clamp the value between 20 and 100
		else
				return 0

/mob/living/proc/set_combat_mode(new_mode, silent = TRUE, forced = TRUE)
	if(combat_mode == new_mode)
		return
	if(!(forced || can_toggle_combat))
		return
	. = combat_mode
	combat_mode = new_mode
	if(hud_used?.action_intent)
		hud_used.action_intent.update_appearance()
	if(silent || !(client?.prefs.read_preference(/datum/preference/toggle/sound_combatmode)))
		return
	if(combat_mode)
		playsound_local(src, 'sound/misc/ui_togglecombat.ogg', 25, FALSE, pressure_affected = FALSE) //Sound from interbay!
	else
		playsound_local(src, 'sound/misc/ui_toggleoffcombat.ogg', 25, FALSE, pressure_affected = FALSE) //Slightly modified version of the above

/mob/living/proc/set_grab_mode(new_mode)
	if(grab_mode == new_mode)
		return
	. = grab_mode
	grab_mode = new_mode
	if(hud_used?.action_intent)
		hud_used.action_intent.update_appearance()

/mob/living/proc/check_shields(atom/AM, damage, attack_text = "the attack", attack_type = MELEE_ATTACK, armour_penetration = 0, damage_type = BRUTE)
	return

/mob/living/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(istype(AM, /obj/item))
		var/obj/item/I = AM
		var/zone = ran_zone(BODY_ZONE_CHEST, 65)//Hits a random part of the body, geared towards the chest
		var/dtype = BRUTE
		SEND_SIGNAL(I, COMSIG_MOVABLE_IMPACT_ZONE, src, zone)
		dtype = I.damtype
		if(!blocked)
			visible_message(span_danger("[src] has been hit by [I]."), \
							span_userdanger("[src] has been hit by [I]."))
			var/armor = run_armor_check(zone, MELEE, "Your armor has protected your [parse_zone(zone)].", "Your armor has softened hit to your [parse_zone(zone)].",I.armour_penetration)
			if(isobj(AM))
				var/obj/O = AM
				if(O.damtype != STAMINA)
					last_damage = I.name
					apply_damage(I.throwforce, dtype, zone, armor, sharpness=I.get_sharpness())
					if(I.thrownby)
						log_combat(I.thrownby, src, "threw and hit", I)
		else
			return 1
	else
		playsound(loc, 'sound/weapons/genhit.ogg', 50, 1, -1)
	..()


/mob/living/mech_melee_attack(obj/mecha/M, punch_force, equip_allowed = TRUE)
	if(M.selected?.melee_override && equip_allowed)
		M.selected.action(src)
	else if(M.occupant.combat_mode)
		last_damage = "grand blunt trauma"
		M.do_attack_animation(src)
		switch(M.damtype)
			if(BRUTE)
				if(M.force >= 20)
					Unconscious(20)
					var/throwtarget = get_edge_target_turf(M, get_dir(M, get_step_away(src, M)))
					src.throw_at(throwtarget, 5, 2, src)//one tile further than mushroom punch/psycho brawling
				take_overall_damage(rand(M.force/2, M.force))
				if(M.meleesound)
					playsound(src, 'sound/weapons/punch4.ogg', 50, 1)
			if(BURN)
				take_overall_damage(0, rand(M.force/2, M.force))
				if(M.meleesound)
					playsound(src, 'sound/items/welder.ogg', 50, 1)
			if(TOX)
				M.mech_toxin_damage(src)
			else
				return
		updatehealth()
		visible_message(span_danger("[M.name] has hit [src]!"), \
						span_userdanger("[M.name] has hit [src]!"), null, COMBAT_MESSAGE_RANGE)
		log_combat(M.occupant, src, "attacked", M, "(COMBAT MODE: [M.occupant.combat_mode ? "ON" : "OFF"]) (DAMTYPE: [uppertext(M.damtype)])")
	else
		step_away(src,M)
		log_combat(M.occupant, src, "pushed", M)
		visible_message(span_warning("[M] pushes [src] out of the way."), null, null, 5)

/mob/living/fire_act()
	last_damage = "fire"
	adjust_fire_stacks(3)
	ignite_mob()

/mob/living/proc/grabbedby(mob/living/carbon/user, supress_message = FALSE)
	if(user == src || anchored || !isturf(user.loc))
		return FALSE
	if(!user.pulling || user.pulling != src)
		user.start_pulling(src, supress_message = supress_message)
		return TRUE

	if(!(status_flags & CANPUSH) || HAS_TRAIT(src, TRAIT_PUSHIMMUNE))
		to_chat(user, span_warning("[src] can't be grabbed more aggressively!"))
		return FALSE

	if(user.grab_state >= GRAB_AGGRESSIVE && !synth_check(user, SYNTH_ORGANIC_HARM))
		to_chat(user, span_notice("You don't want to risk hurting [src]!"))
		return

	if(user.grab_state >= GRAB_AGGRESSIVE && HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_notice("You don't want to risk hurting [src]!"))
		return FALSE
	return grippedby(user)

//proc to upgrade a simple pull into a more aggressive grab.
/mob/living/proc/grippedby(mob/living/carbon/user, instant = FALSE)
	if(user.grab_state >= user.max_grab)
		return
	user.changeNext_move(CLICK_CD_GRABBING)
	var/sound_to_play = 'sound/weapons/thudswoosh.ogg'
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.dna.species.grab_sound)
			sound_to_play = H.dna.species.grab_sound
	playsound(src.loc, sound_to_play, 50, TRUE, -1)

	if(user.grab_state) //only the first upgrade is instantaneous
		var/old_grab_state = user.grab_state
		var/grab_upgrade_time = instant ? 0 : 30
		visible_message(span_danger("[user] starts to tighten [user.p_their()] grip on [src]!"), \
			span_userdanger("[user] starts to tighten [user.p_their()] grip on you!"))
		switch(user.grab_state)
			if(GRAB_AGGRESSIVE)
				log_combat(user, src, "attempted to neck grab", addition="neck grab")
			if(GRAB_NECK)
				log_combat(user, src, "attempted to strangle", addition="kill grab")
		if(!do_after(user, grab_upgrade_time, src))
			return FALSE
		if(!user.pulling || user.pulling != src || user.grab_state != old_grab_state)
			return FALSE
	user.setGrabState(user.grab_state + 1)
	switch(user.grab_state)
		if(GRAB_AGGRESSIVE)
			var/add_log = ""
			if(HAS_TRAIT(user, TRAIT_PACIFISM))
				visible_message(span_danger("[user] has firmly gripped [src]!"),
					span_danger("[user] has firmly gripped you!"))
				add_log = " (pacifist)"
			else
				visible_message(span_danger("[user] has grabbed [src] aggressively!"), \
								span_userdanger("[user] has grabbed you aggressively!"))
			stop_pulling()
			log_combat(user, src, "grabbed", addition="aggressive grab[add_log]")
		if(GRAB_NECK)
			log_combat(user, src, "grabbed", addition="neck grab")
			visible_message(span_danger("[user] grabs [src] by the neck!"),\
							span_userdanger("[user] grabs you by the neck!"), span_hear("You hear aggressive shuffling!"), null, user)
			to_chat(user, span_danger("You grab [src] by the neck!"))
			update_mobility() //we fall down
			if(!buckled && !density)
				Move(user.loc)
		if(GRAB_KILL)
			last_damage = "grip marks on the neck"
			log_combat(user, src, "strangled", addition="kill grab")
			visible_message(span_danger("[user] is strangling [src]!"), \
							span_userdanger("[user] is strangling you!"))
			update_mobility() //we fall down
			if(!buckled && !density)
				Move(user.loc)
	user.set_pull_offsets(src, grab_state)
	return TRUE


/mob/living/attack_slime(mob/living/simple_animal/slime/M)
	if(!SSticker.HasRoundStarted())
		to_chat(M, "You cannot attack people before the game has started.")
		return

	if(M.buckled)
		if(M in buckled_mobs)
			M.Feedstop()
		return // can't attack while eating!

	if(HAS_TRAIT(src, TRAIT_PACIFISM))
		to_chat(M, span_notice("You don't want to hurt anyone!"))
		return FALSE

	if (stat != DEAD)
		last_damage = "goo"
		log_combat(M, src, "attacked")
		M.do_attack_animation(src)
		visible_message(span_danger("The [M.name] glomps [src]!"), \
				span_userdanger("The [M.name] glomps [src]!"), null, COMBAT_MESSAGE_RANGE)
		return TRUE

/mob/living/attack_animal(mob/living/simple_animal/M)
	M.face_atom(src)
	if(M.melee_damage_upper == 0)
		M.visible_message(span_notice("\The [M] [M.friendly] [src]!"))
		return FALSE
	else
		if(HAS_TRAIT(M, TRAIT_PACIFISM))
			to_chat(M, span_notice("You don't want to hurt anyone!"))
			return FALSE

		if(M.attack_sound)
			playsound(loc, M.attack_sound, 50, 1, 1)
		last_damage = "lacerations"
		M.do_attack_animation(src)
		visible_message(span_danger("\The [M] [M.attacktext] [src]!"), \
						span_userdanger("\The [M] [M.attacktext] [src]!"), null, COMBAT_MESSAGE_RANGE)
		log_combat(M, src, "attacked")
		return TRUE


/mob/living/attack_paw(mob/living/carbon/monkey/M, modifiers)
	if(isturf(loc) && istype(loc.loc, /area/start))
		to_chat(M, "No attacking people at spawn, you jackass.")
		return FALSE

	if (M.combat_mode)
		if(HAS_TRAIT(M, TRAIT_PACIFISM))
			to_chat(M, span_notice("You don't want to hurt anyone!"))
			return FALSE

		if(M.is_muzzled() || M.is_mouth_covered(FALSE, TRUE))
			to_chat(M, span_warning("You can't bite with your mouth covered!"))
			return FALSE
		M.do_attack_animation(src, ATTACK_EFFECT_BITE)
		if (prob(75))
			last_damage = "minor laceration"
			log_combat(M, src, "attacked")
			playsound(loc, 'sound/weapons/bite.ogg', 50, 1, -1)
			visible_message(span_danger("[M.name] bites [src]!"), \
					span_userdanger("[M.name] bites [src]!"), null, COMBAT_MESSAGE_RANGE)
			return TRUE
		else
			visible_message(span_danger("[M.name] has attempted to bite [src]!"), \
				span_userdanger("[M.name] has attempted to bite [src]!"), null, COMBAT_MESSAGE_RANGE)
	return FALSE

/mob/living/attack_larva(mob/living/carbon/alien/larva/L, modifiers)
	if(L.combat_mode)
		if(HAS_TRAIT(L, TRAIT_PACIFISM))
			to_chat(L, span_notice("You don't want to hurt anyone!"))
			return

		L.do_attack_animation(src)
		if(prob(90))
			last_damage = "bite"
			log_combat(L, src, "attacked")
			visible_message(span_danger("[L.name] bites [src]!"), \
				span_userdanger("[L.name] bites [src]!"), null, COMBAT_MESSAGE_RANGE)
			playsound(loc, 'sound/weapons/bite.ogg', 50, 1, -1)
			return TRUE
		else
			visible_message(span_danger("[L.name] has attempted to bite [src]!"), \
				span_userdanger("[L.name] has attempted to bite [src]!"), null, COMBAT_MESSAGE_RANGE)
	else
		visible_message(span_notice("[L.name] rubs its head against [src]."))
		return FALSE

/mob/living/attack_alien(mob/living/carbon/alien/humanoid/M, modifiers)
	if(modifiers && modifiers[RIGHT_CLICK])
		last_damage = "minor blunt trauma"
		M.do_attack_animation(src, ATTACK_EFFECT_DISARM)
		return TRUE
	if(M.combat_mode)
		if(HAS_TRAIT(M, TRAIT_PACIFISM))
			to_chat(M, span_notice("You don't want to hurt anyone!"))
			return FALSE
		last_damage = "deep lacerations"
		M.do_attack_animation(src)
		return TRUE
	visible_message(span_notice("[M] caresses [src] with its scythe like arm."))
	return FALSE

/mob/living/ex_act(severity, target, origin)
	if(origin && istype(origin, /datum/spacevine_mutation) && isvineimmune(src))
		return
	last_damage = "compression blast"
	..()

//Looking for irradiate()? It's been moved to radiation.dm under the rad_act() for mobs.

/mob/living/acid_act(acidpwr, acid_volume)
	last_damage = "acidic burns"
	take_bodypart_damage(acidpwr * min(1, acid_volume * 0.1))
	return 1

/mob/living/tesla_act(source, power, zap_range, tesla_flags, list/shocked_targets)
	var/shock_damage = (tesla_flags & TESLA_MOB_DAMAGE) ? (min(round(power/600), 90) + rand(-5, 5)) : 0
	shock_damage = electrocute_act(shock_damage, source, zone=null, tesla_shock = 1, stun = (tesla_flags & TESLA_MOB_STUN))
	if(shock_damage && (tesla_flags & TESLA_MOB_GIB) && health < crit_threshold && stat)
		visible_message(
			span_danger("[src] vaporizes from the sheer energy!"), \
			span_userdanger("The sheer energy vaporizes you!"), \
			span_italics("You hear a deafening electric shock, followed by a loud splatter!"), \
		)
		tesla_zap()
		addtimer(CALLBACK(src, PROC_REF(gib)), 1)
	return ..()

/mob/living/proc/electrocute_act(shock_damage, obj/source, siemens_coeff = 1, zone = null, override = FALSE, tesla_shock = FALSE, illusion = FALSE, stun = TRUE)
	if(tesla_shock && HAS_TRAIT(src, TRAIT_TESLA_IGNORE))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE

	if(!override)
		siemens_coeff *= (100 - getarmor(zone, ELECTRIC)) / 100
	if(SEND_SIGNAL(src, COMSIG_LIVING_ELECTROCUTE_ACT, shock_damage, source, siemens_coeff, zone, tesla_shock, illusion) & COMPONENT_NO_ELECTROCUTE_ACT)
		return FALSE
	
	shock_damage *= siemens_coeff
	if(shock_damage < 1 && !override)
		return FALSE

	if(!illusion)
		last_damage = "electricity burns"
		adjustFireLoss(shock_damage)
	visible_message(
		span_danger("[src] was shocked by \the [source]!"), \
		span_userdanger("You feel a powerful shock coursing through your body!"), \
		span_italics("You hear a heavy electrical crack.") \
	)
	return shock_damage

/mob/living/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/obj/O in contents)
		O.emp_act(severity)

/mob/living/singularity_act()
	var/gain = 20
	investigate_log("([key_name(src)]) has been consumed by the singularity.", INVESTIGATE_SINGULO) //Oh that's where the clown ended up!
	gib()
	return(gain)

/mob/living/narsie_act()
	if(status_flags & GODMODE || QDELETED(src))
		return

	if(is_servant_of_ratvar(src) && !stat)
		to_chat(src, span_userdanger("You resist Nar'sie's influence... but not all of it. <i>Run!</i>"))
		adjustBruteLoss(35)
		if(src && reagents)
			reagents.add_reagent(/datum/reagent/toxin/heparin, 5)
		return FALSE
	if(GLOB.cult_narsie && GLOB.cult_narsie.souls_needed[src])
		GLOB.cult_narsie.souls_needed -= src
		GLOB.cult_narsie.souls += 1
		if((GLOB.cult_narsie.souls >= GLOB.cult_narsie.soul_goal) && (GLOB.cult_narsie.resolved == FALSE))
			GLOB.cult_narsie.resolved = TRUE
			sound_to_playing_players('sound/machines/alarm.ogg')
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), 1), 120)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ending_helper)), 270)
	if(client)
		makeNewConstruct(/mob/living/simple_animal/hostile/construct/harvester, src, cultoverride = TRUE)
	else
		switch(rand(1, 6))
			if(1)
				new /mob/living/simple_animal/hostile/construct/armored/hostile(get_turf(src))
			if(2)
				new /mob/living/simple_animal/hostile/construct/wraith/hostile(get_turf(src))
			if(3 to 6)
				new /mob/living/simple_animal/hostile/construct/builder/hostile(get_turf(src))
	spawn_dust()
	gib()
	return TRUE


/mob/living/ratvar_act()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD && !is_servant_of_ratvar(src))
		to_chat(src, span_userdanger("A blinding light boils you alive! <i>Run!</i>"))
		adjust_fire_stacks(20)
		ignite_mob()
		return FALSE


//called when the mob receives a bright flash
/mob/living/proc/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/flash)
	if(get_eye_protection() < intensity && (override_blindness_check || !(HAS_TRAIT(src, TRAIT_BLIND))) && !HAS_TRAIT(src, TRAIT_NOFLASH))
		overlay_fullscreen("flash", type)
		addtimer(CALLBACK(src, PROC_REF(clear_fullscreen), "flash", 25), 25)
		return TRUE
	return FALSE

//called when the mob receives a loud bang
/mob/living/proc/soundbang_act()
	return 0

//to damage the clothes worn by a mob
/mob/living/proc/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	return


/mob/living/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!used_item)
		used_item = get_active_held_item()
	..()
	setMovetype(movement_type & ~FLOATING) // If we were without gravity, the bouncing animation got stopped, so we make sure we restart the bouncing after the next movement.
