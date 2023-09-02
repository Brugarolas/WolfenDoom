class CinderSpawner : EffectSpawner
{
	ParticleSpawnPoint spawnPoints[SPAWN_POINTS_PER_SPAWNER];

	Default
	{
		//$Category Special Effects (BoA)
		//$Title Cinder Spawner (floor)
		//$Color 12
		//$Arg0 "Radius"
		//$Arg0Tooltip "Radius in map units"
		//$Arg1 "Height"
		//$Arg1Tooltip "Z-dimension (bottom is the z-level the spawner is on)"
		//$Arg2 "Min. Speed"
		//$Arg2Tooltip "Minimum speed the particles have, randomized between min. and max."
		//$Arg3 "Max. Speed"
		//$Arg3Tooltip "Maximum speed the particles have, randomized between min. and max."
		//$Arg4 "Frequency"
		//$Arg4Tooltip "0 is always, 255 is never at a per-tic basis"
		Radius 1;
		Height 1;
		+CLIENTSIDEONLY
		+NOCLIP
		+NOGRAVITY
		EffectSpawner.Range 1024;
		EffectSpawner.SwitchVar "boa_cinderswitch";
		+EffectSpawner.ALLOWTICKDELAY
	}

	States
	{
		Spawn:
			TNT1 A 0;
		Active:
			TNT1 A 5 SpawnEffect();
			Loop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (!args[0] && !args[2] && !args[3])
		{
			args[0] = 128;
			args[2] = 1;
			args[3] = 8;
		}

		SetupSpawnPoints();
	}

	override void SpawnEffect()
	{
		Super.SpawnEffect();

		if (Random(0, 255) < args[4]) { return; }

		int i = Random[CinderSpawner](0, SPAWN_POINTS_PER_SPAWNER - 1);
		double speed = frandom(args[2], args[3]);
		Vector3 vel = ZScriptTools.GetTraceDirection(spawnPoints[i].angle, spawnPoints[i].pitch) * speed;

		FSpawnParticleParams particleInfo;
		particleInfo.color1 = "FFFFFF";
		particleInfo.texture = TexMan.CheckForTexture("EMBRA0");
		particleInfo.style = STYLE_Add;
		particleInfo.flags = SPF_FULLBRIGHT;
		particleInfo.lifetime = int(floor(spawnPoints[i].distance / speed));
		particleInfo.size = 2.56;
		particleInfo.pos = spawnPoints[i].worldPos;
		particleInfo.vel = vel;
		particleInfo.startalpha = 0.8;
		Level.SpawnParticle(particleInfo);
	}

	void SetupSpawnPoints() {
		for (int i = 0; i < SPAWN_POINTS_PER_SPAWNER; i++) {
			do { // So that "continue" can be used to try again
				Vector3 offset = (
					frandom(-args[0],args[0]),
					frandom(-args[0],args[0]),
					random(0,args[1]));
				Vector3 vel = (
					frandom(args[2],args[3]),
					0,
					frandom(-args[2],args[2]));

				// Rotate vel
				{
					double angle = Angle + frandom(-4, 4);
					double c = cos(angle);
					double s = sin(angle);
					double speed = vel.x;
					vel.x = speed * c;
					vel.y = speed * s;
				}
				// Calculate absolute spawn position
				Vector3 spawnPos = Vec3Offset(offset.x, offset.y, offset.z);

				Sector spawnSector = Level.PointInSector(spawnPos.XY);
				if (!SnowSpawner.SpawnPointValid(spawnSector, ceilingpic)) {
					continue;
				}
				spawnPos.Z = max(spawnPos.Z, spawnSector.LowestFloorAt(spawnPos.XY));

				// Use a hitscan to find the distance to the nearest obstacle
				vel = vel.Unit();
				BoASolidSurfaceFinderTracer finder = new("BoASolidSurfaceFinderTracer");
				finder.Trace(spawnPos, spawnSector, vel, 10000.0, TRACE_HitSky);

				// Set up spawn point
				spawnPoints[i].worldPos = spawnPos;
				[spawnPoints[i].angle, spawnPoints[i].pitch] = ZScriptTools.AnglesFromDirection(vel);
				/* // ========== Test start
				Vector3 dirbo = ZScriptTools.GetTraceDirection(spawnPoints[i].angle, spawnPoints[i].pitch);
				Console.Printf("dirbo: %.3f %.3f %.3f, vel: %.3f %.3f %.3f", dirbo, vel);
				if (dirbo dot vel < 0.9375) {
					Console.Printf("ZScriptTools.AnglesFromDirection is broken!");
				}
				// ========== Test end */
				spawnPoints[i].distance = finder.Results.Distance;
			} while(false); // See lines 68 and 83
		}
	}

	static void SpawnCinder(Actor a, Vector3 p = (4,64,1024), Vector3 v = (4,64,1024), double halfang = 180, int failchance = 160)
	{
		if (Random(0, 255) < failchance) { return; }
		// GZDoom allows neither non-constant default parameters nor constant vectors.
		if (p == (4,64,1024)) { p = (frandom(-8,8),frandom(-8,8),frandom(0,32)); }
		if (v == (4,64,1024)) { v = (1,0,frandom(1,3)); }
		a.A_SpawnParticleEx(
			/*color1*/ "FFFFFF",
			/*texture*/ TexMan.CheckForTexture("EMBRA0"),
			/*style*/ STYLE_Add,
			/*flags*/ SPF_FULLBRIGHT | SPF_RELATIVE,
			/*lifetime*/ 8 * (16 + Random(0, 8)),
			/*size*/ frandom(3, 6),
			/*angle*/ frandom(-halfang, halfang),
			/*posoff*/ p.x, p.y, p.z,
			/*vel*/ v.x, v.y, v.z,
			/*acc*/ 0, 0, 0,
			/*startalphaf*/ 0.8,
			/*fadestepf*/ 0.0);
	}
}

