extends TestCase


func _mission(objective: InfiltrationMissionData.Objective = InfiltrationMissionData.Objective.INFILTRATION) -> InfiltrationMissionData:
	var mission: InfiltrationMissionData = InfiltrationMissionData.new()
	mission.objective = objective
	mission.map = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier")])
	(mission.map as BlasterOpsArenaData).enemies_alerted = false
	mission.extraction = Vector2(1300, 700)
	return mission


func _sim(data: InfiltrationMissionData = null, weapon: BlasterData = null) -> BlasterOpsSimulation:
	var mission: InfiltrationMissionData = data if data != null else _mission()
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.equipment(DuelMode.character(&"guardian"), 0)
	equipment.blaster = weapon
	return InfiltrationMode.new(mission, DuelMode.character(&"guardian"), equipment).create_simulation()


func _step(sim: BlasterOpsSimulation, command: InfiltrationIntent, ticks: int) -> void:
	for index in ticks:
		sim.step(command)
		command.pressed = 0


func test_infiltration_dodge_emits_noise_and_preserves_precision_refund() -> void:
	var sim: BlasterOpsSimulation = _sim()
	sim.targets[0].position = sim.player.position + Vector2(180, 0)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	command.pressed = Intent.Command.DODGE
	command.movement = Vector2.RIGHT
	sim.step(command)
	assert_eq(sim.state.dodge_age, 0)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.SUSPICIOUS)
	var heard: bool = false
	for index in sim.event_count:
		var event: InfiltrationEvent = sim.events[index]
		if event.type == InfiltrationEvent.Type.NOISE_EMITTED:
			heard = event.amount == sim.operations.dodge_noise
	assert_true(heard)
	sim.state.dodge_age = sim.operations.invulnerable_from
	var bolt: BlasterOpsBolt = BlasterOpsBolt.new()
	bolt.data = load("res://data/infiltration/bolts/trooper_bolt.tres")
	bolt.active = true
	bolt.owner = 1
	bolt.damage = 7.0
	sim._resolve_player_bolt(bolt)
	assert_eq(sim.state.dodge_cooldown, 0)
	assert_almost(sim.player.health, sim.config.health)


func test_powers_have_long_stealth_cooldown_and_alert_only_visible_witnesses() -> void:
	for objective in InfiltrationMissionData.Objective.values():
		var sim: BlasterOpsSimulation = _sim(_mission(objective as InfiltrationMissionData.Objective))
		sim.loadout.power = BlasterOpsTraining.POWERS[2]
		sim.targets[0].position = sim.player.position + Vector2(280, 0)
		sim.targets[0].aim = Vector2.LEFT
		var command: InfiltrationIntent = InfiltrationIntent.new()
		command.pressed = Intent.Command.POWER
		sim.step(command)
		var multiplier: float = 3.0 if objective == InfiltrationMissionData.Objective.INFILTRATION else 1.0
		assert_eq(sim.state.power_cooldown, Ticks.from_seconds(sim.loadout.power.cooldown * multiplier))
		_step(sim, command, sim.state.power_ticks)
		assert_gt(sim.state.barrier_health, 0.0)
		if objective == InfiltrationMissionData.Objective.INFILTRATION:
			assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.ALERTED)
		else:
			assert_ne(sim.targets[0].awareness, InfiltrationActor.Awareness.ALERTED)


func test_power_noise_does_not_reveal_a_hidden_player_through_a_wall() -> void:
	var data: InfiltrationMissionData = _mission()
	data.map.rows[6] = "#...#..................#"
	var sim: BlasterOpsSimulation = _sim(data)
	sim.targets[0].position = Vector2(352, 416)
	sim.loadout.power = BlasterOpsTraining.POWERS[2]
	sim._release_power()
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.SUSPICIOUS)
	assert_almost(sim.targets[0].health, sim.target_data[0].health)


