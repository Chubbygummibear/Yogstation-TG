/**
 * ## Mech melee attack
 * Called when a mech melees a target with fists
 * Handles damaging the target & associated effects
 * return value is number of damage dealt
 * Arguments:
 * * mecha_attacker: Mech attacking this target
 * * user: mob that initiated the attack from inside the mech as a controller
 */
/atom/proc/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	SHOULD_CALL_PARENT(TRUE)
	log_combat(mecha_attacker.occupant, src, "attacked", mecha_attacker, "(INTENT: [uppertext(mecha_attacker.occupant.a_intent)]) (DAMTYPE: [uppertext(mecha_attacker.damtype)])")
	return

/turf/closed/wall/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	mecha_attacker.do_attack_animation(src)
	switch(mecha_attacker.damtype)
		if(BRUTE)
			playsound(src, 'sound/weapons/punch4.ogg', 50, TRUE)
		if(BURN)
			playsound(src, 'sound/items/welder.ogg', 100, TRUE)
		if(TOX)
			playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
			return FALSE
		else
			return FALSE
	mecha_attacker.visible_message(span_danger("[mecha_attacker.name] hits [src]!"), span_danger("You hit [src]!"), null, COMBAT_MESSAGE_RANGE)
	if(prob(hardness + mecha_attacker.force) && mecha_attacker.force > 20)
		dismantle_wall(1)
		playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	else
		add_dent(WALL_DENT_HIT)
	..()
	return 100 //this is an arbitrary "damage" number since the actual damage is rng dismantle

/obj/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	mecha_attacker.do_attack_animation(src)
	var/play_soundeffect = 0
	var/mech_damtype = mecha_attacker.damtype
	if(mecha_attacker.selected)
		mech_damtype = mecha_attacker.selected.damtype
		play_soundeffect = 1
	else
		switch(mecha_attacker.damtype)
			if(BRUTE)
				playsound(src, 'sound/weapons/punch4.ogg', 50, TRUE)
			if(BURN)
				playsound(src, 'sound/items/welder.ogg', 50, TRUE)
			if(TOX)
				playsound(src, 'sound/effects/spray2.ogg', 50, TRUE)
				return 0
			else
				return 0
	visible_message(span_danger("[mecha_attacker.name] has hit [src]."), null, null, COMBAT_MESSAGE_RANGE)
	..()
	return take_damage(mecha_attacker.force*3, mech_damtype, MELEE, play_soundeffect, get_dir(src, mecha_attacker)) // multiplied by 3 so we can hit objs hard but not be overpowered against mobs.

/obj/structure/window/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	if(!can_be_reached())
		return 0
	..()

/mob/living/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)	
	if(mecha_attacker.occupant.a_intent != INTENT_HARM)
		step_away(src,mecha_attacker)
		log_combat(mecha_attacker.occupant, src, "pushed", mecha_attacker)
		visible_message(span_warning("[mecha_attacker] pushes [src] out of the way."), null, null, 5)
		return 0
	
	if(mecha_attacker.selected?.melee_override && !mecha_attacker.bumpsmash)
		mecha_attacker.selected.action(src)
		return

	last_damage = "grand blunt trauma"
	mecha_attacker.do_attack_animation(src)
	if(mecha_attacker.damtype == "brute")
		var/throwtarget = get_edge_target_turf(mecha_attacker, get_dir(mecha_attacker, get_step_away(src, mecha_attacker)))
		src.throw_at(throwtarget, 5, 2, src)//one tile further than mushroom punch/psycho brawling
	switch(mecha_attacker.damtype)
		if(BRUTE)
			Unconscious(20)
			take_overall_damage(rand(mecha_attacker.force/2, mecha_attacker.force))
			playsound(src, 'sound/weapons/punch4.ogg', 50, 1)
		if(BURN)
			take_overall_damage(0, rand(mecha_attacker.force/2, mecha_attacker.force))
			playsound(src, 'sound/items/welder.ogg', 50, 1)
		if(TOX)
			mecha_attacker.mech_toxin_damage(src)
		else
			return
	updatehealth()
	visible_message(span_danger("[mecha_attacker.name] has hit [src]!"), \
					span_userdanger("[mecha_attacker.name] has hit [src]!"), null, COMBAT_MESSAGE_RANGE)
	//log_combat(mecha_attacker.occupant, src, "attacked", mecha_attacker, "(INTENT: [uppertext(mecha_attacker.occupant.a_intent)]) (DAMTYPE: [uppertext(mecha_attacker.damtype)])")
	..()

/mob/living/carbon/human/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	if(mecha_attacker.selected?.melee_override && !mecha_attacker.bumpsmash)
		mecha_attacker.selected.action(src)
	else if(mecha_attacker.occupant.a_intent == INTENT_HARM)
		mecha_attacker.do_attack_animation(src)
		if(mecha_attacker.damtype == BRUTE)
			step_away(src, mecha_attacker, 15)
		var/obj/item/bodypart/temp = get_bodypart(pick(BODY_ZONE_CHEST, BODY_ZONE_CHEST, BODY_ZONE_CHEST, BODY_ZONE_HEAD))
		if(temp)
			var/update = 0
			var/dmg = rand(mecha_attacker.force/2, mecha_attacker.force)
			switch(mecha_attacker.damtype)
				if(BRUTE)
					if(mecha_attacker.force > 20)
						Knockdown(1.5 SECONDS)//the victim could get up before getting hit again
						var/throwtarget = get_edge_target_turf(mecha_attacker, get_dir(mecha_attacker, get_step_away(src, mecha_attacker)))
						src.throw_at(throwtarget, 5, 2, src)//one tile further than mushroom punch/psycho brawling
					update |= temp.receive_damage(dmg, 0)
					playsound(src, 'sound/weapons/punch4.ogg', 50, 1)
				if(BURN)
					update |= temp.receive_damage(0, dmg)
					playsound(src, 'sound/items/welder.ogg', 50, 1)
				if(TOX)
					mecha_attacker.mech_toxin_damage(src)
				else
					return
			if(update)
				update_damage_overlays()
			updatehealth()

		visible_message(span_danger("[mecha_attacker.name] has hit [src]!"), \
								span_userdanger("[mecha_attacker.name] has hit [src]!"), null, COMBAT_MESSAGE_RANGE)
		log_combat(mecha_attacker.occupant, src, "attacked", mecha_attacker, "(INTENT: [uppertext(mecha_attacker.occupant.a_intent)]) (DAMTYPE: [uppertext(mecha_attacker.damtype)])")

	else
		..()

/*
*	Yog specific interactions
*/
/turf/closed/wall/clockwork/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	..()
	if(heated)
		to_chat(mecha_attacker.occupant, span_userdanger("The wall's intense heat completely reflects your [mecha_attacker.name]'s attack!"))
		mecha_attacker.take_damage(20, BURN)

/obj/structure/destructible/clockwork/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	if(mecha_attacker.occupant && is_servant_of_ratvar(mecha_attacker.occupant) && immune_to_servant_attacks)
		return FALSE
	return ..()

/obj/structure/destructible/cult/bloodstone/mech_melee_attack(obj/mecha/mecha_attacker, mob/living/user)
	mecha_attacker.force = round(mecha_attacker.force/6, 1) //damage is reduced since mechs deal triple damage to objects, this sets gygaxes to 15 (5*3) damage and durands to 21 (7*3) damage
	. = ..()
	mecha_attacker.force = initial(mecha_attacker.force)