////////////////
// SKY CINDER //
////////////////
class CinderSpawnerSky : SnowSpawner
{
	Default
	{
		//$Title Cinder Spawner (ceiling)
		//$Sprite EMBRA0
		//$Arg1Tooltip "The lower the number, the heavier the amount of cinders\nRange: 0 - 255"
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (args[0] == 0) { args[0] = 128; }
	}

	override void SpawnEffect()
	{
		EffectSpawner.SpawnEffect();

		double zoffset = 0;
		if (manager) { zoffset = min(manager.particlez - pos.z, 0); }
		if (Random(0, 255) < Args[1]) { return; }
		
		if (args[2]) { CinderSpawner.SpawnCinder(self, (frandom(-args[0],args[0]), 0, zoffset),
				(frandom(-1.0,1.0),frandom(-1.0,1.0),frandom(-1.0,-3.0)), 180, args[1]); }
		else { CinderSpawner.SpawnCinder(self, (frandom(-args[0],args[0]), frandom(-args[0], args[0]), zoffset),
				(frandom(-1.0,1.0),frandom(-1.0,1.0),frandom(-1.0,-3.0)), 0, args[1]); }
	}
}

// THE FOLLOWING CLASSES ARE UNUSED, only re-added them for savegame compatibility -- N00b

class FloatingCinder : ParticleBase
{
	Default
	{
		DistanceCheck "boa_sfxlod";
		Radius 0;
		Height 0;
		+DONTSPLASH
		+FORCEXYBILLBOARD
		+MISSILE
		+NOBLOCKMAP
		+NOGRAVITY
		RenderStyle "Add";
		Alpha 0.8;
		Scale 0.04;
	}

	States
	{
		Spawn:
			EMBR A 128 BRIGHT;
		Death:
			EMBR A 1 BRIGHT A_FadeOut(0.06, FTF_REMOVE);
			Loop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		scale.x = scale.y = FRandom(0.03, 0.06);
		tics = 8 * (16 + Random(0, 8)); // Not quite what the previous A_Jump logic did, but similar
	}
}

class FloatingCinder2 : FloatingCinder
{
	Default
	{
		+NOINTERACTION
	}
}