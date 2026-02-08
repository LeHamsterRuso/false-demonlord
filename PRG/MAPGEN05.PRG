//------------------------------------------------------------------------------
// TITLE:       Data Generator for JRPG_08 (Battle System version)
// AUTHOR:      Sebastian J. MONCHO MAQUET
// DATE:        13/01/2026
// DESCRIPTION: Generates the MapsV5.dat, ItemsV5.dat, Monsters.dat and HeroesV5.dat files.
//
//              IMPROVEMENTS OVER MAPGEN04.PRG:
//              - Added Monster database support
//              - Created Monsters.dat file with Slime enemy data
//              - Monster stats: HP, MP, Attack, Defense, Reward items
//              - Added Hero database support
//              - Created HeroesV5.dat file with Diablo character data
//              - Hero stats: Level, HP, MP, SP, STR, MAG, DEX, WIS, CRT, DEF, POW, AGI, MOV, LUK, Class, Spells
//              - Enhanced quest system with multiple dialogue states
//
//              Run this program once to create the data files.
//------------------------------------------------------------------------------

PROGRAM MapGenerator;
CONST
    QUEST_NOT_STARTED = 0;
    QUEST_ACTIVE = 1;
    QUEST_COMPLETED = 2;
GLOBAL
    STRUCT ItemList[20]
        STRING name[20];
        STRING description[50];
        INT price;
    END
    INT item_list_count = 0;
    STRUCT MonsterList[10]
        STRING name[20];
        INT max_hp;
        INT max_mp;
        INT attack;
        INT defense;
        INT graph; // Graph ID in MONSTERS.FPG
        INT reward_item_id; // Item to give when defeated
        INT reward_gold; // Gold to give when defeated
    END
    INT monster_list_count = 0;
    STRUCT HeroList[1]
        STRING name[20];
        STRING fpg_file[30];
        INT level;
        INT hp;
        INT mp;
        INT sp;
        INT str;
        INT mag;
        INT dex;
        INT wis;
        INT crt;
        INT def;
        INT pow;
        INT agi;
        INT mov;
        INT luk;
        STRING class[20];
        STRUCT spells[3]
            STRING name[50];
            STRING description[200];
        END
        INT spell_count;
    END
    INT hero_list_count = 0;
    STRUCT MapData[3]
        INT tiles[32,24];
        INT tilesX;
        INT tilesY;
        STRING fpg_file[30];
        STRUCT TeleportData[50]
            INT tile_i;
            INT tile_j;
            INT target_map;
            INT target_x;
            INT target_y;
        END
        INT teleport_count;
        STRUCT NPCData[10]
            STRING name[20];
            STRUCT dialogues[5]
                STRING dialogue[50];
                INT cg_id; // CG image ID to display during this dialogue (0 = none)
            END
            INT dialogue_count; // Number of dialogues
            INT x;
            INT y;
            INT color;
            INT gives_item;
            INT item_id;
            INT npc_id;
            INT graph;
            STRING fpg_file[30];
            // Quest data
            INT has_quest;
            STRUCT quest_dialogues[5]
                STRING dialogue[50];
                INT cg_id; // CG image ID for quest dialogue
            END
            INT quest_dialogue_count;
            STRUCT quest_accept_texts[5]
                STRING text[50];
                INT cg_id;
            END
            INT quest_accept_count;
            STRUCT quest_progress_texts[5]
                STRING text[50];
                INT cg_id;
            END
            INT quest_progress_count;
            STRUCT quest_complete_texts[5]
                STRING text[50];
                INT cg_id;
            END
            INT quest_complete_count;
            STRUCT quest_reward_texts[5]
                STRING text[50];
                INT cg_id;
            END
            INT quest_reward_count;
            INT quest_item_id;
            INT quest_item_count;
            INT quest_gold_reward;
        END
        INT npc_count;
        STRING map_song[30];
        STRING battle_song[30];
    END
    STRUCT TileTypes
        INT field = 1;
        INT mountain = 2;
        INT river = 3;
        INT bridge = 4;
        INT city = 5;
        INT forest = 6;
    END