func test_power_kills_count_against_no_takedowns_and_do_not_hurt_prisoners() -> void:
	var data: InfiltrationMissionData = _mission()
	data.prisoner_spawns = PackedVector2Array([data.map.player_spawn + Vector2(100, 40)])
	data.minimum_prisoners = 1
	var sim: BlasterOpsSimulation = _sim(data)
	sim.targets[0].position = sim.player.position + Vector2(150, 0)
	sim.targets[0].health = 1.0
	sim._release_power()
	assert_almost(sim.targets[0].health, 0.0)
	assert_eq(sim.mission.takedowns, 1)
	assert_eq(sim.mission.bonuses(sim.tick) & InfiltrationMissionState.Bonus.NO_TAKEDOWNS, 0)
	assert_almost(sim.prisoners[0].health, sim.config.prisoner_health)
	assert_eq(sim.prisoners[0].position, data.prisoner_spawns[0])


func test_enemy_bolts_hurt_freed_prisoners_and_minimum_failure_beats_extraction() -> void:
	var data: InfiltrationMissionData = _mission()
	data.prisoner_spawns = PackedVector2Array([data.map.player_spawn + Vector2(100, 0)])
	data.minimum_prisoners = 1
	var sim: BlasterOpsSimulation = _sim(data, BlasterOpsTraining.PISTOL.blaster)
	sim.prisoners[0].health = 1.0
	sim.mission.recruited[0] = 1
	var bolt: BlasterOpsBolt = sim._spawn_bolt(-1, sim.loadout.blaster.bolt, Vector2.RIGHT)
	bolt.owner = 1
	bolt.shooter = 0
	_step(sim, InfiltrationIntent.new(), 6)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN)
	var snapshot: Dictionary = sim.capture()
	_step(sim, InfiltrationIntent.new(), 10)
	assert_eq(sim.capture(), snapshot)


func test_shared_core_replays_dodge_power_panels_and_prisoners_from_snapshot() -> void:
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[1]
	var sim: BlasterOpsSimulation = _sim(data)
	var snapshot: Dictionary = sim.capture()
	var command: InfiltrationIntent = InfiltrationIntent.new()
	var events: Array[int] = []
	var expected: Dictionary
	for replay in 2:
		if replay == 1:
			sim.restore(snapshot)
		for tick in 120:
			command.clear()
			command.aim = Vector2.RIGHT
			command.movement = Vector2.RIGHT
			command.held = InfiltrationIntent.SNEAK
			command.pressed = Intent.Command.DODGE if tick == 0 else Intent.Command.POWER if tick == 20 else InfiltrationIntent.INTERACT if tick == 90 else 0
			sim.step(command)
			if replay == 0:
				events.append(hash(sim.capture()))
			else:
				assert_eq(hash(sim.capture()), events[tick])
		if replay == 0:
			expected = sim.capture()
	assert_eq(sim.capture(), expected)


func test_saber_only_can_destroy_cover_and_complete_a_former_shooter_arena() -> void:
	var data: InfiltrationMissionData = _mission(InfiltrationMissionData.Objective.INCURSION)
	data.map = BlasterOpsFixture.arena([], true)
	data.extraction = Vector2(480, 416)
	data.extraction_radius = 25.0
	var sim: BlasterOpsSimulation = _sim(data)
	sim.player.position = Vector2(342, 416)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	command.aim = Vector2.RIGHT
	command.held = Intent.Command.LIGHT
	_step(sim, command, 90)
	assert_eq(sim.loadout.blaster, null)
	assert_false(sim.map.is_solid(6, 6))
	assert_almost(sim.state.heat, 0.0)
	command.clear()
	command.movement = Vector2.RIGHT
	_step(sim, command, 50)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)


func test_f_strikes_if_takedown_is_unavailable_and_primary_is_a_saber_without_blaster() -> void:
	for command_bit in [Intent.Command.LIGHT, Intent.Command.HEAVY]:
		var sim: BlasterOpsSimulation = _sim()
		sim.targets[0].position = sim.player.position + Vector2(64, 0)
		sim.targets[0].awareness = InfiltrationActor.Awareness.ALERTED
		var command: InfiltrationIntent = InfiltrationIntent.new()
		command.pressed = command_bit
		command.aim = Vector2.RIGHT
		_step(sim, command, 20)
		assert_lt(sim.targets[0].health, sim.target_data[0].health)
		assert_eq(sim.state.burst_left, 0)


