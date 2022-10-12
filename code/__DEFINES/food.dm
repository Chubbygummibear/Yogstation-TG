#define MEAT 		(1<<0)
#define VEGETABLES 	(1<<1)
#define RAW 		(1<<2)
#define JUNKFOOD 	(1<<3)
#define GRAIN 		(1<<4)
#define FRUIT 		(1<<5)
#define DAIRY 		(1<<6)
#define FRIED 		(1<<7)
#define ALCOHOL 	(1<<8)
#define SUGAR 		(1<<9)
#define GROSS 		(1<<10)
#define TOXIC 		(1<<11)
#define PINEAPPLE	(1<<12)
#define BREAKFAST	(1<<13)
#define CLOTH 		(1<<14)
#define GRILLED		(1<<15)
#define EGG			(1<<16) // for eggpeople, to nerf egg-cannibalism
#define CHOCOLATE	(1<<17) //cat
#define SEAFOOD		(1<<18)
#define MICE		(1<<19) //disliked/liked by anything that dislikes/likes any of RAW, MEAT, or GROSS, except felinids
#define NUTS 		(1<<20)

#define DRINK_NICE	1
#define DRINK_GOOD	2
#define DRINK_VERYGOOD	3
#define DRINK_FANTASTIC	4
#define FOOD_AMAZING 5

///bastardized version of tg's IS_EDIBLE that checks for the edible component. however since we lack that, this just checks if the atom is a type or subtype of food
#define IS_EDIBLE(O) (istype(O,/obj/item/reagent_containers/food))

/// Flavour defines (also names) for GLOB.ice_cream_flavours list access. Safer from mispelling than plain text.
#define ICE_CREAM_VANILLA "vanilla"
#define ICE_CREAM_CHOCOLATE "chocolate"
#define ICE_CREAM_STRAWBERRY "strawberry"
#define ICE_CREAM_BLUE "blue"
#define ICE_CREAM_MOB "mob"
#define ICE_CREAM_CUSTOM "custom"
#define ICE_CREAM_BLAND "bland"

#define DEFAULT_MAX_ICE_CREAM_SCOOPS 3
// the vertical distance in pixels from an ice cream scoop and another.
#define ICE_CREAM_SCOOP_OFFSET 4
