#define CONE_WAFFLE "waffle"
#define CONE_CHOC "chocolate"

/obj/machinery/icecream_cart
	name = "ice cream cart"
	desc = "Ding-aling ding dong. Get your Nanotrasen-approved ice cream!"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "icecream_cart"
	density = TRUE
	anchored = FALSE
	use_power = NO_POWER_USE
	layer = BELOW_OBJ_LAYER
	max_integrity = 300
	var/max_volume = 100
	var/list/inventory = list(
		ICE_CREAM_VANILLA = 0, 
		ICE_CREAM_CHOCOLATE = 0, 
		ICE_CREAM_STRAWBERRY = 0, 
		ICE_CREAM_BLUE = 0, 
		CONE_WAFFLE = 0,
		CONE_CHOC = 0
	)

	var/selected_flavor = ICE_CREAM_VANILLA
	var/selected_cone = CONE_WAFFLE

	var/list/flavors = list(
		ICE_CREAM_VANILLA, 
		ICE_CREAM_CHOCOLATE, 
		ICE_CREAM_STRAWBERRY, 
		ICE_CREAM_BLUE, 
		ICE_CREAM_CUSTOM
	)

	var/list/cones = list(
		CONE_WAFFLE,
		CONE_CHOC
	)

	var/production_coefficient = 1
	var/flavor_multiplier = 1

/obj/machinery/icecream_cart/proc/get_ingredient_list(type)
	var/icecream_ingredients = list(/datum/reagent/consumable/milk, /datum/reagent/consumable/ice)
	var/cone_ingredients = list(/datum/reagent/consumable/flour, /datum/reagent/consumable/sugar)
	switch(type)
		if(ICE_CREAM_VANILLA)
			icecream_ingredients += /datum/reagent/consumable/vanilla
			return icecream_ingredients
		if(ICE_CREAM_CHOCOLATE)
			icecream_ingredients += /datum/reagent/consumable/coco
			return icecream_ingredients
		if(ICE_CREAM_STRAWBERRY)
			icecream_ingredients += /datum/reagent/consumable/berryjuice
			return icecream_ingredients
		if(ICE_CREAM_BLUE)
			icecream_ingredients +=/datum/reagent/consumable/ethanol/singulo
			return icecream_ingredients
		if(CONE_WAFFLE)
			return cone_ingredients
		if(CONE_CHOC)
			cone_ingredients += /datum/reagent/consumable/coco
			return cone_ingredients

/obj/machinery/icecream_cart/Initialize()
	. = ..()
	create_reagents(max_volume, NO_REACT | OPENCONTAINER)

/obj/machinery/icecream_cart/RefreshParts()
	reagents.maximum_volume = 0
	for(var/obj/item/reagent_containers/glass/our_beaker in component_parts)
		reagents.maximum_volume += our_beaker.volume
		our_beaker.reagents.trans_to(src, our_beaker.reagents.total_volume)
	production_coefficient = 1.25
	for(var/obj/item/stock_parts/manipulator/our_manipulator in component_parts)
		production_coefficient -= our_manipulator.rating * 0.25
	production_coefficient = clamp(production_coefficient, 0, 1) // coefficient goes from 1 -> 0.75 -> 0.5 -> 0.25

/obj/machinery/icecream_cart/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Storing up to [span_bold("[reagents.maximum_volume]u")] of delicious ice cream.")
		. += span_notice("Reagent consumption rate at [span_bold("[production_coefficient*100]%")], and has a flavor multiplier of [span_bold("[flavor_multiplier*100]%")].")


/obj/machinery/icecream_cart/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IceCreamCart", name)
		ui.open()

/obj/machinery/icecream_cart/ui_data(mob/user, datum/tgui/ui)
	var/list/data = list()
	for(var/datum/reagent/reagent_id in reagents.reagent_list)
		var/list/reagent_data = list(
			reagent_name = reagent_id.name,
			reagent_amount = reagent_id.volume,
			reagent_type = reagent_id.type
		)
		data["reagents"] += list(reagent_data)
	data["inventory"] = list()
	for(var/item in inventory)
		data["inventory"] += list("item" = item, "stock" = inventory[item])
	data["total_reagents"] = reagents.total_volume
	data["max_reagents"] = reagents.maximum_volume

	data["flavors"] = flavors
	data["cones"] = cones

	


	return data

/obj/machinery/icecream_cart/ui_act(action,params)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_cone")
			selected_cone = sanitize_inlist(params["cone_type"],typesof(/obj/item/reagent_containers/food/snacks/icecream),CONE_WAFFLE)

		if("make")
			make(params["design_id"])

		if("dispense")
			make(params["design_id"])

		if("empty_reagent")
			reagents.del_reagent(text2path(params["reagent_type"]))
			. = TRUE
	
	return

/obj/machinery/icecream_cart/attackby(obj/item/user_item, mob/user, params)
	if(istype(user_item, /obj/item/reagent_containers/food/snacks/icecream))
		var/obj/item/reagent_containers/food/snacks/icecream/I = user_item
		if(!I.ice_creamed)
			if(!isemptylist(inventory))
				visible_message("[icon2html(src, viewers(src))] [span_info("[user] scoops delicious [selected_flavor] ice cream into [I].")]")
				inventory[selected_flavor] -= 1
				I.add_ice_cream(selected_flavor)
				if(I.reagents.total_volume < 10)
					I.reagents.add_reagent(/datum/reagent/consumable/sugar, 10 - I.reagents.total_volume)
			else
				to_chat(user, span_warning("There is not enough ice cream left!"))
		else
			to_chat(user, span_notice("[user_item] already has ice cream in it."))
		return 1
	else if(user_item.is_drainable())
		return
	if(default_deconstruction_screwdriver(user, "icecream_cart", "icecream_cart", user_item))
		ui_close(user)
		return

	if(panel_open && default_deconstruction_crowbar(user_item))
		return

	if(user.a_intent == INTENT_HARM) //so we can hit the machine
		return ..()

/obj/machinery/icecream_cart/proc/make(mob/user, make_type, amount)
	for(var/R in get_ingredient_list(make_type))
		if(reagents.has_reagent(R, amount))
			continue
		amount = 0
		break
	if(amount)
		for(var/R in get_ingredient_list(make_type))
			reagents.remove_reagent(R, amount)
		inventory[make_type] += amount
		if(make_type > 4)
			src.visible_message(span_info("[user] cooks up some [selected_flavor] cones."))
		else
			src.visible_message(span_info("[user] whips up some [selected_flavor] icecream."))
	else
		to_chat(user, span_warning("You don't have the ingredients to make this!"))


/obj/machinery/icecream_cart/on_deconstruction()
	for(var/obj/item/reagent_containers/glass/our_beaker in component_parts)
		reagents.trans_to(our_beaker, our_beaker.reagents.maximum_volume)
	..()

/obj/machinery/icecream_cart/kitchen
	var/static/list/icecream_cart_reagents = list(
		/datum/reagent/consumable/milk = 5,
		/datum/reagent/consumable/flour = 5,
		/datum/reagent/consumable/sugar = 5,
		/datum/reagent/consumable/ice = 5,
		/datum/reagent/consumable/coco = 5,
		/datum/reagent/consumable/vanilla = 5,
		/datum/reagent/consumable/berryjuice = 5,
		/datum/reagent/consumable/ethanol/singulo = 5)

/obj/machinery/icecream_cart/kitchen/Initialize()
	. = ..()
	for(var/reagent in icecream_cart_reagents)
		reagents.add_reagent(reagent, icecream_cart_reagents[reagent])	

#undef CONE_WAFFLE
#undef CONE_CHOC