func test_one_handed_rifle_and_saber_only_presentation_states() -> void:
	var pistol: BlasterOpsLoadout = BlasterOpsTraining.PISTOL
	var rifle: BlasterOpsLoadout = BlasterOpsTraining.RIFLE
	var saber: BlasterOpsLoadout = BlasterOpsTraining.equipment(DuelMode.character(&"guardian"), 0)
	for guard in [false, true]:
		for striking in [false, true]:
			assert_eq(BlasterOpsView.weapon_state(pistol, guard, striking), BlasterOpsView.WeaponState.BLADE | BlasterOpsView.WeaponState.BLASTER)
			assert_eq(BlasterOpsView.weapon_state(saber, guard, striking), BlasterOpsView.WeaponState.BLADE)
			var expected: int = BlasterOpsView.WeaponState.BLADE if guard or striking else BlasterOpsView.WeaponState.BLASTER | BlasterOpsView.WeaponState.BELT_HILT | BlasterOpsView.WeaponState.SUPPORT_HAND
			assert_eq(BlasterOpsView.weapon_state(rifle, guard, striking), expected)
	assert_eq(BlasterOpsView.weapon_state(pistol, false, false, true), BlasterOpsView.WeaponState.BLADE)


func test_story_equipped_weapon_keeps_patterns_without_mutating_catalog_or_charging_credits() -> void:
	for id in ["holster_pistol", "thigh_revolver", "lumbar_carbine", "back_rifle", "back_sniper"]:
		var weapon: BlasterData = load("res://data/blasters/%s.tres" % id)
		var sim: BlasterOpsSimulation = _sim(null, weapon)
		var command: InfiltrationIntent = InfiltrationIntent.new()
		command.held = Intent.Command.LIGHT
		command.aim = Vector2.RIGHT
		var count: int = 0
		var previous: int = -1
		for tick in 1 + maxi(weapon.shot_count - 1, 0) * maxi(Ticks.from_seconds(weapon.shot_interval), 1):
			sim.step(command)
			for index in sim.event_count:
				if sim.events[index].type == InfiltrationEvent.Type.SHOT_FIRED and sim.events[index].source == 0:
					if previous >= 0:
						assert_eq(tick - previous, Ticks.from_seconds(weapon.shot_interval), id)
					previous = tick
					count += 1
		assert_eq(count, maxi(weapon.shot_count, 1), id)
		assert_eq(sim.loadout.blaster, weapon)
		assert_true(sim.bolts[0].data == weapon.bolt)
		assert_almost((sim.bolts[0] as BlasterOpsBolt).damage, weapon.bolt.damage * sim.loadout.damage_scale)


func test_guard_and_release_cancel_remaining_pattern_shots() -> void:
	for held in [0, Intent.Command.BLOCK]:
		var sim: BlasterOpsSimulation = _sim(null, BlasterOpsTraining.RIFLE.blaster)
		var command: InfiltrationIntent = InfiltrationIntent.new()
		command.held = Intent.Command.LIGHT
		sim.step(command)
		assert_eq(sim.state.burst_left, 2)
		command.held = held
		_step(sim, command, 15)
		assert_eq(sim.state.burst_left, 0)
		assert_true(sim.state.heat < sim.loadout.heat_per_shot * sim.loadout.blaster.vigor_multiplier * 2)


func test_a_story_protagonist_brings_its_arsenal_weapon_without_spending_operation_credits() -> void:
	var story: StoryCampaign = StoryCampaign.create("Iria", 0, 0, 0, 0, 1)
	story.credits = 500
	var rifle: BlasterData = BlasterOpsTraining.RIFLE.blaster
	assert_true(story.buy_blaster(rifle))
	assert_true(story.equip_blaster(rifle))
	var before: Dictionary = story.to_dict()
	var hero: CharacterData = story.protagonist()
	var mode: InfiltrationMode = InfiltrationMode.new(_mission(), hero)
	var sim: BlasterOpsSimulation = mode.create_simulation()
	assert_eq(sim.loadout.blaster, rifle)
	assert_eq(sim.loadout.blaster.shot_count, 3)
	assert_eq(story.to_dict(), before)


