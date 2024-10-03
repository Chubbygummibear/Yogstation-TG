SUBSYSTEM_DEF(tts)
	name = "Text To Speech"
	wait = 0.05 SECONDS
	priority = FIRE_PRIORITY_TTS
	init_order = INIT_ORDER_TTS
	runlevels = RUNLEVEL_LOBBY | RUNLEVEL_SETUP | RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	/// An associative list of mobs mapped to a list of their own /datum/tts_request_target
	var/list/queued_tts_messages = list()

	/// Whether TTS is enabled or not
	var/tts_enabled = FALSE


	/// Used to calculate the average time it takes for a tts message to be received from the http server
	/// For tts messages which time out, it won't keep tracking the tts message and will just assume that the message took
	/// 7 seconds (or whatever the value of message_timeout is) to receive back a response.
	var/average_tts_messages_time = 0

/datum/controller/subsystem/tts/vv_edit_var(var_name, var_value)
	// tts being enabled depends on whether it actually exists
	if(NAMEOF(src, tts_enabled) == var_name)
		return FALSE
	return ..()

/datum/controller/subsystem/tts/stat_entry(msg)
	msg = "Queued:[length(queued_tts_messages)]|Avg:[average_tts_messages_time]"
	return ..()

/datum/controller/subsystem/tts/Initialize()
	if(!CONFIG_GET(flag/tts_enabled))
		return SS_INIT_NO_NEED
	tts_enabled = TRUE
	return SS_INIT_SUCCESS

/datum/controller/subsystem/tts/proc/play_tts(target, list/listeners, list/audio_sequence, datum/language/language, range = 7, volume_offset = 0)
	var/turf/turf_source = get_turf(target)
	if(!turf_source)
		return

	var/channel = SSsounds.random_available_channel()
	message_admins("playing tts message from [target] to [length(listeners)] listeners of message length [length(audio_sequence)]")
	for(var/mob/listening_mob in listeners | SSmobs.dead_players_by_zlevel[turf_source.z])//observers always hear through walls
		if(QDELING(listening_mob))
			stack_trace("TTS tried to play a sound to a deleted mob.")
			continue
		if(!listening_mob.client)
			continue
		var/volume_to_play_at = listening_mob.client?.prefs.read_preference(/datum/preference/numeric/sound_tts_volume)
		var/tts_pref = listening_mob.client?.prefs.read_preference(/datum/preference/choiced/sound_tts)
		if(volume_to_play_at == 0 || (tts_pref == TTS_SOUND_OFF))
			continue
		var/sound_volume = ((listening_mob == target)? 60 : 85) + volume_offset
		sound_volume = sound_volume * (volume_to_play_at / 100)
		message_admins("playing tts message to [listening_mob] with volume [sound_volume]")
		// var/datum/language_holder/holder = listening_mob.get_language_holder()
		// if(!holder.has_language(language))
		// 	continue
		for(var/sound/audio_bit in audio_sequence)
			audio_bit.channel = channel
			audio_bit.volume = sound_volume
			message_admins("audio_bit file: [audio_bit.file], volume [audio_bit.volume]")
			//SEND_SOUND(listening_mob, audio_bit)
			if(get_dist(listening_mob, turf_source) <= range)
				listening_mob.playsound_local(
					turf_source,
					vol = sound_volume,
					falloff_exponent = SOUND_FALLOFF_EXPONENT,
					channel = channel,
					pressure_affected = TRUE,
					S = audio_bit,
					max_distance = SOUND_RANGE,
					falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE,
					distance_multiplier = 1,
					use_reverb = TRUE,
					wait = TRUE
				)

// Need to wait for all HTTP requests to complete here because of a rustg crash bug that causes crashes when dd restarts whilst HTTP requests are ongoing.
/datum/controller/subsystem/tts/Shutdown()
	tts_enabled = FALSE
	// for(var/datum/tts_request/data in in_process_http_messages)
	// 	var/datum/http_request/request = data.request
	// 	var/datum/http_request/request_blips = data.request_blips
	// 	UNTIL(request.is_complete() && request_blips.is_complete())

#define TTS_ARBRITRARY_DELAY "arbritrary delay"

