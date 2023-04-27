class StarParticle_Spawner : EffectSpawner
{
	Default
	{
		//$Category Special Effects (BoA)
		//$Title Startdust Spawner (horizontal)
		//$Color 12
		//$Sprite EMB5I0
		-SOLID
		+CLIENTSIDEONLY
		+NOCLIP
		+NOGRAVITY
		+NOINTERACTION
		RenderStyle "Add";
		Alpha 1.0;
		EffectSpawner.Range 1200;
		EffectSpawner.SwitchVar "boa_dustswitch";
		+EffectSpawner.ALLOWTICKDELAY
	}

	States
	{
		Spawn:
			TNT1 A 0;
		Active:
			"####" A 9 SpawnEffect();
			Loop;
	}


	override void SpawnEffect()
	{
		Super.SpawnEffect();

		if (random(0, 255) < 64) { return; } // Emulate failchance

		TextureID star = TexMan.CheckForTexture("EMB5I0");

		A_SpawnParticleEx(
			"FFFFFF", // color1
			star, // texture
			STYLE_Add, // style
			SPF_RELATIVE, // flags
			150, // lifetime
			1, // size
			0, // angle
			random(0, 128), // xoff
			0, // yoff
			random(0, 128), // zoff
			0, // velx
			random(2, 8), // vely
			0, // velz
			startalphaf: 1.0,
			fadestepf: 0.0
		);

		// A_SpawnItemEx("StarParticle", random(0,128), 0, random(0,128), 0, random(2,8), 0, 0, SXF_CLIENTSIDE, 64);
	}
}

class StarParticle_Spawner2 : StarParticle_Spawner
{
	Default
	{
		//$Title Startdust Spawner (with pitched)
	}

	override void SpawnEffect()
	{
		EffectSpawner.SpawnEffect();

		if (random(0, 255) < 64) { return; } // Emulate failchance

		TextureID star = TexMan.CheckForTexture("EMB5I0");

		A_SpawnParticleEx(
			"FFFFFF", // color1
			star, // texture
			STYLE_Add, // style
			SPF_RELATIVE, // flags
			150, // lifetime
			1, // size
			0, // angle
			random(0, 128), // xoff
			random(0, 128), // yoff
			0, // zoff
			0, // velx
			random(2, 8), // vely
			-5, // velz
			startalphaf: 1.0,
			fadestepf: 0.0
		);

		// A_SpawnItemEx("StarParticle", random(0,128), random(0,128), 0, 0, random(2,8), -5, 0, SXF_CLIENTSIDE, 64);
	}
}

class StarParticle_SpawnerFast : StarParticle_Spawner
{
	Default
	{
		//$Title Startdust Spawner (horizontal, fast)
	}

	override void SpawnEffect()
	{
		EffectSpawner.SpawnEffect();

		if (random(0, 255) < 64) { return; } // Emulate failchance

		TextureID star = TexMan.CheckForTexture("EMB5I0");

		A_SpawnParticleEx(
			"FFFFFF", // color1
			star, // texture
			STYLE_Add, // style
			SPF_RELATIVE, // flags
			150, // lifetime
			1, // size
			0, // angle
			random(0, 128), // xoff
			0, // yoff
			random(0, 128), // zoff
			0, // velx
			random(20, 30), // vely
			0, // velz
			startalphaf: 1.0,
			fadestepf: 0.0
		);

		// A_SpawnItemEx("StarParticle", random(0,128), 0, random(0,128), 0, random(20,30), 0, 0, SXF_CLIENTSIDE, 64);
	}
}

// Kept for savegame compatibility - Talon1024 and N00b
class StarParticle : ParticleBase
{
	Default
	{
		Gravity 0.125;
		Radius 1;
		Height 1;
		RenderStyle "Add";
		Alpha 1.0;
		YScale 1.0;
		XScale 1.0;
		+BRIGHT
		+FORCEXYBILLBOARD
		+MISSILE
		+NOGRAVITY
		+THRUACTORS
		DistanceCheck "boa_sfxlod";
		+ParticleBase.CHECKPOSITION
	}

	States
	{
		Spawn:
			EMB5 I 150;
			Stop;
	}
}