func test_snapshot_during_a_rifle_burst_preserves_heat_shot_spacing_and_projectiles() -> void:
	var sim: BlasterOpsSimulation = _sim(null, BlasterOpsTraining.RIFLE.blaster)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	command.held = Intent.Command.LIGHT
	sim.step(command)
	var snapshot: Dictionary = sim.capture()
	_step(sim, command, 25)
	var expected: Dictionary = sim.capture()
	sim.restore(snapshot)
	_step(sim, command, 25)
	assert_eq(sim.capture(), expected)


func test_old_mission_resources_default_to_infiltration_and_keep_previews_and_ids() -> void:
	for data in InfiltrationMode.MISSIONS:
		assert_eq(data.objective, InfiltrationMissionData.Objective.INFILTRATION)
		assert_true(data.preview != null)
		assert_gt(data.required_prisoners(), 0)
	var incursion: InfiltrationMissionData = _mission(InfiltrationMissionData.Objective.INCURSION)
	incursion.prisoner_spawns = PackedVector2Array([Vector2(300, 300)])
	assert_eq(incursion.required_prisoners(), 0)


func test_both_namespaces_share_defaults_remapping_and_reference_lifetimes() -> void:
	InputBindings.apply_defaults()
	var duel: Array[InputEvent] = InputMap.action_get_events(&"p1_light_attack")
	InfiltrationBindings.install()
	BlasterOpsBindings.install()
	for suffix in InfiltrationBindings.ALIASES:
		var legacy: Array[InputEvent] = InputMap.action_get_events("infiltration_" + suffix)
		var shared: Array[InputEvent] = InputMap.action_get_events(BlasterOpsBindings.PREFIX + InfiltrationBindings.ALIASES[suffix])
		assert_eq(legacy.size(), shared.size())
		for index in legacy.size():
			assert_eq(legacy[index].as_text(), shared[index].as_text())
	for suffix in BlasterOpsBindings.KEYS:
		for code in BlasterOpsBindings.KEYS[suffix]:
			assert_false(code in [KEY_U, KEY_I, KEY_O, KEY_P, KEY_J, KEY_K, KEY_L, KEY_H, KEY_N, KEY_M])
	BlasterOpsBindings.apply({"strike": [KEY_Z]}, {})
	InfiltrationBindings.refresh()
	assert_eq(InputMap.action_get_events(&"infiltration_takedown")[0].physical_keycode, KEY_Z)
	InfiltrationBindings.uninstall()
	assert_true(InputMap.has_action(&"blaster_ops_strike"))
	BlasterOpsBindings.uninstall()
	assert_false(InputMap.has_action(&"blaster_ops_strike"))
	assert_eq(InputMap.action_get_events(&"p1_light_attack"), duel)


func test_telegraphed_enemies_follow_patrols_and_can_activate_mission_panels() -> void:
	var data: InfiltrationMissionData = _mission()
	var panel: InfiltrationPanelData = InfiltrationPanelData.new()
	panel.position = data.map.enemies[0].position
	data.map.panels.append(panel)
	data.map.enemies[0].route = PackedVector2Array([panel.position, panel.position + Vector2(64, 0)])
	var sim: BlasterOpsSimulation = _sim(data)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	var enemies: Array[InfiltrationIntent] = [InfiltrationIntent.new()]
	sim.step(command, enemies)
	assert_eq(sim.targets[0].waypoint, 1)
	InfiltrationPerception.alert(sim, 0, sim.player.position)
	enemies[0].panel = 0
	for tick in Ticks.from_seconds(sim.config.panel_activation_seconds):
		sim.step(command, enemies)
	assert_true(sim.panels[0].active)
	assert_true(sim.mission.alarm_raised)


func test_all_six_rescue_missions_finish_with_the_same_intent_only_pilot() -> void:
	for index in InfiltrationMode.MISSIONS.size():
		var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[index]
		var sim: BlasterOpsSimulation = _sim(data)
		var pilot: InfiltrationRoute = InfiltrationRoute.new(sim, index != 3)
		var enemies: BlasterOpsEnemyController = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
		var escorts: InfiltrationEscortController = InfiltrationEscortController.new(sim)
		for tick in 72000:
			sim.step(pilot.produce(sim), enemies.produce_all(sim), escorts.produce_all(sim))
			if sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
				break
		assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED, String(data.id))
		assert_true(sim.mission.rescued() >= data.required_prisoners(), String(data.id))