BEGIN
    write(0, 10, 10, 0, "Generating MapsV5.dat, ItemsV5.dat, Monsters.dat and HeroesV5.dat...");
    GenerateItemsData();
    GenerateMonstersData();
    GenerateHeroesData();
    GenerateMapsData();
    write(0, 10, 30, 0, "MapsV5.dat created successfully!");
    write(0, 10, 40, 0, "ItemsV5.dat created successfully!");
    write(0, 10, 50, 0, "Monsters.dat created successfully!");
    write(0, 10, 60, 0, "HeroesV5.dat created successfully!");
    write(0, 10, 70, 0, "Press any key to exit...");
    LOOP
        IF (scan_code != 0)
            EXIT("", 0);
        END
        FRAME;
    END
END

PROCESS GenerateItemsData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Initialize item database
    ItemList[0].name = "Potion";
    ItemList[0].description = "Restores 50 HP";
    ItemList[0].price = 50;
    
    ItemList[1].name = "Elixir";
    ItemList[1].description = "Restores all HP";
    ItemList[1].price = 200;
    
    ItemList[2].name = "Antidote";
    ItemList[2].description = "Cures poison";
    ItemList[2].price = 30;
    
    ItemList[3].name = "Phoenix Down";
    ItemList[3].description = "Revives fallen ally";
    ItemList[3].price = 500;
    
    ItemList[4].name = "Ether";
    ItemList[4].description = "Restores 50 MP";
    ItemList[4].price = 100;
    
    ItemList[5].name = "Tent";
    ItemList[5].description = "Rests the party";
    ItemList[5].price = 150;
    
    ItemList[6].name = "Herb";
    ItemList[6].description = "Restores 20 HP";
    ItemList[6].price = 20;
    
    ItemList[7].name = "Mana Potion";
    ItemList[7].description = "Restores 30 MP";
    ItemList[7].price = 80;
    
    item_list_count = 8;
    
    // Write ItemsV5.dat file
    file_handle = fopen("ItemsV5.dat", "w");
    
    IF (file_handle == 0)
        write(0, 10, 80, 0, "ERROR: Could not create ItemsV5.dat!");
        RETURN;
    END
    
    // Write item_list_count first
    data_size = sizeof(item_list_count);
    fwrite(OFFSET item_list_count, data_size, file_handle);
    
    // Write entire ItemList structure
    data_size = sizeof(ItemList);
    IF (fwrite(OFFSET ItemList, data_size, file_handle) == 0)
        write(0, 10, 90, 0, "ERROR: Could not write to ItemsV5.dat!");
    END
    
    fclose(file_handle);
END

PROCESS GenerateMonstersData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Initialize monster database
    // Slime - basic enemy
    MonsterList[0].name = "Slime";
    MonsterList[0].max_hp = 20;
    MonsterList[0].max_mp = 0;
    MonsterList[0].attack = 5;
    MonsterList[0].defense = 5;
    MonsterList[0].graph = 1; // Graph 1 in MONSTERS.FPG
    MonsterList[0].reward_item_id = 0; // Gives Potion
    MonsterList[0].reward_gold = 10;
    
    monster_list_count = 1;
    
    // Write Monsters.dat file
    file_handle = fopen("Monsters.dat", "w");
    
    IF (file_handle == 0)
        write(0, 10, 100, 0, "ERROR: Could not create Monsters.dat!");
        RETURN;
    END
    
    // Write monster_list_count first
    data_size = sizeof(monster_list_count);
    fwrite(OFFSET monster_list_count, data_size, file_handle);
    
    // Write entire MonsterList structure
    data_size = sizeof(MonsterList);
    IF (fwrite(OFFSET MonsterList, data_size, file_handle) == 0)
        write(0, 10, 110, 0, "ERROR: Could not write to Monsters.dat!");
    END
    
    fclose(file_handle);
