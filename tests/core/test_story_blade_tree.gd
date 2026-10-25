extends TestCase

const CUT: MoveData = preload("res://data/techniques/projected_cut.tres")


func _story(style: int = 0) -> StoryCampaign:
	return StoryCampaign.create("Iria", 0, style, 0, 0, 1)


func _buy_kit(story: StoryCampaign) -> StoryPowerTree:
	story.skill_points = 10
	var tree: StoryPowerTree = StoryPowerTree.new(story, true)
	for index in range(1, tree.nodes.size()):
		assert_true(tree.buy(index))
	return tree


func test_blade_nodes_resolve_the_three_styles_and_existing_resources() -> void:
	for style in 3:
		var story: StoryCampaign = _story(style)
		var base: CharacterData = story.style_character()
		var tree: StoryPowerTree = StoryPowerTree.new(story, true)
		assert_eq(tree.nodes.size(), 5)
		assert_eq(tree.nodes[0].technique, base.technique_forward)
		assert_eq(tree.nodes[1].technique, base.technique_back)
		assert_eq(tree.nodes[2].technique, base.technique_air)
		assert_eq(tree.nodes[3].ability, base.ability)
		assert_eq(tree.nodes[4].technique, CUT)
		assert_true(tree.nodes[0].technique != null)
		assert_true(tree.nodes[2].technique != null)
		for index in tree.nodes.size():
			assert_eq(tree.nodes[index].definition.cost, [0, 2, 2, 3, 3][index])
			assert_eq(tree.nodes[index].definition.parent, index - 1)
			assert_true(tree.nodes[index].icon != null)
	assert_true(DuelFixture.character(&"heron").technique_forward == null)
	assert_true(DuelFixture.GUARDIAN.technique_air == null)


func test_new_campaign_only_has_the_forward_technique() -> void:
	for style in 3:
		var story: StoryCampaign = _story(style)
		var hero: CharacterData = story.protagonist()
		assert_eq(hero.technique_forward, story.style_character().technique_forward)
		assert_true(hero.technique_back == null)
		assert_true(hero.technique_air == null)
		assert_true(hero.ability == null)
		assert_eq(story.blade_bought.size(), 1)
		var restored: StoryCampaign = StoryCampaign.from_dict(story.to_dict())
		assert_eq(restored.blade_bought, story.blade_bought)
		assert_true(restored.protagonist().ability == null)


func test_each_purchase_releases_the_kit_and_spends_shared_points() -> void:
	var story: StoryCampaign = _story()
	story.skill_points = 10
	var blade: StoryPowerTree = StoryPowerTree.new(story, true)
	var powers: StoryPowerTree = StoryPowerTree.new(story)
	assert_false(blade.buy(3))
	assert_true(blade.buy(1))
	assert_true(story.protagonist().technique_back != null)
	assert_true(story.protagonist().technique_air == null)
	assert_eq(story.skill_points, 8)
	assert_true(powers.buy(1))
	assert_eq(story.skill_points, 7)
	assert_true(blade.buy(2))
	assert_true(story.protagonist().technique_air != null)
	assert_true(blade.buy(3))
	assert_true(story.protagonist().ability != null)
	assert_false(blade.buy(4))
	assert_eq(story.skill_points, 2)
	assert_false(blade.buy(3))


func test_projected_cut_replaces_one_chosen_slot_and_can_restore_style() -> void:
	for style in 3:
		var story: StoryCampaign = _story(style)
		var tree: StoryPowerTree = _buy_kit(story)
		assert_eq(story.skill_points, 0)
		assert_false(tree.equip(4, -1))
		assert_false(tree.equip(4, 3))
		for slot in 3:
			assert_true(tree.equip(4, slot))
			var hero: CharacterData = story.protagonist()
			var original: CharacterData = story.style_character()
			var fields: Array[StringName] = [&"technique_forward", &"technique_back", &"technique_air"]
			for other in 3:
				assert_eq(hero.get(fields[other]), CUT if other == slot else original.get(fields[other]))
			assert_eq(tree.nodes[4].state, StoryPowerTree.State.EQUIPPED)
			assert_eq(tree.nodes[slot].state, StoryPowerTree.State.LEARNED)
			var restored: StoryCampaign = StoryCampaign.from_dict(story.to_dict())
			assert_eq(restored.projected_cut_slot, slot)
			assert_eq(restored.protagonist().get(fields[slot]), CUT)
			assert_true(tree.equip(slot, slot))
			assert_eq(story.projected_cut_slot, -1)
			assert_eq(story.protagonist().get(fields[slot]), original.get(fields[slot]))


func test_legacy_save_keeps_all_four_style_nodes_and_no_projected_cut() -> void:
	for style in 3:
		var saved: Dictionary = _story(style).to_dict()
		saved.erase("blade_bought")
		saved.erase("projected_cut_slot")
		var story: StoryCampaign = StoryCampaign.from_dict(saved)
		assert_eq(story.blade_bought.size(), 4)
		assert_eq(story.skill_points, 0)
		assert_eq(story.projected_cut_slot, -1)
		var hero: CharacterData = story.protagonist()
		assert_true(hero.technique_forward != null and hero.technique_back != null and hero.technique_air != null)
		assert_true(hero.ability != null)
		assert_false(story.blade_bought.has(&"projected_cut"))


func test_unbought_direction_does_not_fall_back_to_style_ability() -> void:
	var story: StoryCampaign = _story()
	_buy_kit(story)
	story.blade_bought.erase(&"style_back")
	var cast: Array[CharacterData] = [story.protagonist(), DuelFixture.SHADOW]
	var duel: DuelFixture = DuelFixture.create(null, null, 7, cast)
	duel.skip_intro()
	duel.place(300.0)
	duel.intents[0].move_x = -duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(30)
	assert_eq(duel.count_events(CombatEvent.Type.ATTACK_STARTED), 0)
	assert_true(duel.fighter(0).move == null)


func test_story_projected_cut_is_usable_in_all_slots_and_paths() -> void:
	for path in 2:
		for slot in 3:
			var story: StoryCampaign = _story()
			story.path = path
			var tree: StoryPowerTree = _buy_kit(story)
			assert_true(tree.equip(4, slot))
			var cast: Array[CharacterData] = [story.protagonist(), DuelFixture.SHADOW]
			var duel: DuelFixture = DuelFixture.create(null, null, 7, cast)
			duel.skip_intro()
			duel.place(300.0)
			if slot == 2:
				duel.fighter(0).y = 250.0
				duel.fighter(0).on_ground = false
				duel.sim.change_state(duel.fighter(0), FighterState.State.JUMPING)
			duel.intents[0].move_x = (1 if slot == 0 else -1) * duel.fighter(0).facing if slot < 2 else 0
			duel.press(0, Intent.Command.SPECIAL)
			duel.step()
			duel.release(0)
			assert_eq(duel.fighter(0).move, CUT)
			if slot == 2:
				assert_eq(duel.fighter(0).air_attacks, 1)
			duel.step(20)
			assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1)

