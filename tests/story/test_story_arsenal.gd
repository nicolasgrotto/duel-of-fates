extends TestCase

const CAMPAIGN: CampaignData = preload("res://data/story/campaign.tres")
const STYLE_TECHNIQUE: int = 0
const STYLE_HOLSTER: int = 3


func _story(style: int) -> StoryCampaign:
	return StoryCampaign.create("Teste", 0, style, 0, 0, 1)


func _blaster(id: StringName) -> BlasterData:
	for blaster in CAMPAIGN.blasters:
		if blaster.id == id:
			return blaster
	assert_true(false, String(id))
	return null


func _shots(blaster_id: StringName) -> int:
	var story: StoryCampaign = _story(STYLE_HOLSTER)
	story.blaster_id = blaster_id
	return _fired(story.protagonist(), CAMPAIGN.blaster_tree[0].technique)


func _fired(hero: CharacterData, move: MoveData) -> int:
	var duel: DuelFixture = DuelFixture.create(null, null, 7, [hero, DuelFixture.character(&"guardian")] as Array[CharacterData])
	duel.skip_intro()
	duel.place(900.0)
	assert_eq(ActionStarter.start_attack(duel.sim, duel.fighter(0), move), ActionStarter.Result.STARTED)
	var most: int = 0
	for tick in 90:
		duel.step()
		most = maxi(most, duel.sim.projectiles.filter(func(p: Projectile) -> bool: return p.active and p.kind == Projectile.Kind.BOLT).size())
	return most


func test_every_weapon_has_text_art_and_a_distinct_pattern() -> void:
	assert_eq(CAMPAIGN.blasters.size(), 5)
	var locale: String = TranslationServer.get_locale()
	for code in ["pt_BR", "en"]:
		TranslationServer.set_locale(code)
		for blaster in CAMPAIGN.blasters:
			assert_ne(TranslationServer.translate(blaster.name_key), blaster.name_key)
			assert_ne(TranslationServer.translate(blaster.description_key), blaster.description_key)
			assert_true(blaster.texture != null and blaster.support_texture != null, String(blaster.id))
	TranslationServer.set_locale(locale)
	assert_eq(_blaster(&"back_rifle").shot_count, 3)
	var sniper: BlasterData = _blaster(&"back_sniper")
	assert_eq(sniper.shot_count, 1)
	assert_gt(sniper.bolt.damage, _blaster(&"back_rifle").bolt.damage * 2.0)
	assert_gt(sniper.bolt.size, _blaster(&"holster_pistol").bolt.size)
	assert_gt(sniper.draw_time, _blaster(&"back_rifle").draw_time)
	assert_true(_blaster(&"thigh_revolver").size_class != BlasterData.SizeClass.LONG)


func test_bigger_bolts_draw_bigger_and_standard_ones_keep_their_look() -> void:
	var reference: float = (load("res://data/balance/power_vfx_config.gd").new() as PowerVfxConfig).bolt_reference_size
	assert_almost(PowerView.scale_for_bolt(_blaster(&"holster_pistol").bolt.size, reference), 1.0)
	assert_almost(PowerView.scale_for_bolt(_blaster(&"back_sniper").bolt.size, reference), 2.0)


func test_the_weapon_decides_how_many_shots_a_draw_fires() -> void:
	assert_eq(_shots(&"holster_pistol"), 2)
	assert_eq(_shots(&"back_rifle"), 3)
	assert_eq(_shots(&"back_sniper"), 1)


func test_vigor_cost_scales_only_for_draws() -> void:
	var sniper: BlasterData = _blaster(&"back_sniper")
	var story: StoryCampaign = _story(STYLE_HOLSTER)
	story.blaster_id = sniper.id
	var duel: DuelFixture = DuelFixture.create(null, null, 7, [story.protagonist(), DuelFixture.character(&"guardian")] as Array[CharacterData])
	var fighter: FighterState = duel.fighter(0)
	var draw: MoveData = CAMPAIGN.blaster_tree[0].technique
	assert_almost(fighter.vigor_cost_of(draw), draw.vigor_cost * sniper.vigor_multiplier)
	var heavy: MoveData = fighter.character.heavy
	assert_almost(fighter.vigor_cost_of(heavy), heavy.vigor_cost)


func test_buying_spends_credits_and_refuses_what_it_cannot_afford() -> void:
	var story: StoryCampaign = _story(STYLE_TECHNIQUE)
	var rifle: BlasterData = _blaster(&"back_rifle")
	assert_false(story.owns_blaster(_blaster(&"holster_pistol")))
	assert_false(story.owns_blaster(rifle))
	assert_false(story.buy_blaster(rifle))
	story.credits = rifle.price + 10
	assert_true(story.buy_blaster(rifle))
	assert_eq(story.credits, 10)
	assert_true(story.owns_blaster(rifle))
	assert_false(story.buy_blaster(rifle))
	assert_eq(story.credits, 10)


func test_credits_come_only_from_the_first_win() -> void:
	var story: StoryCampaign = _story(STYLE_TECHNIQUE)
	var encounter: EncounterData = story.route()[0]
	var notes: PackedStringArray = story.complete(encounter, 1.0)
	assert_eq(story.credits, story.credits_for(encounter))
	assert_false(notes.is_empty())
	story.complete(encounter, 1.0)
	assert_eq(story.credits, story.credits_for(encounter))