END

PROCESS GenerateHeroesData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Initialize hero database
    // Diablo - the Demon King
    HeroList[0].name = "Diablo";
    HeroList[0].fpg_file = "DIABLO/PLAYER.FPG";
    HeroList[0].level = 150;
    HeroList[0].hp = 4500;
    HeroList[0].mp = 9999;
    HeroList[0].sp = 330;
    HeroList[0].str = 1860;
    HeroList[0].mag = 9999;
    HeroList[0].dex = 160;
    HeroList[0].wis = 774;
    HeroList[0].crt = 25;
    HeroList[0].def = 2050;
    HeroList[0].pow = 8033;
    HeroList[0].agi = 860;
    HeroList[0].mov = 964;
    HeroList[0].luk = 30;
    HeroList[0].class = "Demon Lord";
    
    // Spells - 3 most powerful
    HeroList[0].spells[0].name = "White Nova";
    HeroList[0].spells[0].description = "Level 150 Fire/Light spell. Strongest magic for Diablo. White fireball explodes on impact, massive semi-circle damage. One-hit kills high-level monsters.";
    
    HeroList[0].spells[1].name = "Apocalypse Abyss";
    HeroList[0].spells[1].description = "Forbidden Formation Magic. 13 power points. Four elements (lightning, magma, ice, wind) create devastating tornado.";
    
    HeroList[0].spells[2].name = "Ruination Flame";
    HeroList[0].spells[2].description = "Colossal heat flash with ultimate power. Requires Ruination ring. Prevents other spells.";
    
    HeroList[0].spell_count = 3;
    
    hero_list_count = 1;
    
    // Write HeroesV5.dat file
    file_handle = fopen("HeroesV5.dat", "w");
    
    IF (file_handle == 0)
        write(0, 10, 120, 0, "ERROR: Could not create HeroesV5.dat!");
        RETURN;
    END
    
    // Write hero_list_count first
    data_size = sizeof(hero_list_count);
    fwrite(OFFSET hero_list_count, data_size, file_handle);
    
    // Write entire HeroList structure
    data_size = sizeof(HeroList);
    IF (fwrite(OFFSET HeroList, data_size, file_handle) == 0)
        write(0, 10, 130, 0, "ERROR: Could not write to HeroesV5.dat!");
    END
    
    fclose(file_handle);
END

PROCESS GenerateMapsData()
PRIVATE
    file_handle;
    data_size;
    i, j, count;