/datum/controller/subsystem/tts/fire(resumed)
	if(!tts_enabled)
		flags |= SS_NO_FIRE
		return
	
	var/list/processing_messages = queued_tts_messages
	//while(processing_messages.len)
	for(var/datum/tts_request/tts_message in processing_messages)
		if(MC_TICK_CHECK)
			return
		
		// var/datum/tts_target = queued_tts_messages[queued_tts_messages.len]
		// var/list/data = queued_tts_messages[tts_target]
		
		if(QDELETED(tts_message.target))
			queued_tts_messages -= tts_message
			continue

		//var/datum/tts_request/current_target = data[1]
		play_tts(tts_message.target, tts_message.listeners, tts_message.sound_sequence, tts_message.language, tts_message.message_range, tts_message.volume_offset)
		average_tts_messages_time = MC_AVERAGE(average_tts_messages_time, world.time - tts_message.start_time)
		queued_tts_messages -= tts_message


/datum/controller/subsystem/tts/proc/queue_tts_message(datum/target, message, datum/language/language, speaker, filter, list/listeners, local = FALSE, message_range = 7, volume_offset = 0, pitch = 0, special_filters = "")
	if(!tts_enabled)
		return

	message_admins("new tts request with message [message]")
	var/shell_scrubbed_input = tts_speech_filter(message)
	shell_scrubbed_input = copytext(shell_scrubbed_input, 1, 300)
	var/identifier = "[sha1(speaker + num2text(pitch) + special_filters + shell_scrubbed_input)].[world.time]"
	// if(isliving(target))
	// 	var/mob/living/living_speaker = target
	// 	listeners += living_speaker
	
	var/datum/tts_request/current_request = new /datum/tts_request(identifier, shell_scrubbed_input, target, local, language, message_range, volume_offset, listeners, pitch)
	//var/list/player_queued_tts_messages = queued_tts_messages[target]
	current_request.prepare_sound()
	queued_tts_messages += current_request
	message_admins("request added to queue. Queue length: [length(queued_tts_messages)]")
	// if(!player_queued_tts_messages)
	// 	player_queued_tts_messages = list()
	// 	queued_tts_messages[target] = player_queued_tts_messages
	// player_queued_tts_messages += current_request
	

/// A struct containing information on an individual player or mob who has made a TTS request
/datum/tts_request
	/// The mob to play this TTS message on
	var/mob/target
	/// The people who are going to hear this TTS message
	/// Does nothing if local is set to TRUE
	var/list/listeners
	/// The language to limit this TTS message to
	var/datum/language/language
	/// The message itself
	var/message
	/// The message identifier
	var/identifier
	/// The volume offset to play this TTS at.
	var/volume_offset = 0
	/// Whether this TTS message should be sent to the target only or not.
	var/local = FALSE
	/// The message range to play this TTS message
	var/message_range = 7
	/// The time at which this request was started
	var/start_time
	/// We can't combine sound files in byond, so we make a list of sound datums to play
	var/list/sound_sequence = list()
	/// The audio length of this tts request.
	var/audio_length
	/// When the audio file should play at the minimum
	var/when_to_play = 0
	/// Whether this request was timed out or not
	var/timed_out = FALSE
	/// Does this use blips during local generation or not?
	var/use_blips = FALSE
	/// What's the pitch adjustment?
	var/pitch = 0


/datum/tts_request/New(identifier, message, target, local, datum/language/language, message_range, volume_offset, list/listeners, pitch)
	. = ..()
	src.identifier = identifier
	src.message = message
	src.language = language
	src.target = target
	src.local = local
	src.message_range = message_range
	src.volume_offset = volume_offset
	src.listeners = listeners
	src.pitch = pitch
	start_time = world.time

/datum/tts_request/proc/prepare_sound()
	//message_admins("preparing tts sound for [target] with message [message]")
	var/list/beep_noises = list(
		'yogstation/sound/voice/spokenletters/bebebese.wav',
		'yogstation/sound/voice/spokenletters/bebebese_slow.wav',
		'yogstation/sound/voice/spokenletters/451.wav')
	
	for(var/char = 1, char <= length(message), char++)
		var/file_to_use
		var/letter = lowertext(message[char])
		//message_admins("letter is [letter]")
		if(is_alpha(letter))
			file_to_use = "yogstation/sound/voice/spokenletters/[letter].wav" 
		else
			file_to_use = pick(beep_noises) 
		var/sound/char_sound = new(file_to_use)
		char_sound.frequency = pitch
		//char_sound.pitch = pitch
		char_sound.wait = TRUE
		char_sound.repeat = FALSE
		sound_sequence += char_sound
