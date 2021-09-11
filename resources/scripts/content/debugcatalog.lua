--------------------------------------------------------------------------------
-- Debug catalog data
--------------------------------------------------------------------------------

if useDebugCatalog then
	debugCatalog = [[{
	"head": {
		"protocolVersion": "1.0",
		"apiVersion": "1.0",
		"playerDevMode": false,
		"fromCache": true,
		"serverName": "cdn.discordapp.com",
		"processTime": "3.46ms",
		"memoryUsage": "1.07 MB",
		"memoryPeakUsage": "1.12 MB"
	},
	"body": [
		{
			"setNode": {
				"id": "root",
				"type": "root",
				"children": [
					{
						"id": "channel:category",
						"version": "7a6f5387cea37c915a15b50a16214cd7"
					},
					{
						"id": "channel:test-test",
						"version": "7a6f5387cea37c915a15b50a16214cd7"
					}
				],
				"version": "73dc61d9b2b6bfb373e4c0ae8bb9a5ae"
			}
		},
		{
			"setNode": {
				"id": "episode:testvideo",
				"version": "55d29a3bf5f0ed8b98234f2b88911f4c",
				"type": "episode",
				"number": 1,
				"ageRate": 6,
				"title": "Test",
				"description": "Discord moflex",
				"mediaUrls": {
					"en": "https://cdn.discordapp.com/attachments/885556340599164929/886221030899716096/shawn_le_mouton.moflex",
					"fr": "https://cdn.discordapp.com/attachments/885556340599164929/886221030899716096/shawn_le_mouton.moflex"
				},
				"viewCount": 0,
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE01-thumbnail.3dst"
				},
				"agePrerollVideo": "rom:/data/dammy.moflex"
			}
		},
		{
			"setNode": {
				"id": "episode:testvideo2",
				"version": "649f671be9bd0e2bf9fa18d73de07d57",
				"type": "episode",
				"number": 2,
				"ageRate": 6,
				"title": "Test 2",
				"description": "Same discord moflex",
				"mediaUrls": {
					"en": "https://cdn.discordapp.com/attachments/885556340599164929/886221030899716096/shawn_le_mouton.moflex",
					"fr": "https://cdn.discordapp.com/attachments/885556340599164929/886221030899716096/shawn_le_mouton.moflex"
				},
				"viewCount": 111,
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE02-thumbnail.3dst"
				},
				"agePrerollVideo": "rom:/data/dammy.moflex"
			}
		},
		{
			"setNode": {
				"id": "episode:testvideo3",
				"version": "649f671be9bd0e2bf9fa18d73de07d57",
				"type": "episode",
				"number": 3,
				"ageRate": 6,
				"title": "Test 3",
				"description": "This shouldn't load (dead link)",
				"mediaUrls": {
					"en": "https://dm13bvvnwveun.cloudfront.net/inazuma/videos/IE_ENGLISH_03.moflex",
					"fr": "https://dm13bvvnwveun.cloudfront.net/inazuma/videos/IE_ENGLISH_03.moflex"
				},
				"viewCount": 111,
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE02-thumbnail.3dst"
				},
				"agePrerollVideo": "rom:/data/dammy.moflex"
			}
		},
    {
			"setNode": {
				"id": "episode:testvideo4",
				"version": "649f671be9bd0e2bf9fa18d73de07d57",
				"type": "episode",
				"number": 4,
				"ageRate": 6,
				"title": "Test 4",
				"description": "This should load",
				"mediaUrls": {
					"en": "https://https://github.com/raventhecat333/silver-couscous/blob/main/intro.moflex?raw=true",
					"fr": "https://https://github.com/raventhecat333/silver-couscous/blob/main/intro.moflex?raw=true"
				},
				"viewCount": 111,
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE02-thumbnail.3dst"
				},
				"agePrerollVideo": "rom:/data/dammy.moflex"
			}
		},
    {
			"setNode": {
				"id": "episode:testvideo5",
				"version": "649f671be9bd0e2bf9fa18d73de07d57",
				"type": "episode",
				"number": 5,
				"ageRate": 6,
				"title": "Test 5",
				"description": "This should load",
				"mediaUrls": {
					"en": "https://github.com/raventhecat333/silver-couscous/raw/main/intro.moflex",
					"fr": "https://github.com/raventhecat333/silver-couscous/raw/main/intro.moflex"
				},
				"viewCount": 111,
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE02-thumbnail.3dst"
				},
				"agePrerollVideo": "rom:/data/dammy.moflex"
			}
		},
		{
			"setNode": {
				"id": "episode:testvideo6",
				"version": "649f671be9bd0e2bf9fa18d73de07d57",
				"type": "episode",
				"number": 6,
				"ageRate": 6,
				"title": "Test 6",
				"description": "This shouldn't load too (dead link)",
				"mediaUrls": {
					"en": "https://dm13bvvnwveun.cloudfront.net/inazuma/videos/IE_ENGLISH_03.moflex",
					"fr": "https://dm13bvvnwveun.cloudfront.net/inazuma/videos/IE_ENGLISH_03.moflex"
				},
				"viewCount": 111,
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE02-thumbnail.3dst"
				},
				"agePrerollVideo": "rom:/data/dammy.moflex"
			}
		},
		{
			"setNode": {
				"id": "channel:category",
				"type": "channel",
				"title": "Caterory 1",
				"eshopLinks": [
					{
						"label": "Hihihi",
						"id": "1045488",
						"imageUrl": "https://lightning-server.ext.mobiclip.com/inazuma/thumbs/IE03-thumbnail.3dst"
					}
				],
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE03-thumbnail.3dst"
				},
				"children": [
					{
						"id": "episode:testvideo",
						"version": "55d29a3bf5f0ed8b98234f2b88911f4c"
					},
					{
						"id": "episode:testvideo2",
						"version": "649f671be9bd0e2bf9fa18d73de07d57"
					}
				],
				"version": "7a6f5387cea37c915a15b50a16214cd7"
			}
		},{
			"setNode": {
				"id": "channel:test-test",
				"type": "channel",
				"title": "Category 2",
				"eshopLinks": [
					{
						"label": "Hihihi",
						"id": "1045488",
						"imageUrl": "https://lightning-server.ext.mobiclip.com/inazuma/thumbs/IE03-thumbnail.3dst"
					}
				],
				"imageUrls": {
					"default": "https://dm13bvvnwveun.cloudfront.net/inazuma/thumbs/IE03-thumbnail.3dst"
				},
				"children": [
					{
						"id": "episode:testvideo3",
						"version": "55d29a3bf5f0ed8b98234f2b88911f4c"
					},
					{
						"id": "episode:testvideo4",
						"version": "649f671be9bd0e2bf9fa18d73de07d57"
					}
				],
				"version": "7a6f5387cea37c915a15b50a16214cd7"
			}
		}
	]
}]]
end