BEGIN
    // Set map dimensions
    MapData[0].tilesX = 32;
    MapData[0].tilesY = 24;
    MapData[0].fpg_file = "DIABLO/MAP01.FPG";
    MapData[1].tilesX = 8;
    MapData[1].tilesY = 8;
    MapData[1].fpg_file = "DIABLO/MAP02.FPG";
    MapData[2].tilesX = 8;
    MapData[2].tilesY = 8;
    MapData[2].fpg_file = "DIABLO/MAP03.FPG";

    // Assign map songs
    MapData[0].map_song = "MOD/BULERIA.S3M";
    MapData[1].map_song = "MOD/BULERIA.S3M";
    MapData[2].map_song = "MOD/CONQUPNO.S3M";

    // Assign battle songs
    MapData[0].battle_song = "MOD/CICLOPE.S3M";
    MapData[1].battle_song = "MOD/CICLOPE.S3M";
    MapData[2].battle_song = "MOD/BULERIA.S3M";

    // Initialize world map (32x24 tiles)
    FROM i = 0 TO 31;
        FROM j = 0 TO 23;
            MapData[0].tiles[i,j] = TileTypes.field;
            IF (i < 4 OR i > 27 OR j < 3)
                MapData[0].tiles[i,j] = TileTypes.mountain;
            END
            IF (j > 20)
                MapData[0].tiles[i,j] = TileTypes.river;
            END
            IF (j == 12 OR j == 13)
                MapData[0].tiles[i,j] = TileTypes.river;
            END
            IF (i == 16 AND (j == 12 OR j == 13))
                MapData[0].tiles[i,j] = TileTypes.bridge;
            END
            IF ((i >= 8 AND i <= 15 AND j >= 6 AND j <= 11) OR (i >= 18 AND i <= 25 AND j >= 14 AND j <= 19))
                MapData[0].tiles[i,j] = TileTypes.forest;
            END
            IF ((i >= 6 AND i <= 9 AND j >= 5 AND j <= 8) OR (i >= 20 AND i <= 23 AND j >= 15 AND j <= 18))
                MapData[0].tiles[i,j] = TileTypes.city;
            END
            IF (i == 7 AND j >= 6 AND j <= 11)
                MapData[0].tiles[i,j] = TileTypes.bridge;
            END
            IF (j == 11 AND i >= 7 AND i <= 16)
                MapData[0].tiles[i,j] = TileTypes.bridge;
            END
            IF (i == 16 AND j >= 11 AND j <= 15)
                MapData[0].tiles[i,j] = TileTypes.bridge;
            END
            IF (j == 15 AND i >= 16 AND i <= 21)
                MapData[0].tiles[i,j] = TileTypes.bridge;
            END
        END
    END

    // Initialize city 1 map
    FROM i = 0 TO 7;
        FROM j = 0 TO 7;
            MapData[1].tiles[i,j] = TileTypes.field;
            IF ((i >= 2 AND i <= 5 AND j >= 2 AND j <= 5))
                MapData[1].tiles[i,j] = TileTypes.city;
            END
            IF (i == 3 OR i == 4 OR j == 3 OR j == 4)
                MapData[1].tiles[i,j] = TileTypes.bridge;
            END
            IF (j == 7 AND i == 3)
                MapData[1].tiles[i,j] = TileTypes.field;
            END
        END
    END

    // Initialize city 2 map
    FROM i = 0 TO 7;
        FROM j = 0 TO 7;
            MapData[2].tiles[i,j] = TileTypes.field;
            IF ((i >= 1 AND i <= 6 AND j >= 1 AND j <= 6))
                MapData[2].tiles[i,j] = TileTypes.city;
            END
            IF (i == 2 OR i == 5 OR j == 2 OR j == 5)
                MapData[2].tiles[i,j] = TileTypes.bridge;
            END
            IF (j == 7 AND i == 4)
                MapData[2].tiles[i,j] = TileTypes.field;
            END
        END
    END

    // Initialize teleports for world map
    count = 0;
    FROM i = 6 TO 9;
        FROM j = 5 TO 8;
            MapData[0].TeleportData[count].tile_i = i;
            MapData[0].TeleportData[count].tile_j = j;
            MapData[0].TeleportData[count].target_map = 1;
            MapData[0].TeleportData[count].target_x = (i - 6) * 64;
            MapData[0].TeleportData[count].target_y = (j - 5) * 64;
            count++;
        END
    END
    FROM i = 20 TO 23;
        FROM j = 15 TO 18;
            MapData[0].TeleportData[count].tile_i = i;
            MapData[0].TeleportData[count].tile_j = j;
            MapData[0].TeleportData[count].target_map = 2;
            MapData[0].TeleportData[count].target_x = (i - 20) * 64;
            MapData[0].TeleportData[count].target_y = (j - 15) * 64;
            count++;
        END
    END
    MapData[0].teleport_count = count;
    MapData[1].teleport_count = 0;
    MapData[2].teleport_count = 0;

    // Initialize NPCs - World Map
    // Shera - gives potions, shows CG 3
    MapData[0].NPCData[0].name = "Shera";
    MapData[0].NPCData[0].dialogues[0].dialogue = "Hello Diablo. Do you want a potion?";
    MapData[0].NPCData[0].dialogues[0].cg_id = 3; // Show CG 3 during dialogue
    MapData[0].NPCData[0].dialogue_count = 1;
    MapData[0].NPCData[0].x = 50;
    MapData[0].NPCData[0].y = 50;
    MapData[0].NPCData[0].color = 12;
    MapData[0].NPCData[0].gives_item = 1;
    MapData[0].NPCData[0].item_id = 0; // Potion
    MapData[0].NPCData[0].npc_id = 0;
    MapData[0].NPCData[0].graph = 3;
    MapData[0].NPCData[0].fpg_file = "DIABLO/NPC01.FPG";
    MapData[0].NPCData[0].has_quest = 0;
    
    // Rem - shows CG 2
    MapData[0].NPCData[1].name = "Rem";
    MapData[0].NPCData[1].dialogues[0].dialogue = "Diablo, I need your help!";
    MapData[0].NPCData[1].dialogues[0].cg_id = 2; // Show CG 2 during dialogue
    MapData[0].NPCData[1].dialogue_count = 1;
    MapData[0].NPCData[1].x = 250;
    MapData[0].NPCData[1].y = 150;
    MapData[0].NPCData[1].color = 14;
    MapData[0].NPCData[1].gives_item = 0;
    MapData[0].NPCData[1].item_id = -1;
    MapData[0].NPCData[1].npc_id = 1;
    MapData[0].NPCData[1].graph = 3;
    MapData[0].NPCData[1].fpg_file = "DIABLO/NPC02.FPG";
    MapData[0].NPCData[1].has_quest = 0;

    // Initialize NPCs - City 1
    // Crystella - has 2 dialogues, no CG
    MapData[1].NPCData[0].name = "Crystella";
    MapData[1].NPCData[0].dialogues[0].dialogue = "I know what you're planning...";
    MapData[1].NPCData[0].dialogues[0].cg_id = 0; // No CG
    MapData[1].NPCData[0].dialogues[1].dialogue = "I'll be watching you...";
    MapData[1].NPCData[0].dialogues[1].cg_id = 0; // No CG
    MapData[1].NPCData[0].dialogue_count = 2;
    MapData[1].NPCData[0].x = 64;
    MapData[1].NPCData[0].y = 96;
    MapData[1].NPCData[0].color = 9;
    MapData[1].NPCData[0].gives_item = 0;
    MapData[1].NPCData[0].item_id = -1;
    MapData[1].NPCData[0].npc_id = 2;
    MapData[1].NPCData[0].graph = 3;
    MapData[1].NPCData[0].fpg_file = "DIABLO/NPC03.FPG";
    MapData[1].NPCData[0].has_quest = 0;
    
    // Sylvie - HAS QUEST: Collect 5 potions for 100 gold, shows CG 1 on quest dialogue
    MapData[1].NPCData[1].name = "Sylvie";
    MapData[1].NPCData[1].dialogue_count = 0; // Quest NPCs use quest_dialogue fields
    MapData[1].NPCData[1].x = 160;
    MapData[1].NPCData[1].y = 128;
    MapData[1].NPCData[1].color = 10;
    MapData[1].NPCData[1].gives_item = 0;
    MapData[1].NPCData[1].item_id = -1;
    MapData[1].NPCData[1].npc_id = 3;
    MapData[1].NPCData[1].graph = 3;
    MapData[1].NPCData[1].fpg_file = "DIABLO/NPC04.FPG";
    // Quest data
    MapData[1].NPCData[1].has_quest = 1;
    MapData[1].NPCData[1].quest_dialogues[0].dialogue = "Diablo, I need 5 potions. Can you help?";
    MapData[1].NPCData[1].quest_dialogues[0].cg_id = 1; // Show CG 1 during quest offer
    MapData[1].NPCData[1].quest_dialogue_count = 1;
    MapData[1].NPCData[1].quest_accept_texts[0].text = "Thank you! I'll be waiting.";
    MapData[1].NPCData[1].quest_accept_texts[0].cg_id = 0; // No CG
    MapData[1].NPCData[1].quest_accept_count = 1;
    MapData[1].NPCData[1].quest_progress_texts[0].text = "Bring me 5 potions, please.";
    MapData[1].NPCData[1].quest_progress_texts[0].cg_id = 0; // No CG
    MapData[1].NPCData[1].quest_progress_count = 1;
    MapData[1].NPCData[1].quest_complete_texts[0].text = "Perfect! Here is your reward.";
    MapData[1].NPCData[1].quest_complete_texts[0].cg_id = 0; // No CG
    MapData[1].NPCData[1].quest_complete_texts[1].text = "You earned 100 gold pieces!";
    MapData[1].NPCData[1].quest_complete_texts[1].cg_id = 0; // No CG
    MapData[1].NPCData[1].quest_complete_count = 2;
    MapData[1].NPCData[1].quest_reward_texts[0].text = "I have no more quests for you.";
    MapData[1].NPCData[1].quest_reward_texts[0].cg_id = 0; // No CG
    MapData[1].NPCData[1].quest_reward_texts[1].text = "Thanks again for your help!";
    MapData[1].NPCData[1].quest_reward_texts[1].cg_id = 0; // No CG
    MapData[1].NPCData[1].quest_reward_count = 2;
    MapData[1].NPCData[1].quest_item_id = 0; // Potion
    MapData[1].NPCData[1].quest_item_count = 5;
    MapData[1].NPCData[1].quest_gold_reward = 100;

    // Initialize NPCs - City 2
    // Edelgard - no quest, no CG
    MapData[2].NPCData[0].name = "Edelgard";
    MapData[2].NPCData[0].dialogues[0].dialogue = "Welcome to the city of demons.";
    MapData[2].NPCData[0].dialogues[0].cg_id = 0; // No CG
    MapData[2].NPCData[0].dialogue_count = 1;
    MapData[2].NPCData[0].x = 96;
    MapData[2].NPCData[0].y = 64;
    MapData[2].NPCData[0].color = 13;
    MapData[2].NPCData[0].gives_item = 0;
    MapData[2].NPCData[0].item_id = -1;
    MapData[2].NPCData[0].npc_id = 4;
    MapData[2].NPCData[0].graph = 3;
    MapData[2].NPCData[0].fpg_file = "DIABLO/NPC05.FPG";
    MapData[2].NPCData[0].has_quest = 0;
    
    // Klem - no quest, no CG
    MapData[2].NPCData[1].name = "Klem";
    MapData[2].NPCData[1].dialogues[0].dialogue = "Give me cookies.";
    MapData[2].NPCData[1].dialogues[0].cg_id = 0; // No CG
    MapData[2].NPCData[1].dialogue_count = 1;
    MapData[2].NPCData[1].x = 192;
    MapData[2].NPCData[1].y = 160;
    MapData[2].NPCData[1].color = 11;
    MapData[2].NPCData[1].gives_item = 0;
    MapData[2].NPCData[1].item_id = -1;
    MapData[2].NPCData[1].npc_id = 5;
    MapData[2].NPCData[1].graph = 3;
    MapData[2].NPCData[1].fpg_file = "DIABLO/NPC06.FPG";
    MapData[2].NPCData[1].has_quest = 0;

    MapData[0].npc_count = 2;
    MapData[1].npc_count = 2;
    MapData[2].npc_count = 2;

    // Write to file
    file_handle = fopen("MapsV5.dat", "w");
    
    IF (file_handle == 0)
        write(0, 10, 120, 0, "ERROR: Could not create MapsV5.dat!");
        RETURN;
    END
    
    data_size = sizeof(MapData);
    
    IF (fwrite(OFFSET MapData, data_size, file_handle) == 0)
        write(0, 10, 120, 0, "ERROR: Could not write to MapsV5.dat!");
    END
    
    fclose(file_handle);
END