func test_one_route_affords_the_priciest_weapon_but_not_every_weapon() -> void:
	var story: StoryCampaign = _story(STYLE_TECHNIQUE)
	var earned: int = 0
	for encounter in story.route():
		earned += story.credits_for(encounter)
	var total: int = 0
	for blaster in CAMPAIGN.blasters:
		total += blaster.price
	assert_gt(float(earned), float(_blaster(&"back_sniper").price))
	assert_lt(float(earned), float(total) * 2.0)


func test_old_saves_gain_credits_for_encounters_already_won() -> void:
	var story: StoryCampaign = _story(STYLE_TECHNIQUE)
	var encounter: EncounterData = story.route()[0]
	story.cleared.append(encounter.id)
	var saved: Dictionary = story.to_dict()
	saved.erase("credits")
	saved.erase("owned_blasters")
	saved.erase("blaster_carried")
	saved.erase("blaster_bought")
	saved.erase("blaster_active")
	var loaded: StoryCampaign = StoryCampaign.from_dict(saved)
	assert_eq(loaded.credits, story.credits_for(encounter))
	assert_false(loaded.blaster_equipped())


func test_purchases_and_slot_survive_a_save() -> void:
	var story: StoryCampaign = _story(STYLE_TECHNIQUE)
	story.credits = 1000
	var sniper: BlasterData = _blaster(&"back_sniper")
	assert_true(story.buy_blaster(sniper))
	assert_true(story.equip_blaster(sniper))
	var loaded: StoryCampaign = StoryCampaign.from_dict(story.to_dict())
	assert_eq(loaded.credits, story.credits)
	assert_eq(loaded.blaster_id, sniper.id)
	assert_true(loaded.blaster_equipped())
	assert_true(loaded.owns_blaster(sniper))


func test_any_style_can_buy_equip_and_fire_a_blaster() -> void:
	for style in CAMPAIGN.styles.size():
		if CAMPAIGN.styles[style] == &"holster":
			continue
		var story: StoryCampaign = _story(style)
		var plain: CharacterData = story.protagonist()
		assert_true(plain.weapon.blaster == null, "no blaster until equipped")
		var pistol: BlasterData = _blaster(&"holster_pistol")
		assert_false(story.equip_blaster(pistol), "the pistol must be bought first")
		story.credits = pistol.price
		assert_true(story.buy_blaster(pistol))
		assert_eq(story.credits, 0)
		assert_true(story.equip_blaster(pistol))
		var armed: CharacterData = story.protagonist()
		assert_eq(armed.weapon.sidearm, WeaponData.Sidearm.HOLSTER)
		assert_eq(armed.weapon.blaster, pistol)
		assert_eq(armed.technique_forward, CAMPAIGN.blaster_tree[0].technique)
		assert_true(armed.technique_forward.usable_by(armed))
		assert_gt(float(_fired(armed, armed.technique_forward)), 0.0)
		story.unequip_blaster()
		var saber: CharacterData = story.protagonist()
		assert_true(saber.weapon.blaster == null)
		assert_eq(saber.technique_forward, story.style_character().technique_forward)


func test_the_shared_character_data_is_never_changed() -> void:
	var story: StoryCampaign = _story(STYLE_TECHNIQUE)
	story.credits = 1000
	story.buy_blaster(_blaster(&"holster_pistol"))
	story.equip_blaster(_blaster(&"holster_pistol"))
	story.protagonist()
	assert_true(DuelFixture.character(&"guardian").weapon.blaster == null)
	assert_ne(DuelFixture.character(&"guardian").weapon.sidearm, WeaponData.Sidearm.HOLSTER)


func test_only_the_holster_style_starts_with_the_pistol_equipped() -> void:
	var holster: StoryCampaign = _story(STYLE_HOLSTER)
	var pistol: BlasterData = _blaster(&"holster_pistol")
	assert_eq(pistol.price, 150)
	assert_true(holster.owns_blaster(pistol))
	assert_eq(holster.credits, 0)
	assert_eq(holster.protagonist().weapon.blaster, pistol)
	assert_eq(holster.protagonist().technique_forward, CAMPAIGN.blaster_tree[0].technique)
	assert_false(_story(STYLE_TECHNIQUE).owns_blaster(pistol))


func test_prices_follow_the_author_table() -> void:
	var expected: Dictionary = {&"holster_pistol": 150, &"thigh_revolver": 200, &"lumbar_carbine": 250, &"back_rifle": 350, &"back_sniper": 450}
	for id in expected:
		assert_eq(_blaster(id).price, expected[id])


func test_holster_style_keeps_the_weapon_and_can_turn_its_skills_off() -> void:
	var story: StoryCampaign = _story(STYLE_HOLSTER)
	var base: CharacterData = story.style_character()
	story.credits = 1000
	var rifle: BlasterData = _blaster(&"back_rifle")
	story.buy_blaster(rifle)
	assert_true(story.equip_blaster(rifle))
	assert_eq(story.protagonist().weapon.blaster, rifle)
	assert_true(story.toggle_blaster_skill(CAMPAIGN.blaster_tree[0]))
	assert_eq(story.protagonist().technique_forward, base.technique_forward)
	assert_eq(story.protagonist().weapon.blaster, rifle)
