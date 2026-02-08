//------------------------------------------------------------------------------
// TITLE:       JRPG with Battle System
// AUTHOR:      Sebastian J. MONCHO MAQUET
// DATE:        04/02/2026
// DESCRIPTION: Enhanced JRPG with turn-based battle system.
//
// NOTE:        Run MAPGEN05.PRG first to generate MapsV5.dat, ItemsV5.dat, Monsters.dat and HeroesV5.dat files before running this program.
//
//              This version is the same as JRPG_08, but fixes the control system and corrects a bug when talking to Shera.
//------------------------------------------------------------------------------

PROGRAM JRPG;
CONST
    // Quest states
    QUEST_NOT_STARTED = 0;
    QUEST_ACTIVE = 1;
    QUEST_COMPLETED = 2;
    // Game constants
    TILE_SIZE = 32;
    NORMAL_ZOOM = 100;
    INTERACTION_DISTANCE = 50;
    MAX_ITEMS = 10;
    MAX_MAPS = 3;
    MAX_NPCS_PER_MAP = 10;
    MAX_CGS = 10;
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
        INT sprite_graph_id; // Graph ID in MONSTERS.FPG
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
    STRUCT MenuOption[12]
        STRING text;
        INT text_id;
        INT desc_id;
    END
    offset_x = 0;
    offset_y = 0;
    current_map = 0; // 0 = world, 1 = city1, 2 = city2
    INT player_gold = 0; // Player's gold currency
    STRUCT PlayerStats
        STRING name;
        INT current_hp;
        INT max_hp;
        INT current_mp;
        INT max_mp;
        INT attack;
        INT defense;
    END
    STRUCT PlayerData
        INT x = 160;
        INT y = 120;
        INT sprite_graph_id = 2;
        INT direction = 2;
        INT anim_frame = 0;
        INT anim_counter = 0;
    END
    // Battle system
    INT in_battle = 0; // Flag when battle is active
    INT battle_process_id = 0; // ID of active battle process
    INT step_counter = 0; // Steps taken for random encounters
    INT steps_until_battle = 50; // Steps until next battle (randomized)
    song_id = 0;
    STRING current_song[30];
    prev_offset_x = -1;
    prev_offset_y = -1;
    prev_map = 0;
    STRUCT Inventory[MAX_ITEMS]
        STRING item[20];
        INT quantity;
        STRING description[50];
    END
    INT item_count = 0;
    INT inventory_open = 0; // Legacy flag (no longer used for logic)
    INT inventory_active = 0; // True while inventory_screen process is running
    INT submenu_finished = 0; // Flag to signal when submenu has finished
    INT force_redraw = 0; // Force map redraw
    INT dialogue_zoom = NORMAL_ZOOM; // Zoom level during dialogues (100 = normal, 150 = 1.5x)
    // CG Gallery system
    INT cg_fpg_id; // FPG ID for CG images
    INT cg_unlocked[10]; // Array to track which CGs are unlocked (1 = unlocked, 0 = locked)
    INT cg_count = 3; // Total number of CGs in the game
    INT battle_overlay_id = 0; // ID for battle dark overlay
    INT after_battle_start = 0; // Flag for after initial battle message
    STRUCT Controls
        INT left;
        INT right;
        INT up;
        INT down;
        INT talk;
        INT inventory;
        INT exit;
    END
    STRUCT MapData[MAX_MAPS]
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
        STRUCT NPCData[MAX_NPCS_PER_MAP]
            STRING name[20];
            STRUCT dialogues[5]
                STRING dialogue[50];
                INT cg_id; // CG image ID to display (0 = none)
            END
            INT dialogue_count; // Number of dialogues
            INT x;
            INT y;
            INT color;
            INT gives_item;
            INT item_id;
            INT npc_id;
            INT sprite_graph_id;
            STRING fpg_file[30];
            // Quest data
            INT has_quest;
            STRUCT quest_dialogues[5]
                STRING dialogue[50];
                INT cg_id;
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
    // Quest tracking - one per NPC (indexed by npc_id)
    INT quest_states[10];
    // Temporary dialogue storage for passing to dialogue process
    STRUCT temp_dialogues[5]
        STRING dialogue[50];
        INT cg_id; // CG to show during this dialogue
    END
    INT temp_dialogue_count;
    STRUCT DialogState
        INT process_id;             // Stores the ID of the active dialogue process; used to check if a dialogue is currently running (0 means no dialogue).
        INT closing;                // Boolean flag indicating whether the dialogue is in the process of closing.
        INT close_timer;            // Countdown timer for the dialogue closing animation or delay before fully closing.
        INT open_timer;             // Countdown timer for the dialogue opening delay to prevent immediate interactions.
        INT skip;                   // Boolean flag to skip the letter-by-letter text animation and display the full text instantly.
        INT press_timer;            // Countdown timer to debounce key presses, preventing rapid repeated actions.
        INT complete;               // Boolean flag indicating whether the text animation has finished displaying the full dialogue.
        INT box_id;                 // The draw ID of the dialogue box rectangle; used for deleting the box when closing.
        INT has_options;            // Flag if dialogue has yes/no options
        INT selected_option;        // 0 = yes, 1 = no
        INT item_to_give;           // Item ID to give if yes
        INT is_quest;               // Flag if this is a quest dialogue
        INT quest_npc_id;           // NPC ID for quest tracking
        INT current_dialogue_index; // Current dialogue being shown (for multi-dialogue NPCs)
        INT total_dialogues;        // Total number of dialogues for this NPC
        INT current_npc_index;      // Index of current NPC in MapData array
        INT current_map_index;      // Index of current map
        INT current_cg_id;          // Current CG being displayed (0 = none)
    END
    STRUCT TileTypes
        INT field = 1;
        INT mountain = 2;
        INT river = 3;
        INT bridge = 4;
        INT city = 5;
        INT forest = 6;
    END
    STRUCT ScreenConfig
        INT width = 320;
        INT height = 200;
        INT fps = 30;
    END
    INT fpg_ids[MAX_MAPS]; // FPG IDs for each map
    INT npc_fpg_ids[6]; // FPG IDs for each NPC
    INT hud_fpg_id; // FPG ID for HUD elements
    INT player_fpg_id; // FPG ID for player graphics
    INT monsters_fpg_id; // FPG ID for monster graphics
    STRUCT Enemies[3] // Battle enemies array
        INT monster_id;
        INT current_hp;
        INT max_hp;
        INT alive;
        INT dying;
        INT dying_timer;
        INT size;
    END
    INT selecting_target = 0;
    INT selected_target = 0;
    // Graphics control variables for centralized rendering
    INT show_dialogue_box = 0; // 1 = show dialogue box
    INT show_menu_bg = 0; // 1 = show menu background
    INT show_battle_box = 0; // 1 = show battle box
    INT show_dialogue_cg = 0; // CG ID to show in dialogue (0 = none)
    INT show_gallery_cg = 0; // CG ID to show in gallery (0 = none)
BEGIN
    set_mode(ScreenConfig.width * 1000 + ScreenConfig.height);
    set_fps(ScreenConfig.fps, 0);

    // Set text z to ensure battle messages appear above all graphics
    text_z = 1000;

    // Load palette
    load_pal("DIV2.PAL");

    // Load HUD graphics
    hud_fpg_id = load_fpg("DIABLO/HUD.FPG");

    // Load player graphics
    player_fpg_id = load_fpg("DIABLO/PLAYER.FPG");

    // Load CG graphics
    cg_fpg_id = load_fpg("DIABLO/CG.FPG");

    // Load monster graphics
    monsters_fpg_id = load_fpg("DIABLO/MONSTERS.FPG");

    // Initialize controls
    InitControls();

    // Initialize quest states
    InitQuestStates();

    // Initialize CG unlock states
    InitCGStates();

    // Load item database from file
    IF (LoadItemsData() == -1)
        EXIT("ItemsV5.dat file missing! Please run MAPGEN05.PRG first.", 1);
    END

    // Load monster database from file
    IF (LoadMonstersData() == -1)
        EXIT("Monsters.dat file missing! Please run MAPGEN05.PRG first.", 1);
    END

    // Load hero database from file
    IF (LoadHeroesData() == -1)
        EXIT("HeroesV5.dat file missing! Please run MAPGEN05.PRG first.", 1);
    END

    // Initialize PlayerStats from HeroList
    InitPlayerStats();

    // Load map data from file (maps, NPCs, teleports)
    IF (LoadMapsData() == -1)
        EXIT("MapsV5.dat file missing! Please run MAPGEN05.PRG first.", 1);
    END

    // Load initial background music from map data
    InitInitialMusic();

    // Load FPG files dynamically from map data
    LoadMapFPGs();

    // Create processes
    map_drawer();
    player();
    hud_display();

    // Needed, do not remove this loop
    LOOP
        FRAME;
    END
END

// Initialize all quest states to NOT_STARTED
FUNCTION InitQuestStates()
PRIVATE
    i;
BEGIN
    FROM i = 0 TO 9;
        quest_states[i] = QUEST_NOT_STARTED;
    END
    RETURN(0);
END

// Initialize all CG states to locked (0)
FUNCTION InitCGStates()
PRIVATE
    i;
BEGIN
    FROM i = 0 TO 9;
        cg_unlocked[i] = 0; // All CGs start locked
    END
    RETURN(0);
END

// Initialize PlayerStats from HeroList
FUNCTION InitPlayerStats()
BEGIN
    PlayerStats.name = HeroList[0].name;
    PlayerStats.max_hp = HeroList[0].hp;
    PlayerStats.current_hp = HeroList[0].hp;
    PlayerStats.max_mp = HeroList[0].mp;
    PlayerStats.current_mp = HeroList[0].mp;
    PlayerStats.attack = HeroList[0].str;
    PlayerStats.defense = HeroList[0].def;
    RETURN(0);
END

// Initialize initial background music
FUNCTION InitInitialMusic()
BEGIN
    song_id = load_song(MapData[0].map_song, 1); // 1 for indefinite loop
    song(song_id);
    current_song = MapData[0].map_song;
    RETURN(0);
END

// Loads monster database from Monsters.dat file.
// Reads all available monsters with their stats and rewards.
FUNCTION LoadMonstersData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Open the monsters data file for reading
    file_handle = fopen("Monsters.dat", "r");

    IF (file_handle == 0)
        // File doesn't exist - show error
        write(0, 10, 10, 0, "ERROR: Monsters.dat not found! Please run MAPGEN05.PRG first.");
        RETURN(-1);
    END

    // Read monster_list_count first
    fread(OFFSET monster_list_count, 1, file_handle);

    // Read entire MonsterList structure
    data_size = sizeof(MonsterList);
    fread(OFFSET MonsterList, data_size, file_handle);

    // Close the file
    fclose(file_handle);
    RETURN(0);
END

// Loads hero database from HeroesV5.dat file.
// Reads all available heroes with their stats and spells.
FUNCTION LoadHeroesData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Open the heroes data file for reading
    file_handle = fopen("HeroesV5.dat", "r");

    IF (file_handle == 0)
        // File doesn't exist - show error
        write(0, 10, 10, 0, "ERROR: HeroesV5.dat not found! Please run MAPGEN05.PRG first.");
        RETURN(-1);
    END

    // Read hero_list_count first
    fread(OFFSET hero_list_count, 1, file_handle);

    // Read entire HeroList structure
    data_size = sizeof(HeroList);
    fread(OFFSET HeroList, data_size, file_handle);

    // Close the file
    fclose(file_handle);
    RETURN(0);
END

// Loads item database from ItemsV5.dat file.
// Reads all available items with their descriptions and prices.
FUNCTION LoadItemsData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Open the items data file for reading
    file_handle = fopen("ItemsV5.dat", "r");

    IF (file_handle == 0)
        // File doesn't exist - show error
        write(0, 10, 10, 0, "ERROR: ItemsV5.dat not found! Please run MAPGEN05.PRG first.");
        RETURN(-1);
    END

    // Read item_list_count first
    fread(OFFSET item_list_count, 1, file_handle);

    // Read entire ItemList structure
    data_size = sizeof(ItemList);
    fread(OFFSET ItemList, data_size, file_handle);

    // Close the file
    fclose(file_handle);
    RETURN(0);
END

// Loads all map data from MapsV5.dat file.
// Reads map tiles, NPCs, teleports, and quest data for all maps from external file.
FUNCTION LoadMapsData()
PRIVATE
    file_handle;
    data_size;
BEGIN
    // Open the maps data file for reading
    file_handle = fopen("MapsV5.dat", "r");

    IF (file_handle == 0)
        // File doesn't exist - show error
        write(0, 10, 10, 0, "ERROR: MapsV5.dat not found! Please run MAPGEN05.PRG first.");
        RETURN(-1);
    END

    // Get size of MapData structure
    data_size = sizeof(MapData);

    // Read entire MapData structure from file
    IF (fread(OFFSET MapData, data_size, file_handle) == 0)
        // Error reading file
        write(0, 10, 10, 0, "Error loading MapsV5.dat!");
        RETURN(-1);
    END

    // Close the file
    fclose(file_handle);
    RETURN(0);
END

// Loads FPG files dynamically from map data.
FUNCTION LoadMapFPGs()
PRIVATE
    i, j, k;
    STRING loaded_npcs[6];
    INT loaded_count = 0;
    INT already_loaded;
BEGIN
    // Load map FPGs
    FROM i=0 TO MAX_MAPS-1;
        fpg_ids[i] = load_fpg(MapData[i].fpg_file);
    END

    // Load NPC FPGs (avoiding duplicates)
    FROM i=0 TO MAX_MAPS-1; // For each map
        j = 0;
        WHILE (j < MapData[i].npc_count) // For each NPC in map
            // Check if this FPG is already loaded
            already_loaded = 0;
            FOR (k = 0; k < loaded_count; k++)
                IF (strcmp(loaded_npcs[k], MapData[i].NPCData[j].fpg_file) == 0)
                    already_loaded = 1;
                    BREAK;
                END
            END

            // If not loaded yet, load it
            IF (already_loaded == 0)
                npc_fpg_ids[MapData[i].NPCData[j].npc_id] = load_fpg(MapData[i].NPCData[j].fpg_file);
                loaded_npcs[loaded_count] = MapData[i].NPCData[j].fpg_file;
                loaded_count++;
            END
            j++;
        END
    END
    RETURN(0);
END

// Initializes the Controls struct with keyboard bindings.
FUNCTION InitControls()
BEGIN
    Controls.left = _LEFT;
    Controls.right = _RIGHT;
    Controls.up = _UP;
    Controls.down = _DOWN;
    Controls.talk = _ENTER;
    Controls.inventory = _ESC;
    Controls.exit = _F10;
    RETURN(0);
END

// Changes the background music if different from current
FUNCTION ChangeSong(STRING new_song)
BEGIN
    IF (strcmp(current_song, new_song) != 0)
        unload_song(song_id);
        song_id = load_song(new_song, 1);
        song(song_id);
        current_song = new_song;
    END
    RETURN(0);
END

// Calculates frames for a given number of seconds based on current FPS
FUNCTION seconds_to_frames(INT seconds)
BEGIN
    RETURN(seconds * ScreenConfig.fps);
END

// Waits for menu keys to be released
FUNCTION wait_for_key_release()
BEGIN
    WHILE (KEY(Controls.up) OR KEY(Controls.down) OR KEY(Controls.talk) OR KEY(Controls.inventory))
        FRAME;
    END
END

// Waits for a specific key to be released
FUNCTION wait_key_release(INT key_code)
BEGIN
    WHILE (KEY(key_code))
        FRAME;
    END
END

// Handles player movement logic
FUNCTION handle_movement(INT moving_offset, INT new_direction_offset, INT speed_offset)
PRIVATE
    tile_i, tile_j;
    new_x, new_y;
BEGIN
    *moving_offset = 0;
    *new_direction_offset = PlayerData.direction;

    // Calculate current tile and speed
    tile_i = PlayerData.x / TILE_SIZE;
    tile_j = PlayerData.y / TILE_SIZE;
    IF (current_map == 0)
        *speed_offset = 5;
        IF (tile_i >= 0 AND tile_i < MapData[current_map].tilesX AND tile_j >= 0 AND tile_j < MapData[current_map].tilesY)
            IF (MapData[current_map].tiles[tile_i, tile_j] == TileTypes.forest OR MapData[current_map].tiles[tile_i, tile_j] == TileTypes.mountain)
                *speed_offset = 2;
            END
        END
    ELSE
        *speed_offset = 5;
    END

    // Movement
    IF (DialogState.process_id == 0 AND inventory_active == 0 AND in_battle == 0)
        IF (KEY(Controls.left))
            new_x = PlayerData.x - *speed_offset;
            tile_i = new_x / 32;
            tile_j = PlayerData.y / 32;
            IF (current_map == 0)
                IF (tile_i >= 0 AND tile_i < MapData[current_map].tilesX AND tile_j >= 0 AND tile_j < MapData[current_map].tilesY)
                    IF (MapData[current_map].tiles[tile_i, tile_j] != TileTypes.river)
                        PlayerData.x = new_x;
                        *moving_offset = 1;
                        *new_direction_offset = 4;
                    END
                END
            ELSE
                PlayerData.x = new_x;
                *moving_offset = 1;
                *new_direction_offset = 4;
            END
        END
        IF (KEY(Controls.right))
            new_x = PlayerData.x + *speed_offset;
            tile_i = new_x / 32;
            tile_j = PlayerData.y / 32;
            IF (current_map == 0)
                IF (tile_i >= 0 AND tile_i < MapData[current_map].tilesX AND tile_j >= 0 AND tile_j < MapData[current_map].tilesY)
                    IF (MapData[current_map].tiles[tile_i, tile_j] != TileTypes.river)
                        PlayerData.x = new_x;
                        *moving_offset = 1;
                        *new_direction_offset = 2;
                    END
                END
            ELSE
                PlayerData.x = new_x;
                *moving_offset = 1;
                *new_direction_offset = 2;
            END
        END
        IF (KEY(Controls.up))
            new_y = PlayerData.y - *speed_offset;
            tile_i = PlayerData.x / 32;
            tile_j = new_y / 32;
            IF (current_map == 0)
                IF (tile_i >= 0 AND tile_i < MapData[current_map].tilesX AND tile_j >= 0 AND tile_j < MapData[current_map].tilesY)
                    IF (MapData[current_map].tiles[tile_i, tile_j] != TileTypes.river)
                        PlayerData.y = new_y;
                        *moving_offset = 1;
                        *new_direction_offset = 1;
                    END
                END
            ELSE
                PlayerData.y = new_y;
                *moving_offset = 1;
                *new_direction_offset = 1;
            END
        END
        IF (KEY(Controls.down))
            new_y = PlayerData.y + *speed_offset;
            tile_i = PlayerData.x / 32;
            tile_j = new_y / 32;
            IF (current_map == 0)
                IF (tile_i >= 0 AND tile_i < MapData[current_map].tilesX AND tile_j >= 0 AND tile_j < MapData[current_map].tilesY)
                    IF (MapData[current_map].tiles[tile_i, tile_j] != TileTypes.river)
                        PlayerData.y = new_y;
                        *moving_offset = 1;
                        *new_direction_offset = 3;
                    END
                END
            ELSE
                PlayerData.y = new_y;
                *moving_offset = 1;
                *new_direction_offset = 3;
            END
        END
    END
END

// Handles player animation updates
FUNCTION handle_animations(INT moving, INT new_direction)
BEGIN
    // Update player animation
    PlayerData.direction = new_direction;

    IF (moving)
        PlayerData.anim_counter++;
        IF (PlayerData.anim_counter >= 5)
            PlayerData.anim_counter = 0;
            PlayerData.anim_frame = (PlayerData.anim_frame + 1) % 6;
        END

        IF (PlayerData.direction == 1)
            PlayerData.sprite_graph_id = 5 + PlayerData.anim_frame;
        ELSE
            IF (PlayerData.direction == 2)
                PlayerData.sprite_graph_id = 11 + PlayerData.anim_frame;
            ELSE
                IF (PlayerData.direction == 3)
                    PlayerData.sprite_graph_id = 17 + PlayerData.anim_frame;
                ELSE
                    PlayerData.sprite_graph_id = 23 + PlayerData.anim_frame;
                END
            END
        END
    ELSE
        PlayerData.anim_frame = 0;
        PlayerData.anim_counter = 0;

        IF (PlayerData.direction == 1)
            PlayerData.sprite_graph_id = 1;
        ELSE
            IF (PlayerData.direction == 2)
                PlayerData.sprite_graph_id = 2;
            ELSE
                IF (PlayerData.direction == 3)
                    PlayerData.sprite_graph_id = 3;
                ELSE
                    PlayerData.sprite_graph_id = 4;
                END
            END
        END
    END
END

// Handles player interactions with NPCs and menus
FUNCTION handle_interactions(INT closest_npc_offset, INT enter_pressed_offset, INT inventory_close_timer_offset)
PRIVATE
    temp_dist;
    min_dist;
    i;
    npc_id;
    STRING dialogue_text;
BEGIN
    // Calculate distances for interaction
    *closest_npc_offset = -1;
    min_dist = 51;
    i = 0;
    WHILE (i < MapData[current_map].npc_count)
        temp_dist = sqrt((PlayerData.x - MapData[current_map].NPCData[i].x) * (PlayerData.x - MapData[current_map].NPCData[i].x) + (PlayerData.y - MapData[current_map].NPCData[i].y) * (PlayerData.y - MapData[current_map].NPCData[i].y));
        IF (temp_dist < 50 AND temp_dist < min_dist)
            *closest_npc_offset = i;
            min_dist = temp_dist;
        END
        i++;
    END

    // Check interaction with NPCs
    IF (KEY(Controls.talk))
        IF (*enter_pressed_offset == 0 AND *closest_npc_offset != -1 AND inventory_active == 0 AND *inventory_close_timer_offset == 0 AND in_battle == 0)
            IF (DialogState.press_timer == 0)
                DialogState.press_timer = ScreenConfig.fps / 2;
                IF (DialogState.process_id == 0)
                    npc_id = MapData[current_map].NPCData[*closest_npc_offset].npc_id;

                    // Check if NPC has a quest
                    IF (MapData[current_map].NPCData[*closest_npc_offset].has_quest == 1)
                        // Quest NPC - determine dialogue based on quest state
                        IF (quest_states[npc_id] == QUEST_NOT_STARTED)
                            // Offer quest
                            i = 0;
                            WHILE (i < MapData[current_map].NPCData[*closest_npc_offset].quest_dialogue_count)
                                temp_dialogues[i].dialogue = MapData[current_map].NPCData[*closest_npc_offset].quest_dialogues[i].dialogue;
                                temp_dialogues[i].cg_id = MapData[current_map].NPCData[*closest_npc_offset].quest_dialogues[i].cg_id;
                                i++;
                            END
                            temp_dialogue_count = MapData[current_map].NPCData[*closest_npc_offset].quest_dialogue_count;
                            DialogState.process_id = dialogue(MapData[current_map].NPCData[*closest_npc_offset].name, 1, 0);
                            DialogState.is_quest = 1;
                            DialogState.quest_npc_id = npc_id;
                            DialogState.current_npc_index = *closest_npc_offset;
                            DialogState.current_map_index = current_map;
                        ELSE
                            IF (quest_states[npc_id] == QUEST_ACTIVE)
                                // Check if quest can be completed
                                IF (HasItems(MapData[current_map].NPCData[*closest_npc_offset].quest_item_id, MapData[current_map].NPCData[*closest_npc_offset].quest_item_count))
                                    // Can complete quest
                                    i = 0;
                                    WHILE (i < MapData[current_map].NPCData[*closest_npc_offset].quest_complete_count)
                                        temp_dialogues[i].dialogue = MapData[current_map].NPCData[*closest_npc_offset].quest_complete_texts[i].text;
                                        temp_dialogues[i].cg_id = MapData[current_map].NPCData[*closest_npc_offset].quest_complete_texts[i].cg_id;
                                        i++;
                                    END
                                    temp_dialogue_count = MapData[current_map].NPCData[*closest_npc_offset].quest_complete_count;
                                    DialogState.process_id = dialogue(MapData[current_map].NPCData[*closest_npc_offset].name, 0, 0);
                                    // Complete quest
                                    RemoveItems(MapData[current_map].NPCData[*closest_npc_offset].quest_item_id, MapData[current_map].NPCData[*closest_npc_offset].quest_item_count);
                                    player_gold = player_gold + MapData[current_map].NPCData[*closest_npc_offset].quest_gold_reward;
                                    quest_states[npc_id] = QUEST_COMPLETED;
                                ELSE
                                    // Quest in progress
                                    i = 0;
                                    WHILE (i < MapData[current_map].NPCData[*closest_npc_offset].quest_progress_count)
                                        temp_dialogues[i].dialogue = MapData[current_map].NPCData[*closest_npc_offset].quest_progress_texts[i].text;
                                        temp_dialogues[i].cg_id = MapData[current_map].NPCData[*closest_npc_offset].quest_progress_texts[i].cg_id;
                                        i++;
                                    END
                                    temp_dialogue_count = MapData[current_map].NPCData[*closest_npc_offset].quest_progress_count;
                                    DialogState.process_id = dialogue(MapData[current_map].NPCData[*closest_npc_offset].name, 0, 0);
                                END
                            ELSE
                                // Quest completed
                                i = 0;
                                WHILE (i < MapData[current_map].NPCData[*closest_npc_offset].quest_reward_count)
                                    temp_dialogues[i].dialogue = MapData[current_map].NPCData[*closest_npc_offset].quest_reward_texts[i].text;
                                    temp_dialogues[i].cg_id = MapData[current_map].NPCData[*closest_npc_offset].quest_reward_texts[i].cg_id;
                                    i++;
                                END
                                temp_dialogue_count = MapData[current_map].NPCData[*closest_npc_offset].quest_reward_count;
                                DialogState.process_id = dialogue(MapData[current_map].NPCData[*closest_npc_offset].name, 0, 0);
                            END
                        END
                    ELSE
                        // Regular NPC dialogue - copy to temp storage
                        i = 0;
                        WHILE (i < MapData[current_map].NPCData[*closest_npc_offset].dialogue_count)
                            temp_dialogues[i].dialogue = MapData[current_map].NPCData[*closest_npc_offset].dialogues[i].dialogue;
                            temp_dialogues[i].cg_id = MapData[current_map].NPCData[*closest_npc_offset].dialogues[i].cg_id;
                            i++;
                        END
                        temp_dialogue_count = MapData[current_map].NPCData[*closest_npc_offset].dialogue_count;
                        DialogState.process_id = dialogue(MapData[current_map].NPCData[*closest_npc_offset].name, MapData[current_map].NPCData[*closest_npc_offset].gives_item, MapData[current_map].NPCData[*closest_npc_offset].item_id);
                    END
                END
            END
            *enter_pressed_offset = 1;
        END
    ELSE
        *enter_pressed_offset = 0;
    END

    // Decrement timers
    IF (DialogState.press_timer > 0)
        DialogState.press_timer--;
    END
    IF ((*inventory_close_timer_offset) > 0)
        (*inventory_close_timer_offset)--;
    END
END

// Displays HUD information (gold count).
PROCESS hud_display()
PRIVATE
    gold_text_id = 0;
    STRING gold_str;
BEGIN
    LOOP
        IF (inventory_active == 0)
            // Display gold
            IF (gold_text_id != 0)
                delete_text(gold_text_id);
            END
            gold_str = "Gold: " + itoa(player_gold);
            gold_text_id = write(0, 10, 10, 0, gold_str);
        ELSE
            // Hide gold during inventory
            IF (gold_text_id != 0)
                delete_text(gold_text_id);
                gold_text_id = 0;
            END
        END
        FRAME;
    END
END

// Central rendering process.
PROCESS map_drawer()
PRIVATE
    tile_i, tile_j, npc_index, color, x1, y1, x2, y2;
    dist_x, dist_y;
    i_min, i_max, j_min, j_max;
    map_width, map_height;
    dirty;
    last_inventory_state;
    tile_code;
BEGIN
    force_redraw = 1;
    last_inventory_state = inventory_active;
    LOOP
        // Detect inventory state change to force redraw when closing
        IF (inventory_active != last_inventory_state)
            IF (inventory_active == 0)
                force_redraw = 1;
            END
            last_inventory_state = inventory_active;
        END

        // Only draw map if inventory is not active
        IF (inventory_active == 0)
            // Dirty rectangle: only redraw if map or camera changes
            dirty = 0;
            IF (offset_x != prev_offset_x OR offset_y != prev_offset_y OR current_map != prev_map OR force_redraw == 1)
                dirty = 1;
            END

            // Always clear screen to prevent sprite accumulation from put()
            clear_screen();

            // Current map dimensions
            map_width = MapData[current_map].tilesX;
            map_height = MapData[current_map].tilesY;

            // Visible tile range
            IF (((-offset_x + 31) / TILE_SIZE) - 1 > 0) i_min = ((-offset_x + 31) / TILE_SIZE) - 1; ELSE i_min = 0; END
            IF (map_width - 1 < ((ScreenConfig.width - offset_x) / TILE_SIZE) + 1) i_max = map_width - 1; ELSE i_max = ((ScreenConfig.width - offset_x) / TILE_SIZE) + 1; END
            IF (((-offset_y + 31) / TILE_SIZE) - 1 > 0) j_min = ((-offset_y + 31) / TILE_SIZE) - 1; ELSE j_min = 0; END
            IF (map_height - 1 < ((ScreenConfig.height - offset_y) / TILE_SIZE) + 1) j_max = map_height - 1; ELSE j_max = ((ScreenConfig.height - offset_y) / TILE_SIZE) + 1; END

            // Apply zoom effect during dialogues

            tile_i = i_min;
            WHILE (tile_i <= i_max)
                tile_j = j_min;
                WHILE (tile_j <= j_max)
                    x1 = tile_i * TILE_SIZE + offset_x;
                    y1 = tile_j * TILE_SIZE + offset_y;

                    // Apply zoom transformation centered on player (screen center)
                    x1 = ScreenConfig.width / 2 + ((x1 - ScreenConfig.width / 2) * dialogue_zoom) / 100;
                    y1 = ScreenConfig.height / 2 + ((y1 - ScreenConfig.height / 2) * dialogue_zoom) / 100;

                    // Get tile code
                    tile_code = MapData[current_map].tiles[tile_i,tile_j];
                    // Draw sprite with zoom - xput handles the scaling
                    xput(fpg_ids[current_map], tile_code, x1 + 16, y1 + 16, 0, dialogue_zoom, 0, 0);
                    tile_j++;
                END
                tile_i++;
            END

            // Update previous values
            prev_offset_x = offset_x;
            prev_offset_y = offset_y;
            prev_map = current_map;
            force_redraw = 0;

            // Draw NPCs (only if not in battle)
            IF (in_battle == 0)
                npc_index = 0;
                WHILE (npc_index < MapData[current_map].npc_count)
                    // Calculate screen position
                    x1 = MapData[current_map].NPCData[npc_index].x + offset_x;
                    y1 = MapData[current_map].NPCData[npc_index].y + offset_y;

                    // Apply zoom transformation centered on player (screen center)
                    x1 = ScreenConfig.width / 2 + ((x1 - ScreenConfig.width / 2) * dialogue_zoom) / 100;
                    y1 = ScreenConfig.height / 2 + ((y1 - ScreenConfig.height / 2) * dialogue_zoom) / 100;

                    // Check if visible on screen
                    IF (x1 + 16 > 0 AND x1 - 16 < ScreenConfig.width AND y1 + 16 > 0 AND y1 - 16 < ScreenConfig.height)
                        // Update NPC direction to face player
                        dist_x = abs(PlayerData.x - MapData[current_map].NPCData[npc_index].x);
                        dist_y = abs(PlayerData.y - MapData[current_map].NPCData[npc_index].y);

                        IF (dist_x > dist_y)
                            IF (PlayerData.x > MapData[current_map].NPCData[npc_index].x)
                                MapData[current_map].NPCData[npc_index].sprite_graph_id = 2; // Look right
                            ELSE
                                MapData[current_map].NPCData[npc_index].sprite_graph_id = 4; // Look left
                            END
                        ELSE
                            IF (PlayerData.y < MapData[current_map].NPCData[npc_index].y)
                                MapData[current_map].NPCData[npc_index].sprite_graph_id = 1; // Look up
                            ELSE
                                MapData[current_map].NPCData[npc_index].sprite_graph_id = 3; // Look down
                            END
                        END
                        // Draw NPC shadow
                        xput(hud_fpg_id, 3, x1, y1, 0, dialogue_zoom, 4, 0);
                        // Draw NPC sprite
                        xput(npc_fpg_ids[MapData[current_map].NPCData[npc_index].npc_id], MapData[current_map].NPCData[npc_index].sprite_graph_id, x1, y1 - 24, 0, dialogue_zoom, 0, 0);
                    END
                    npc_index++;
                END
            END

            // Draw player (only if not in battle)
            IF (in_battle == 0)
                // Draw player shadow
                xput(hud_fpg_id, 3, ScreenConfig.width / 2, ScreenConfig.height / 2, 0, dialogue_zoom, 4, 0);
                // Draw player sprite
                xput(player_fpg_id, PlayerData.sprite_graph_id, ScreenConfig.width / 2, ScreenConfig.height / 2 - 24, 0, dialogue_zoom, 0, 0);
            END
        END

        // Centralized UI rendering (always on top of map)
        // Draw dialogue box if active
        IF (show_dialogue_box == 1)
            put(hud_fpg_id, 1, ScreenConfig.width / 2, ScreenConfig.height - 25);
        END

        // Draw dialogue CG if active
        IF (show_dialogue_cg > 0 AND dialogue_zoom >= 150)
            put(cg_fpg_id, show_dialogue_cg, ScreenConfig.width / 2, 75);
        END

        // Draw menu background if active
        IF (show_menu_bg == 1)
            put(hud_fpg_id, 2, ScreenConfig.width / 2, ScreenConfig.height / 2);
        END

        // Draw gallery CG if viewing
        IF (show_gallery_cg > 0)
            put(cg_fpg_id, show_gallery_cg, ScreenConfig.width / 2, 75);
        END

        // Draw battle box if active
        IF (show_battle_box == 1)
            put(hud_fpg_id, 1, ScreenConfig.width / 2, ScreenConfig.height - 25);
        END

        FRAME;
    END
END

// Handles all player logic and interactions.
PROCESS player()
PRIVATE
    screen_x, screen_y;
    tile_i, tile_j, speed;
    new_x, new_y;
    closest_npc = -1;
    temp_dist;
    min_dist;
    i;
    npc_map;
    exit_direction;
    INT enter_pressed = 0;
    INT inventory_close_timer = 0;
    INT k;
    INT moving = 0;
    INT new_direction = 0;
    INT npc_id;
    STRING dialogue_text;
BEGIN
    x = PlayerData.x;
    y = PlayerData.y;
    LOOP
        // Draw battle overlay if in battle
        IF (in_battle == 1 AND after_battle_start == 1)
        END

        handle_movement(OFFSET(moving), OFFSET(new_direction), OFFSET(speed));

        handle_animations(moving, new_direction);

        // Random encounters on world map
        IF (moving AND current_map == 0 AND in_battle == 0)
            step_counter++;
            IF (step_counter >= steps_until_battle)
                // Trigger random battle
                step_counter = 0;
                steps_until_battle = 30 + rand(0, 40); // Random 30-70 steps
                in_battle = 1;
                battle_process_id = battle_screen();
                // Battle will reset in_battle when it finishes
            END
        END

        // Check for exiting city boundaries
        IF (current_map != 0 AND (PlayerData.x < 0 OR PlayerData.x >= 256 OR PlayerData.y < 0 OR PlayerData.y >= 256))
            prev_map = -1;
            prev_offset_x = -9999;
            prev_offset_y = -9999;
            fade_off();
            exit_direction = 0;
            IF (PlayerData.y < 0)
                exit_direction = 0;
            ELSE
                IF (PlayerData.y >= 256)
                    exit_direction = 1;
                ELSE
                    IF (PlayerData.x < 0)
                        exit_direction = 2;
                    ELSE
                        exit_direction = 3;
                    END
                END
            END
            IF (current_map == 1)
                current_map = 0;
                ChangeSong(MapData[current_map].map_song);
                IF (exit_direction == 0)
                    PlayerData.x = 7 * 32;
                    PlayerData.y = 4 * 32;
                ELSE
                    IF (exit_direction == 1)
                        PlayerData.x = 7 * 32;
                        PlayerData.y = 9 * 32;
                    ELSE
                        IF (exit_direction == 2)
                            PlayerData.x = 5 * 32;
                            PlayerData.y = 6 * 32;
                        ELSE
                            PlayerData.x = 10 * 32;
                            PlayerData.y = 6 * 32;
                        END
                    END
                END
            ELSE
                IF (current_map == 2)
                    current_map = 0;
                    ChangeSong(MapData[current_map].map_song);
                    IF (exit_direction == 0)
                        PlayerData.x = 21 * 32;
                        PlayerData.y = 14 * 32;
                    ELSE
                        IF (exit_direction == 1)
                            PlayerData.x = 21 * 32;
                            PlayerData.y = 19 * 32;
                        ELSE
                            IF (exit_direction == 2)
                                PlayerData.x = 19 * 32;
                                PlayerData.y = 16 * 32;
                            ELSE
                                PlayerData.x = 24 * 32;
                                PlayerData.y = 16 * 32;
                            END
                        END
                    END
                END
            END
            fade_on();
            force_redraw = 1;
        END

        // Center camera on player
        offset_x = ScreenConfig.width / 2 - PlayerData.x;
        offset_y = ScreenConfig.height / 2 - PlayerData.y;
        screen_x = ScreenConfig.width / 2;
        screen_y = ScreenConfig.height / 2;

        IF (KEY(Controls.inventory))
            IF (DialogState.press_timer == 0 AND inventory_close_timer == 0 AND inventory_active == 0 AND in_battle == 0)
                DialogState.press_timer = ScreenConfig.fps / 2;
                inventory_screen();
                inventory_close_timer = ScreenConfig.fps;
            END
        END

        IF (KEY(Controls.exit))
            unload_song(song_id);
            EXIT("Goodbye", 0);
        END

        x = PlayerData.x;
        y = PlayerData.y;

        handle_interactions(OFFSET(closest_npc), OFFSET(enter_pressed), OFFSET(inventory_close_timer));

        // Check for map transitions
        IF (current_map == 0)
            tile_i = PlayerData.x / 32;
            tile_j = PlayerData.y / 32;
            k = 0;
            WHILE (k < MapData[0].teleport_count)
                IF (tile_i == MapData[0].TeleportData[k].tile_i AND tile_j == MapData[0].TeleportData[k].tile_j)
                    prev_map = -1;
                    prev_offset_x = -9999;
                    prev_offset_y = -9999;
                    fade_off();
                    current_map = MapData[0].TeleportData[k].target_map;
                    ChangeSong(MapData[current_map].map_song);
                    PlayerData.x = MapData[0].TeleportData[k].target_x;
                    PlayerData.y = MapData[0].TeleportData[k].target_y;
                    fade_on();
                    BREAK;
                END
                k++;
            END
        END

        FRAME;
    END
END

// Handles victory condition and rewards in battle
FUNCTION handle_victory(INT num_enemies, INT battle_active_offset, INT message_text_id_offset, INT msg_timer_offset, STRING battle_msg)
PRIVATE
    INT enemy_alive_count;
    INT i, j;
    INT found;
    INT reward_gold_total = 0;
    INT items_gained = 0;
BEGIN
    // Check victory condition first
    enemy_alive_count = 0;
    i = 0;
    WHILE (i < num_enemies)
        IF (Enemies[i].alive == 1)
            enemy_alive_count++;
        END
        i++;
    END

    IF (enemy_alive_count == 0 AND *battle_active_offset == 1)
        // All enemies defeated - victory!
        // Only give rewards once
        reward_gold_total = 0;
        items_gained = 0;
        i = 0;
        WHILE (i < num_enemies)
            player_gold = player_gold + MonsterList[Enemies[i].monster_id].reward_gold;
            reward_gold_total = reward_gold_total + MonsterList[Enemies[i].monster_id].reward_gold;

            // Add item to inventory
            found = -1;
            FOR (j = 0; j < item_count; j++)
                IF (strcmp(inventory[j].item, ItemList[MonsterList[Enemies[i].monster_id].reward_item_id].name) == 0)
                    found = j;
                    BREAK;
                END
            END
            IF (found != -1)
                inventory[found].quantity++;
            ELSE
                IF (item_count < 10)
                    inventory[item_count].item = ItemList[MonsterList[Enemies[i].monster_id].reward_item_id].name;
                    inventory[item_count].quantity = 1;
                    inventory[item_count].description = ItemList[MonsterList[Enemies[i].monster_id].reward_item_id].description;
                    item_count++;
                END
            END
            items_gained++;
            i++;
        END

        IF (*message_text_id_offset != 0)
            delete_text(*message_text_id_offset);
        END
        // Clear action and enemy texts
        FROM i=0 TO 3;
            // Assuming ActionText and EnemyText are global or passed, but for simplicity, we'll handle in main
        END
        battle_msg = "VICTORY! Gained ";
        battle_msg = battle_msg + itoa(reward_gold_total);
        battle_msg = battle_msg + " gold and ";
        battle_msg = battle_msg + itoa(items_gained);
        battle_msg = battle_msg + " ";
        battle_msg = battle_msg + ItemList[MonsterList[0].reward_item_id].name;
        battle_msg = battle_msg + "s!";
        *message_text_id_offset = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);
        ChangeSong("MOD/ILUETNI.XM");
        *msg_timer_offset = seconds_to_frames(2);
        *battle_active_offset = 0; // This prevents re-entry into this block
        // Wait for message to finish
        WHILE (*msg_timer_offset > 0)
            // Draw enemies during wait
            j = 0;
            WHILE (j < num_enemies)
                IF (Enemies[j].alive == 1)
                    xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                END
                j++;
            END
            FRAME;
            (*msg_timer_offset)--;
        END
    END
END

// Handles battle animations (enemy drawing and dying)
FUNCTION handle_battle_animations(INT num_enemies)
PRIVATE
    INT i;
BEGIN
    // Draw enemies
    i = 0;
    WHILE (i < num_enemies)
        IF (Enemies[i].alive == 1)
            // Handle dying animation
            IF (Enemies[i].dying == 1)
                Enemies[i].size = (Enemies[i].dying_timer * 100) / seconds_to_frames(1);
                flags = 4; // transparent
                Enemies[i].dying_timer--;
                IF (Enemies[i].dying_timer <= 0)
                    Enemies[i].alive = 0;
                    Enemies[i].dying = 0;
                END
            ELSE
                flags = 0;
                Enemies[i].size = 100;
            END

            // Draw slime (centered horizontally, spaced vertically)
            IF (selecting_target == 1 AND i == selected_target)
                // Selected enemy: larger (120%) and transparent (flags=4), but override if dying
                IF (Enemies[i].dying == 0)
                    xput(monsters_fpg_id, MonsterList[Enemies[i].monster_id].sprite_graph_id, 80 + i * 80, 60, 0, 120, 4, 0);
                ELSE
                    xput(monsters_fpg_id, MonsterList[Enemies[i].monster_id].sprite_graph_id, 80 + i * 80, 60, 0, Enemies[i].size, flags, 0);
                END
            ELSE
                // Normal enemy
                xput(monsters_fpg_id, MonsterList[Enemies[i].monster_id].sprite_graph_id, 80 + i * 80, 60, 0, Enemies[i].size, flags, 0);
            END
        END
        i++;
    END
END

// Handles turn-based logic in battle
FUNCTION handle_turns(INT num_enemies, INT player_turn_offset, INT battle_active_offset, INT message_text_id_offset, INT msg_timer_offset, STRING battle_msg, INT input_timer_offset)
PRIVATE
    INT damage;
    INT enemy_alive_count;
    INT enemy_action;
    INT all_enemies_dead;
    INT player_dead;
    INT found;
    INT any_dying = 0;
    INT items_gained = 0;
    INT mp_cost = 0;
    INT i, j;
BEGIN
    // Only process turns when msg_timer is 0 and battle is still active
    IF (*msg_timer_offset == 0 AND *battle_active_offset == 1)
        IF (*player_turn_offset)
            // Player's turn - Show "Your turn" message and menu
            // This is complex, so for now, keep in main, but we can extract parts
            // For simplicity, this function will handle the core turn logic after menu selection
            // Assuming the menu is handled in main, and here we handle the actions
        END
    END

    IF (*player_turn_offset == 0)
        // Check if any enemy is dying
        any_dying = 0;
        i = 0;
        WHILE (i < num_enemies)
            IF (Enemies[i].dying == 1)
                any_dying = 1;
                BREAK;
            END
            i++;
        END

        IF (any_dying == 0)
            // Enemy turn - attacks immediately since msg_timer == 0
            i = 0;
            WHILE (i < num_enemies)
                IF (Enemies[i].alive == 1)
                    damage = MonsterList[Enemies[i].monster_id].attack - PlayerStats.defense;
                    IF (damage < 1)
                        damage = 1;
                    END
                    PlayerStats.current_hp = PlayerStats.current_hp - damage;

                    IF (*message_text_id_offset != 0)
                        delete_text(*message_text_id_offset);
                    END
                    battle_msg = MonsterList[Enemies[i].monster_id].name + " attacks!";
                    *message_text_id_offset = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);
                    *msg_timer_offset = seconds_to_frames(2);
                    // Wait for message to finish
                    WHILE (*msg_timer_offset > 0)
                        // Draw enemies during wait
                        j = 0;
                        WHILE (j < num_enemies)
                            IF (Enemies[j].alive == 1)
                                xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                            END
                            j++;
                        END
                        FRAME;
                        (*msg_timer_offset)--;
                    END
                    // Then show damage message
                    IF (*message_text_id_offset != 0)
                        delete_text(*message_text_id_offset);
                    END
                    battle_msg = "You took ";
                    battle_msg = battle_msg + itoa(damage);
                    battle_msg = battle_msg + " damage!";
                    *message_text_id_offset = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);
                    *msg_timer_offset = seconds_to_frames(2);
                    // Wait again
                    WHILE (*msg_timer_offset > 0)
                        // Draw enemies during wait
                        j = 0;
                        WHILE (j < num_enemies)
                            IF (Enemies[j].alive == 1)
                                xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                            END
                            j++;
                        END
                        FRAME;
                        (*msg_timer_offset)--;
                    END
                    BREAK; // One enemy attacks per turn
                END
                i++;
            END

            IF (PlayerStats.current_hp <= 0)
                PlayerStats.current_hp = 0;
                IF (*message_text_id_offset != 0)
                    delete_text(*message_text_id_offset);
                END
                // Clear action and enemy texts
                j = 0;
                WHILE (j < 3)
                    // Assuming ActionText and EnemyText are global
                    j++;
                END
                *message_text_id_offset = write(0, 50, 170, 0, "DEFEAT!");
                *msg_timer_offset = seconds_to_frames(2);
                // Wait for message to finish
                WHILE (*msg_timer_offset > 0)
                    // Draw enemies
                    j = 0;
                    WHILE (j < num_enemies)
                        IF (Enemies[j].alive == 1)
                            xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                        END
                        j++;
                    END
                    FRAME;
                    (*msg_timer_offset)--;
                END
                *battle_active_offset = 0;
            ELSE
                *player_turn_offset = 1;
            END
        END
    END
END

// Check if player has specified number of items.
FUNCTION HasItems(INT item_id, INT count_needed)
PRIVATE
    i;
BEGIN
    i = 0;
    WHILE (i < item_count)
        IF (strcmp(inventory[i].item, ItemList[item_id].name) == 0)
            IF (inventory[i].quantity >= count_needed)
                RETURN(1); // Has enough items
            ELSE
                RETURN(0); // Not enough items
            END
        END
        i++;
    END
    RETURN(0); // Item not found
END

// Remove specified number of items from inventory.
FUNCTION RemoveItems(INT item_id, INT count_to_remove)
PRIVATE
    i;
BEGIN
    i = 0;
    WHILE (i < item_count)
        IF (strcmp(inventory[i].item, ItemList[item_id].name) == 0)
            inventory[i].quantity = inventory[i].quantity - count_to_remove;
            IF (inventory[i].quantity <= 0)
                // Remove item from inventory by shifting array
                WHILE (i < item_count - 1)
                    inventory[i].item = inventory[i + 1].item;
                    inventory[i].quantity = inventory[i + 1].quantity;
                    inventory[i].description = inventory[i + 1].description;
                    i++;
                END
                item_count--;
            END
            RETURN;
        END
        i++;
    END
    RETURN(0);
END

// Manages the interactive dialogue system with multiple dialogues support.
// Uses global temp_dialogues and temp_dialogue_count instead of parameters
PROCESS dialogue(STRING name, INT has_options, INT item_id)
PRIVATE
    STRING temp;
    STRING text[50];
    index = 0;
    letter_delay = 0;
    text_id = 0;
    name_id = 0;
    indicator_id = 0;
    options_text_ids[2];
    options_box_id = 0;
    selected_option = 0;
    showing_options = 0;
    STRUCT OptionStrings[2]
        STRING normal;
        STRING selected;
    END
    i;
    len;
    complete = 0;
    INT input_timer = 0;
    INT enter_pressed = 0;
    INT frame_counter = 0;
    INT j;
    INT found;
BEGIN
    // Initialize options
    OptionStrings[0].normal = "  Yes";
    OptionStrings[0].selected = "> Yes";
    OptionStrings[1].normal = "  No";
    OptionStrings[1].selected = "> No";
    DialogState.closing = 0;
    DialogState.close_timer = 0;
    DialogState.open_timer = 5;
    DialogState.skip = 0;
    DialogState.complete = 0;
    DialogState.has_options = has_options;
    DialogState.item_to_give = item_id;
    DialogState.current_dialogue_index = 0;
    DialogState.total_dialogues = temp_dialogue_count;
    DialogState.is_quest = 0;
    DialogState.quest_npc_id = 0;

    // Get first dialogue text and CG
    text = temp_dialogues[0].dialogue;
    len = strlen(text);
    DialogState.current_cg_id = temp_dialogues[0].cg_id;

    // Unlock CG if it exists and hasn't been unlocked yet
    IF (DialogState.current_cg_id > 0 AND DialogState.current_cg_id <= cg_count)
        IF (cg_unlocked[DialogState.current_cg_id] == 0)
            cg_unlocked[DialogState.current_cg_id] = 1; // Unlock CG
        END
    END

    name_id = write(0, 30, ScreenConfig.height - 45, 0, name);
    enter_pressed = 1; // Prevent immediate input activation
    LOOP
        // Check if menus are active - close dialogue if so
        IF (inventory_active == 1)
            DialogState.closing = 1;
        END

        // Smooth zoom transition
        IF (dialogue_zoom < 200)
            dialogue_zoom = dialogue_zoom + 10;
            IF (dialogue_zoom > 200)
                dialogue_zoom = 200;
            END
        END

        // Update graphics control variables
        show_dialogue_box = 1;
        show_dialogue_cg = DialogState.current_cg_id;

        IF (DialogState.open_timer > 0)
            DialogState.open_timer--;
        END

        IF (input_timer > 0)
            input_timer--;
        END

        // Reset enter_pressed only when key is released
        IF (enter_pressed == 1 AND NOT KEY(Controls.talk))
            enter_pressed = 0;
        END

        // Animate text letter by letter
        IF (DialogState.skip AND index < len)
            index = len;
            DialogState.skip = 0;
            i = 0;
            WHILE (i < index)
                temp[i] = text[i];
                i++;
            END
            temp[index] = 0;
            complete = 1;
            DialogState.complete = 1;
            letter_delay = 0;
        END
        IF (index < len AND DialogState.skip == 0)
            IF (letter_delay == 0)
                index++;
                i = 0;
                WHILE (i < index)
                    temp[i] = text[i];
                    i++;
                END
                temp[index] = 0;
                letter_delay = ScreenConfig.fps / 15;
            ELSE
                letter_delay--;
            END
        ELSE
            IF (complete == 0)
                complete = 1;
                DialogState.complete = 1;
                i = 0;
                WHILE (i < len)
                    temp[i] = text[i];
                    i++;
                END
                temp[len] = 0;
            END
        END

        // Write current text
        IF (text_id != 0)
            delete_text(text_id);
        END
        text_id = write(0, 30, ScreenConfig.height - 30, 0, temp);

        // Show indicator
        IF (indicator_id != 0)
            delete_text(indicator_id);
            indicator_id = 0;
        END
        IF (complete == 1 AND DialogState.has_options == 0 AND DialogState.open_timer == 0)
            IF ((frame_counter / 15) % 2 == 0)
                indicator_id = write(0, ScreenConfig.width - 80, ScreenConfig.height - 20, 0, "[ENTER]");
            END
        END

        // Handle skip and advance
        IF (KEY(Controls.talk) AND DialogState.open_timer == 0 AND enter_pressed == 0 AND showing_options == 0)
            IF (complete == 1)
                DialogState.closing = 1;
            ELSE
                DialogState.skip = 1;
            END
            enter_pressed = 1;
            wait_key_release(Controls.talk);
        END

        // Show options if complete
        IF (complete == 1 AND DialogState.has_options == 1)
            IF (showing_options == 0)
                showing_options = 1;
                input_timer = ScreenConfig.fps/3*2;
                enter_pressed = 1;
            END
        END

        // Handle options menu
        IF (showing_options)
            FROM i=0 TO 1;
                IF (options_text_ids[i] != 0)
                    delete_text(options_text_ids[i]);
                    options_text_ids[i] = 0;
                END
            END

            IF (KEY(Controls.up))
                selected_option = (selected_option - 1 + 2) % 2;
                wait_key_release(Controls.up);
            END
            IF (KEY(Controls.down))
                selected_option = (selected_option + 1) % 2;
                wait_key_release(Controls.down);
            END

            // Display options
            FROM i=0 TO 1;
                IF (i == selected_option)
                    options_text_ids[i] = write(0, 240, ScreenConfig.height - 20 + i * 10, 0, OptionStrings[i].selected);
                ELSE
                    options_text_ids[i] = write(0, 240, ScreenConfig.height - 20 + i * 10, 0, OptionStrings[i].normal);
                END
            END

            IF (KEY(Controls.talk))
                IF (enter_pressed == 0)
                    // Handle quest acceptance
                    IF (DialogState.is_quest == 1)
                        IF (selected_option == 0)
                            // Accept quest - show acceptance text(s) if available
                            IF (MapData[DialogState.current_map_index].NPCData[DialogState.current_npc_index].quest_accept_count > 0)
                                // Close current dialogue and show accept texts
                                DialogState.current_dialogue_index = 0;
                                DialogState.total_dialogues = MapData[DialogState.current_map_index].NPCData[DialogState.current_npc_index].quest_accept_count;
                                j = 0;
                                WHILE (j < MapData[DialogState.current_map_index].NPCData[DialogState.current_npc_index].quest_accept_count)
                                    temp_dialogues[j].dialogue = MapData[DialogState.current_map_index].NPCData[DialogState.current_npc_index].quest_accept_texts[j].text;
                                    temp_dialogues[j].cg_id = MapData[DialogState.current_map_index].NPCData[DialogState.current_npc_index].quest_accept_texts[j].cg_id;
                                    j++;
                                END
                                // Reset to show first accept text
                                text = temp_dialogues[0].dialogue;
                                len = strlen(text);
                                index = 0;
                                complete = 0;
                                DialogState.complete = 0;
                                DialogState.has_options = 0;
                                DialogState.closing = 0; // Don't close, show accept text
                                DialogState.open_timer = ScreenConfig.fps/3*2;
                                temp[0] = 0;
                                showing_options = 0; // Clear options immediately
                                // Delete option texts from screen
                                IF (options_text_ids[0] != 0)
                                    delete_text(options_text_ids[0]);
                                    options_text_ids[0] = 0;
                                END
                                IF (options_text_ids[1] != 0)
                                    delete_text(options_text_ids[1]);
                                    options_text_ids[1] = 0;
                                END
                                enter_pressed = 1; // Keep enter pressed to prevent immediate skip
                                input_timer = ScreenConfig.fps/3*2; // Long timer to prevent input
                            END
                            quest_states[DialogState.quest_npc_id] = QUEST_ACTIVE;
                            // Don't close dialogue - continue showing accept texts
                        ELSE
                            // Rejected quest
                            DialogState.closing = 1;
                        END
                        // Reset quest flag after handling
                        DialogState.is_quest = 0;
                    ELSE
                        // Regular item giving
                        IF (selected_option == 0)
                            found = -1;
                            FOR (j = 0; j < item_count; j++)
                                IF (strcmp(inventory[j].item, ItemList[DialogState.item_to_give].name) == 0)
                                    found = j;
                                    BREAK;
                                END
                            END
                            IF (found != -1)
                                inventory[found].quantity++;
                            ELSE
                                IF (item_count < 10)
                                    inventory[item_count].item = ItemList[DialogState.item_to_give].name;
                                    inventory[item_count].quantity = 1;
                                    inventory[item_count].description = ItemList[DialogState.item_to_give].description;
                                    item_count++;
                                END
                            END
                        END
                        // Close dialogue after handling item
                        DialogState.closing = 1;
                    END
                    showing_options = 0;
                    enter_pressed = 1;
                    input_timer = 10;
                ELSE
                    enter_pressed = 0;
                END
            END
        END

        // Check closing
        IF (DialogState.closing)
            IF (complete == 0)
                index = len;
                i = 0;
                WHILE (i < len)
                    temp[i] = text[i];
                    i++;
                END
                temp[len] = 0;
                complete = 1;
            ELSE
                // Check if there are more dialogues to show
                IF (DialogState.current_dialogue_index < DialogState.total_dialogues - 1)
                    // Move to next dialogue
                    DialogState.current_dialogue_index++;
                    text = temp_dialogues[DialogState.current_dialogue_index].dialogue;
                    DialogState.current_cg_id = temp_dialogues[DialogState.current_dialogue_index].cg_id;

                    // Unlock new CG if it exists
                    IF (DialogState.current_cg_id > 0 AND DialogState.current_cg_id <= cg_count)
                        IF (cg_unlocked[DialogState.current_cg_id] == 0)
                            cg_unlocked[DialogState.current_cg_id] = 1;
                        END
                    END

                    len = strlen(text);
                    index = 0;
                    complete = 0;
                    DialogState.complete = 0;
                    DialogState.closing = 0;
                    DialogState.open_timer = ScreenConfig.fps/3*2;
                    temp[0] = 0; // Clear temp
                    IF (indicator_id != 0)
                        delete_text(indicator_id);
                        indicator_id = 0;
                    END
                    // Clear options for next dialogue
                    showing_options = 0;
                    FROM i=0 TO 1;
                        IF (options_text_ids[i] != 0)
                            delete_text(options_text_ids[i]);
                            options_text_ids[i] = 0;
                        END
                    END
                ELSE
                    // Last dialogue - proceed to close
                    IF (DialogState.close_timer == 0)
                        DialogState.close_timer = ScreenConfig.fps / 2;
                    END
                    DialogState.close_timer--;

                    // Smooth zoom transition back to normal
                    IF (dialogue_zoom > 100)
                        dialogue_zoom = dialogue_zoom - 10;
                        IF (dialogue_zoom < 100)
                            dialogue_zoom = 100;
                        END
                    END

                    IF (DialogState.close_timer == 0)
                        DialogState.box_id = 0;
                        force_redraw = 1;

                        // Ensure zoom is fully reset
                        dialogue_zoom = 100;

                        IF (options_box_id != 0)
                            delete_draw(options_box_id);
                            options_box_id = 0;
                        END
                        delete_text(text_id);
                        delete_text(name_id);
                        IF (indicator_id != 0)
                            delete_text(indicator_id);
                        END
                        IF (showing_options)
                            FROM i=0 TO 1;
                                IF (options_text_ids[i] != 0)
                                    delete_text(options_text_ids[i]);
                                END
                            END
                        END
                        DialogState.closing = 0;
                        DialogState.process_id = 0;
                        show_dialogue_box = 0;
                        show_dialogue_cg = 0;
                        RETURN;
                    END
                END
            END
        END
        frame_counter++;

        FRAME;
    END
END

// Saves the current game state to save.dat file.
FUNCTION SaveGame()
PRIVATE
    file_handle;
    data_size;
    i;
BEGIN
    // Create save file
    file_handle = fopen("save.dat", "w");

    IF (file_handle == 0)
        RETURN(-1); // Error creating file
    END

    // Write PlayerData
    data_size = sizeof(PlayerData);
    fwrite(OFFSET PlayerData, data_size, file_handle);

    // Write PlayerStats
    data_size = sizeof(PlayerStats);
    fwrite(OFFSET PlayerStats, data_size, file_handle);

    // Write player_gold
    fwrite(OFFSET player_gold, 1, file_handle);

    // Write current_map
    fwrite(OFFSET current_map, 1, file_handle);

    // Write item_count
    fwrite(OFFSET item_count, 1, file_handle);

    // Write inventory
    data_size = sizeof(Inventory);
    fwrite(OFFSET Inventory, data_size, file_handle);

    // Write quest_states
    data_size = sizeof(quest_states);
    fwrite(OFFSET quest_states, data_size, file_handle);

    // Write cg_unlocked
    data_size = sizeof(cg_unlocked);
    fwrite(OFFSET cg_unlocked, data_size, file_handle);

    fclose(file_handle);
    RETURN(1); // Success
END

// Loads the game state from save.dat file.
FUNCTION LoadGame()
PRIVATE
    file_handle;
    data_size;
    i;
BEGIN
    // Try to open save file
    file_handle = fopen("save.dat", "r");

    IF (file_handle == 0)
        RETURN(-1); // File doesn't exist
    END

    // Read PlayerData
    data_size = sizeof(PlayerData);
    fread(OFFSET PlayerData, data_size, file_handle);

    // Read PlayerStats
    data_size = sizeof(PlayerStats);
    fread(OFFSET PlayerStats, data_size, file_handle);

    // Read player_gold
    fread(OFFSET player_gold, 1, file_handle);

    // Read current_map
    fread(OFFSET current_map, 1, file_handle);

    // Read item_count
    fread(OFFSET item_count, 1, file_handle);

    // Read inventory
    data_size = sizeof(Inventory);
    fread(OFFSET Inventory, data_size, file_handle);

    // Read quest_states
    data_size = sizeof(quest_states);
    fread(OFFSET quest_states, data_size, file_handle);

    // Read cg_unlocked
    data_size = sizeof(cg_unlocked);
    fread(OFFSET cg_unlocked, data_size, file_handle);

    fclose(file_handle);

    // Force map reload
    prev_map = -1;
    prev_offset_x = -9999;
    prev_offset_y = -9999;
    force_redraw = 1;

    // Change music to current map's song
    ChangeSong(MapData[current_map].map_song);

    RETURN(1); // Success
END

// Displays the pause/main menu screen.
PROCESS inventory_screen()
PRIVATE
    bg_id = 0, title_id = 0;
    INT selected = 0;
    INT i;
    INT input_timer = 0;
    INT open_timer = 0;
    INT exit_menu = 0;
    INT do_exit_game = 0;
    INT submenu_result = 0;
    INT in_submenu = 0;
    INT save_result = 0;
    INT load_result = 0;
    INT message_text_id = 0;
    INT msg_timer = 0;
BEGIN
    inventory_active = 1;
    clear_screen();

    open_timer = 20;

    show_menu_bg = 1;

    title_id = write(0, ScreenConfig.width / 2, 10, 4, "Pause Menu");

    LOOP
        IF (input_timer > 0)
            input_timer--;
        END
        IF (open_timer > 0)
            open_timer--;
        END

        // Clear previous menu options
        clear_menu(8);

        // Display save/load messages if any
        IF (msg_timer > 0)
            msg_timer--;
            IF (msg_timer == 0 AND message_text_id != 0)
                delete_text(message_text_id);
                message_text_id = 0;
            END
        END

        IF (in_submenu == 0)
            navigate_menu(OFFSET(selected), 8, OFFSET(input_timer));
        END
        IF (KEY(Controls.talk) AND in_submenu == 0)
            IF (selected == 0)
                // Stats
                in_submenu = 1;
                wait_key_release(Controls.talk);
                delete_text(title_id);
                FROM i=0 TO 7;
                    IF (MenuOption[i].text_id != 0)
                        delete_text(MenuOption[i].text_id);
                    END
                END
                submenu_finished = 0;
                stats_screen();
                // Wait for the submenu to finish completely
                WHILE (submenu_finished == 0)
                    FRAME;
                END
                clear_screen();
                title_id = write(0, ScreenConfig.width / 2, 10, 4, "Pause Menu");
                input_timer = 5;
                open_timer = 5;
                in_submenu = 0;
            ELSE
                IF (selected == 1)
                    // Quests
                    in_submenu = 1;
                    wait_key_release(Controls.talk);
                    delete_text(title_id);
                    FROM i=0 TO 7;
                        IF (MenuOption[i].text_id != 0)
                            delete_text(MenuOption[i].text_id);
                        END
                    END
                    submenu_finished = 0;
                    quests_screen();
                    // Wait for the submenu to finish completely
                    WHILE (submenu_finished == 0)
                        FRAME;
                    END
                    clear_screen();
                    title_id = write(0, ScreenConfig.width / 2, 10, 4, "Pause Menu");
                    input_timer = 5;
                    open_timer = 5;
                    in_submenu = 0;
                ELSE
                    IF (selected == 2)
                        // Items
                        wait_key_release(Controls.talk);
                        delete_text(title_id);
                        FROM i=0 TO 7;
                            IF (MenuOption[i].text_id != 0)
                                delete_text(MenuOption[i].text_id);
                            END
                        END
                        submenu_finished = 0;
                        items_screen();
                        // Wait for the submenu to finish completely
                        WHILE (submenu_finished == 0)
                            FRAME;
                        END
                        clear_screen();
                        title_id = write(0, ScreenConfig.width / 2, 10, 4, "Pause Menu");
                        input_timer = 20;
                        open_timer = 20;
                        in_submenu = 0;
                    ELSE
                        IF (selected == 3)
                            // CG Gallery
                            wait_key_release(Controls.talk);
                            delete_text(title_id);
                            FROM i=0 TO 7;
                                IF (MenuOption[i].text_id != 0)
                                    delete_text(MenuOption[i].text_id);
                                END
                            END
                            submenu_finished = 0;
                            cg_gallery_screen();
                            // Wait for the submenu to finish completely
                            WHILE (submenu_finished == 0)
                                FRAME;
                            END
                            clear_screen();
                            title_id = write(0, ScreenConfig.width / 2, 10, 4, "Pause Menu");
                            input_timer = 20;
                            open_timer = 20;
                            in_submenu = 0;
                        ELSE
                            IF (selected == 4)
                                // Save Game
                                wait_key_release(Controls.talk);
                                save_result = SaveGame();
                                IF (message_text_id != 0)
                                    delete_text(message_text_id);
                                END
                                IF (save_result == 1)
                                    message_text_id = write(0, ScreenConfig.width / 2, 180, 4, "Game saved successfully!");
                                ELSE
                                    message_text_id = write(0, ScreenConfig.width / 2, 180, 4, "Error saving game!");
                                END
                                msg_timer = ScreenConfig.fps * 2;
                                input_timer = 10;
                            ELSE
                                IF (selected == 5)
                                    // Load Game
                                    wait_key_release(Controls.talk);
                                    load_result = LoadGame();
                                    IF (message_text_id != 0)
                                        delete_text(message_text_id);
                                    END
                                    IF (load_result == 1)
                                        message_text_id = write(0, ScreenConfig.width / 2, 180, 4, "Game loaded successfully!");
                                        msg_timer = ScreenConfig.fps * 2;
                                        input_timer = 10;
                                    ELSE
                                        message_text_id = write(0, ScreenConfig.width / 2, 180, 4, "No save file found!");
                                        msg_timer = ScreenConfig.fps * 2;
                                        input_timer = 10;
                                    END
                                ELSE
                                    IF (selected == 6)
                                        // Back
                                        exit_menu = 1;
                                        wait_key_release(Controls.talk);
                                    ELSE
                                        // Exit Game (selected == 7)
                                        exit_menu = 1;
                                        do_exit_game = 1;
                                        wait_key_release(Controls.talk);
                                    END
                                END
                            END
                        END
                    END
                END
            END
        END
        IF (KEY(Controls.inventory) AND open_timer == 0)
            exit_menu = 1;
            wait_key_release(Controls.inventory);
        END

        IF (exit_menu)
            force_redraw = 1;
            BREAK;
        END

        // Draw menu options only if not in submenu
        IF (in_submenu == 0)
            IF (selected == 0)
                MenuOption[0].text = "> Stats";
            ELSE
                MenuOption[0].text = "  Stats";
            END
            IF (selected == 1)
                MenuOption[1].text = "> Quests";
            ELSE
                MenuOption[1].text = "  Quests";
            END
            IF (selected == 2)
                MenuOption[2].text = "> Items";
            ELSE
                MenuOption[2].text = "  Items";
            END
            IF (selected == 3)
                MenuOption[3].text = "> CG";
            ELSE
                MenuOption[3].text = "  CG";
            END
            IF (selected == 4)
                MenuOption[4].text = "> Save Game";
            ELSE
                MenuOption[4].text = "  Save Game";
            END
            IF (selected == 5)
                MenuOption[5].text = "> Load Game";
            ELSE
                MenuOption[5].text = "  Load Game";
            END
            IF (selected == 6)
                MenuOption[6].text = "> Back";
            ELSE
                MenuOption[6].text = "  Back";
            END
            IF (selected == 7)
                MenuOption[7].text = "> Exit Game";
            ELSE
                MenuOption[7].text = "  Exit Game";
            END

            render_menu(8, ScreenConfig.width / 2, 30, 15);
        END

        FRAME;
    END

    delete_text(title_id);
    IF (message_text_id != 0)
        delete_text(message_text_id);
    END
    clear_menu(8);
    show_menu_bg = 0;
    inventory_active = 0;

    IF (do_exit_game)
        unload_song(song_id);
        EXIT("Goodbye", 0);
    END
END

// Displays the quests screen.
PROCESS quests_screen()
PRIVATE
    title_id = 0;
    INT menu_count = 0;
    INT selected = 0;
    INT i, j;
    INT input_timer = 0;
    INT open_timer = 0;
    INT exit_screen = 0;
    STRING quest_status;
    INT active_quests = 0;
BEGIN
    clear_screen();

    open_timer = 10;

    title_id = write(0, ScreenConfig.width / 2, 10, 4, "Quests");

    // Count active/completed quests
    FOR (i = 0; i < 3; i++)
        FOR (j = 0; j < MapData[i].npc_count; j++)
            IF (MapData[i].NPCData[j].has_quest == 1)
                IF (quest_states[MapData[i].NPCData[j].npc_id] != QUEST_NOT_STARTED)
                    active_quests++;
                END
            END
        END
    END

    menu_count = active_quests + 1; // +1 for Back option

    // Wait for key release
    wait_for_key_release();

    LOOP
        IF (input_timer > 0)
            input_timer--;
        END
        IF (open_timer > 0)
            open_timer--;
        END

        // Clear previous menu options
        FROM i=0 TO 11;
            IF (MenuOption[i].text_id != 0)
                delete_text(MenuOption[i].text_id);
                MenuOption[i].text_id = 0;
            END
            IF (MenuOption[i].desc_id != 0)
                delete_text(MenuOption[i].desc_id);
                MenuOption[i].desc_id = 0;
            END
        END

        navigate_menu(OFFSET(selected), menu_count, OFFSET(input_timer));
        IF (KEY(Controls.talk))
            IF (selected == active_quests)
                exit_screen = 1;
                wait_key_release(Controls.talk);
            END
        END
        IF (KEY(Controls.inventory) AND open_timer == 0)
            exit_screen = 1;
            wait_key_release(Controls.inventory);
        END

        IF (exit_screen)
            BREAK;
        END

        // Draw quest list
        menu_count = 0;
        FOR (i = 0; i < 3; i++)
            FOR (j = 0; j < MapData[i].npc_count; j++)
                IF (MapData[i].NPCData[j].has_quest == 1)
                    IF (quest_states[MapData[i].NPCData[j].npc_id] == QUEST_ACTIVE)
                        quest_status = " [Active]";
                        IF (menu_count == selected)
                            MenuOption[menu_count].text = "> " + MapData[i].NPCData[j].name + ": " + MapData[i].NPCData[j].quest_dialogues[0].dialogue;
                        ELSE
                            MenuOption[menu_count].text = "  " + MapData[i].NPCData[j].name + ": " + MapData[i].NPCData[j].quest_dialogues[0].dialogue;
                        END
                        MenuOption[menu_count].text_id = write(0, 30, 30 + menu_count * 20, 0, MenuOption[menu_count].text);
                        MenuOption[menu_count].desc_id = write(0, 30, 40 + menu_count * 20, 0, quest_status);
                        menu_count++;
                    ELSE
                        IF (quest_states[MapData[i].NPCData[j].npc_id] == QUEST_COMPLETED)
                            quest_status = " [Completed]";
                            IF (menu_count == selected)
                                MenuOption[menu_count].text = "> " + MapData[i].NPCData[j].name + ": " + MapData[i].NPCData[j].quest_dialogues[0].dialogue;
                            ELSE
                                MenuOption[menu_count].text = "  " + MapData[i].NPCData[j].name + ": " + MapData[i].NPCData[j].quest_dialogues[0].dialogue;
                            END
                            MenuOption[menu_count].text_id = write(0, 30, 30 + menu_count * 20, 0, MenuOption[menu_count].text);
                            MenuOption[menu_count].desc_id = write(0, 30, 40 + menu_count * 20, 0, quest_status);
                            menu_count++;
                        END
                    END
                END
            END
        END

        // Draw Back option
        IF (menu_count == selected)
            MenuOption[menu_count].text = "> Back";
        ELSE
            MenuOption[menu_count].text = "  Back";
        END
        MenuOption[menu_count].text_id = write(0, ScreenConfig.width / 2, 30 + menu_count * 20, 4, MenuOption[menu_count].text);

        menu_count++;

        FRAME;
    END

    delete_text(title_id);
    FROM i=0 TO 11;
        IF (MenuOption[i].text_id != 0)
            delete_text(MenuOption[i].text_id);
        END
        IF (MenuOption[i].desc_id != 0)
            delete_text(MenuOption[i].desc_id);
        END
    END
    submenu_finished = 1;
END

// Displays the items screen.
PROCESS items_screen()
PRIVATE
    title_id = 0;
    INT menu_count;
    INT selected = 0;
    INT i;
    STRING current_item;
    INT num_items_to_show;
    INT input_timer = 0;
    INT open_timer = 0;
    INT exit_screen = 0;
    STRING qty_str;
BEGIN
    clear_screen();

    open_timer = 10;
    num_items_to_show = item_count;
    IF (num_items_to_show > 8)
        num_items_to_show = 8;
    END
    menu_count = item_count + 1; // +1 for Back option

    title_id = write(0, ScreenConfig.width / 2, 10, 4, "Items");

    // Wait for key release
    wait_for_key_release();

    LOOP
        IF (input_timer > 0)
            input_timer--;
        END
        IF (open_timer > 0)
            open_timer--;
        END

        // Clear previous menu options
        clear_menu(12);

        navigate_menu(OFFSET(selected), menu_count, OFFSET(input_timer));
        IF (KEY(Controls.talk))
            IF (selected == item_count)
                exit_screen = 1;
                wait_key_release(Controls.talk);
            END
        END
        IF (KEY(Controls.inventory) AND open_timer == 0)
            exit_screen = 1;
            wait_key_release(Controls.inventory);
        END

        IF (exit_screen)
            BREAK;
        END

        // Draw item list
        i = 0;
        WHILE (i < item_count)
            qty_str = itoa(inventory[i].quantity);
            current_item = inventory[i].item + " x" + qty_str;
            IF (i == selected)
                MenuOption[i].text = "> " + current_item;
            ELSE
                MenuOption[i].text = "  " + current_item;
            END
            MenuOption[i].text_id = write(0, 30, 30 + i * 20, 0, MenuOption[i].text);
            MenuOption[i].desc_id = write(0, 200, 30 + i * 20, 0, inventory[i].description);
            i++;
        END

        // Draw Back option
        IF (item_count == selected)
            MenuOption[item_count].text = "> Back";
        ELSE
            MenuOption[item_count].text = "  Back";
        END
        MenuOption[item_count].text_id = write(0, ScreenConfig.width / 2, 30 + item_count * 20, 4, MenuOption[item_count].text);

        FRAME;
    END

    delete_text(title_id);
    FROM i=0 TO 11;
        IF (MenuOption[i].text_id != 0)
            delete_text(MenuOption[i].text_id);
        END
        IF (MenuOption[i].desc_id != 0)
            delete_text(MenuOption[i].desc_id);
        END
    END
    submenu_finished = 1;
END


// Displays the CG Gallery screen.
PROCESS cg_gallery_screen()
PRIVATE
    title_id = 0;
    INT menu_count;
    INT selected = 0;
    INT i;
    INT input_timer = 0;
    INT open_timer = 0;
    INT exit_screen = 0;
    INT viewing_cg = 0; // Flag when viewing a CG
    INT current_cg = 0; // Current CG being viewed
    INT cg_text_id = 0;
BEGIN
    clear_screen();

    open_timer = 10;
    menu_count = cg_count + 1; // CGs + Back option

    title_id = write(0, ScreenConfig.width / 2, 10, 4, "CG Gallery");

    // Wait for key release
    wait_for_key_release();

    LOOP
        IF (input_timer > 0)
            input_timer--;
        END
        IF (open_timer > 0)
            open_timer--;
        END

        IF (viewing_cg == 0)
            // Gallery menu mode
            // Clear previous menu options
            clear_menu(11);

            navigate_menu(OFFSET(selected), menu_count, OFFSET(input_timer));
            IF (KEY(Controls.talk))
                IF (selected < cg_count)
                    // Try to view CG if unlocked
                    IF (cg_unlocked[selected + 1] == 1)
                        fade_off();
                        delete_text(all_text);
                        clear_screen();
                        viewing_cg = 1;
                        current_cg = selected + 1;
                        title_id = 0;
                        FROM i=0 TO 10;
                            MenuOption[i].text_id = 0;
                        END
                        fade_on();
                        wait_key_release(Controls.talk);
                    END
                ELSE
                    // Back option
                    exit_screen = 1;
                    wait_key_release(Controls.talk);
                END
            END
            IF (KEY(Controls.inventory) AND open_timer == 0)
                exit_screen = 1;
                wait_key_release(Controls.inventory);
            END

            IF (exit_screen)
                BREAK;
            END

            // Draw CG list
            i = 0;
            WHILE (i < cg_count)
                IF (cg_unlocked[i + 1] == 1)
                    // CG is unlocked
                    IF (i == selected)
                        MenuOption[i].text = "> CG " + itoa(i + 1);
                    ELSE
                        MenuOption[i].text = "  CG " + itoa(i + 1);
                    END
                ELSE
                    // CG is locked
                    IF (i == selected)
                        MenuOption[i].text = "> ???";
                    ELSE
                        MenuOption[i].text = "  ???";
                    END
                END
                MenuOption[i].text_id = write(0, ScreenConfig.width / 2, 30 + i * 20, 4, MenuOption[i].text);
                i++;
            END

            // Draw Back option
            IF (cg_count == selected)
                MenuOption[cg_count].text = "> Back";
            ELSE
                MenuOption[cg_count].text = "  Back";
            END
            MenuOption[cg_count].text_id = write(0, ScreenConfig.width / 2, 30 + cg_count * 20, 4, MenuOption[cg_count].text);
        ELSE
            // CG viewing mode
            clear_screen();
            delete_text(all_text); // Delete all texts every frame to ensure menu doesn't show

            // Update CG display variable
            show_gallery_cg = current_cg;

            // Show instructions
            cg_text_id = write(0, ScreenConfig.width / 2, ScreenConfig.height - 20, 4, "Press ENTER to close");

            // Check for exit
            IF (KEY(Controls.talk))
                fade_off();
                delete_text(all_text);
                cg_text_id = 0;
                viewing_cg = 0;
                current_cg = 0;
                show_gallery_cg = 0;
                clear_screen();
                title_id = write(0, ScreenConfig.width / 2, 10, 4, "CG Gallery");
                fade_on();
                wait_key_release(Controls.talk);
            END
            IF (KEY(Controls.inventory))
                fade_off();
                delete_text(all_text);
                cg_text_id = 0;
                viewing_cg = 0;
                current_cg = 0;
                show_gallery_cg = 0;
                exit_screen = 1;
                wait_key_release(Controls.inventory);
            END
        END

        FRAME;
    END

    delete_text(title_id);
    IF (cg_text_id != 0)
        delete_text(cg_text_id);
    END
    FROM i=0 TO 10;
        IF (MenuOption[i].text_id != 0)
            delete_text(MenuOption[i].text_id);
        END
    END
    submenu_finished = 1;
END

// Displays the stats screen.
PROCESS stats_screen()
PRIVATE
    title_id = 0;
    STRUCT StatText[8]
        STRING label;
        INT text_id;
    END
    INT i;
    INT input_timer = 0;
    INT open_timer = 0;
    INT exit_screen = 0;
    STRING value_str;
BEGIN
    clear_screen();

    open_timer = 10;

    title_id = write(0, ScreenConfig.width / 2, 10, 4, "Character Stats");

    // Wait for key release
    wait_for_key_release();

    LOOP
        IF (input_timer > 0)
            input_timer--;
        END
        IF (open_timer > 0)
            open_timer--;
        END

        // Clear previous stat texts
        FROM i=0 TO 7;
            IF (StatText[i].text_id != 0)
                delete_text(StatText[i].text_id);
                StatText[i].text_id = 0;
            END
        END

        IF (KEY(Controls.talk))
            exit_screen = 1;
            wait_key_release(Controls.talk);
        END
        IF (KEY(Controls.inventory) AND open_timer == 0)
            exit_screen = 1;
            wait_key_release(Controls.inventory);
        END

        IF (exit_screen)
            BREAK;
        END

        // Display stats
        StatText[0].label = "Name: " + PlayerStats.name;
        StatText[0].text_id = write(0, 30, 40, 0, StatText[0].label);

        value_str = itoa(PlayerStats.current_hp) + " / " + itoa(PlayerStats.max_hp);
        StatText[1].label = "HP: " + value_str;
        StatText[1].text_id = write(0, 30, 60, 0, StatText[1].label);

        value_str = itoa(PlayerStats.current_mp) + " / " + itoa(PlayerStats.max_mp);
        StatText[2].label = "MP: " + value_str;
        StatText[2].text_id = write(0, 30, 80, 0, StatText[2].label);

        StatText[3].label = "Attack: " + itoa(PlayerStats.attack);
        StatText[3].text_id = write(0, 30, 100, 0, StatText[3].label);

        StatText[4].label = "Defense: " + itoa(PlayerStats.defense);
        StatText[4].text_id = write(0, 30, 120, 0, StatText[4].label);

        StatText[5].label = "Gold: " + itoa(player_gold);
        StatText[5].text_id = write(0, 30, 140, 0, StatText[5].label);

        StatText[6].label = "Press ENTER to close";
        StatText[6].text_id = write(0, ScreenConfig.width / 2, 170, 4, StatText[6].label);

        FRAME;
    END

    delete_text(title_id);
    FROM i=0 TO 7;
        IF (StatText[i].text_id != 0)
            delete_text(StatText[i].text_id);
        END
    END
    submenu_finished = 1;
END

// Displays the battle screen with turn-based combat.
PROCESS battle_screen()
PRIVATE
    INT num_enemies;
    INT selected_action = 0;
    INT i, j;
    INT input_timer = 0;
    INT battle_active = 1;
    INT player_turn = 1;
    INT message_text_id = 0;
    INT msg_timer = 0;
    INT msg_id = 0;
    INT hp_mp_id = 0; // ID for HP/MP display
    STRUCT ActionText[4]
        STRING text;
        INT text_id;
    END
    STRUCT EnemyText[3]
        STRING text;
        INT text_id;
    END
    INT damage;
    INT enemy_alive_count;
    INT enemy_action;
    INT all_enemies_dead;
    INT player_dead;
    INT found;
    INT reward_gold_total = 0;
    STRING battle_msg[200];
    STRING hp_mp_msg[50];
    INT battle_msg_id = 0;
    INT selecting_magic = 0; // 1 = selecting magic
    INT selected_magic = 0; // 0-2 = spells, 3 = Back
    INT casting_spell = -1; // -1 = none, 0-2 = spell being cast
    INT any_dying = 0;
    INT items_gained = 0;
    INT mp_cost = 0;
BEGIN
    // Randomize number of enemies (1-3 slimes)
    num_enemies = rand(1, 3);

    // Initialize enemies
    i = 0;
    WHILE (i < num_enemies)
        Enemies[i].monster_id = 0; // Slime
        Enemies[i].max_hp = MonsterList[0].max_hp;
        Enemies[i].current_hp = MonsterList[0].max_hp;
        Enemies[i].alive = 1;
        Enemies[i].dying = 0;
        Enemies[i].dying_timer = 0;
        Enemies[i].size = 100;
        i++;
    END

    // Draw dark overlay (black semi-transparent rectangle covering map area, not dialogue box)

    // Display battle start message
    IF (num_enemies == 1)
        battle_msg = "A " + MonsterList[0].name + " appeared!";
    ELSE
        battle_msg = itoa(num_enemies);
        battle_msg = battle_msg + " " + MonsterList[0].name + "s appeared!";
    END
    battle_msg_id = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);

    // Start battle song
    ChangeSong(MapData[current_map].battle_song);

    show_battle_box = 1;

    // Wait for key release and show start message
    i = 0;
    WHILE (i < seconds_to_frames(2) OR KEY(Controls.talk) OR KEY(Controls.inventory))
        FRAME;
        i++;
    END

    delete_text(battle_msg_id);
    battle_msg_id = 0;

    after_battle_start = 1;

    LOOP
        // Force map redraw without player/NPCs (they check in_battle flag)
        force_redraw = 1;

        IF (input_timer > 0)
            input_timer--;
        END

        handle_battle_animations(num_enemies);

        // Clear previous texts
        FROM i=0 TO 3;
            IF (ActionText[i].text_id != 0)
                delete_text(ActionText[i].text_id);
                ActionText[i].text_id = 0;
            END
            IF (EnemyText[i].text_id != 0)
                delete_text(EnemyText[i].text_id);
                EnemyText[i].text_id = 0;
            END
        END

        handle_victory(num_enemies, OFFSET(battle_active), OFFSET(message_text_id), OFFSET(msg_timer), battle_msg);

        // Only process turns when msg_timer is 0 and battle is still active
        IF (msg_timer == 0 AND battle_active == 1)
            IF (player_turn)
                IF (selecting_target == 0 AND selecting_magic == 0)
                    // Player's turn - Show "Your turn" message and menu
                    IF (msg_id != 0)
                        delete_text(msg_id);
                        msg_id = 0;
                    END
                    msg_id = write(0, 50, 130, 0, "Your turn! Choose action:");

                        // Show action menu
                        IF (selected_action == 0)
                            ActionText[0].text = "> Attack";
                        ELSE
                            ActionText[0].text = "  Attack";
                        END
                        IF (selected_action == 1)
                            ActionText[1].text = "> Magic";
                        ELSE
                            ActionText[1].text = "  Magic";
                        END
                        IF (selected_action == 2)
                            ActionText[2].text = "> Run";
                        ELSE
                            ActionText[2].text = "  Run";
                        END

                        ActionText[0].text_id = write(0, 30, ScreenConfig.height - 40, 0, ActionText[0].text);
                        ActionText[1].text_id = write(0, 30, ScreenConfig.height - 30, 0, ActionText[1].text);
                        ActionText[2].text_id = write(0, 30, ScreenConfig.height - 20, 0, ActionText[2].text);

                        // Navigation
                        navigate_menu(OFFSET(selected_action), 3, OFFSET(input_timer));

                        // Action selection
                        IF (KEY(Controls.talk))
                            // Delete menu message first
                            IF (msg_id != 0)
                                delete_text(msg_id);
                            END

                            IF (selected_action == 0)
                                // Attack - select target
                                selecting_target = 1;
                                selected_target = 0;
                                // Find first alive
                                i = 0;
                                WHILE (i < num_enemies)
                                    IF (Enemies[i].alive == 1)
                                        selected_target = i;
                                        BREAK;
                                    END
                                    i++;
                                END
                                // Clear action texts
                                FROM i=0 TO 2;
                                    IF (ActionText[i].text_id != 0)
                                        delete_text(ActionText[i].text_id);
                                        ActionText[i].text_id = 0;
                                    END
                                END
                                // Clear enemy texts
                                FROM i=0 TO 2;
                                    IF (EnemyText[i].text_id != 0)
                                        delete_text(EnemyText[i].text_id);
                                        EnemyText[i].text_id = 0;
                                    END
                                END
                                input_timer = 10;
                                wait_key_release(Controls.talk);
                            ELSE
                                IF (selected_action == 1)
                                // Magic - show magic menu
                                selecting_magic = 1;
                                selected_magic = 0;
                                // Clear action texts
                                FROM i=0 TO 2;
                                    IF (ActionText[i].text_id != 0)
                                        delete_text(ActionText[i].text_id);
                                        ActionText[i].text_id = 0;
                                    END
                                END
                                // Clear enemy texts
                                FROM i=0 TO 2;
                                    IF (EnemyText[i].text_id != 0)
                                        delete_text(EnemyText[i].text_id);
                                        EnemyText[i].text_id = 0;
                                    END
                                END
                                input_timer = 10;
                                wait_key_release(Controls.talk);
                                ELSE
                                    // Run away
                                    IF (msg_id != 0)
                                        delete_text(msg_id);
                                    END
                                    msg_id = write(0, 50, 170, 0, "Escaped!");
                                    msg_timer = seconds_to_frames(2);
                                    battle_active = 0;
                                    input_timer = 10;
                                    wait_key_release(Controls.talk);
                                    // Clear action texts
                                    FROM i=0 TO 3;
                                        IF (ActionText[i].text_id != 0)
                                            delete_text(ActionText[i].text_id);
                                            ActionText[i].text_id = 0;
                                        END
                                    END
                                    // Wait for message to finish
                                    WHILE (msg_timer > 0)
                                        // Draw enemies during wait
                                        j = 0;
                                        WHILE (j < num_enemies)
                                            IF (Enemies[j].alive == 1)
                                                xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                                            END
                                            j++;
                                        END
                                        FRAME;
                                        msg_timer--;
                                    END
                                END
                            END
                        END
                ELSE
                    IF (selecting_target == 1)
                        // Target selection - show enemy list
                        msg_id = write(0, ScreenConfig.width / 2, 155, 4, "Choose target:");
                        i = 0;
                        WHILE (i < num_enemies)
                            IF (Enemies[i].alive == 1)
                                IF (i == selected_target)
                                    EnemyText[i].text = "> ";
                                ELSE
                                    EnemyText[i].text = "  ";
                                END
                                EnemyText[i].text = EnemyText[i].text + MonsterList[Enemies[i].monster_id].name;
                                EnemyText[i].text = EnemyText[i].text + " HP:";
                                EnemyText[i].text = EnemyText[i].text + itoa(Enemies[i].current_hp);
                                EnemyText[i].text_id = write(0, ScreenConfig.width / 2, 170 + i * 10, 4, EnemyText[i].text);
                            END
                            i++;
                        END
                        // Navigation
                        IF (KEY(Controls.up))
                            selected_target = (selected_target - 1 + num_enemies) % num_enemies;
                            WHILE (Enemies[selected_target].alive == 0)
                                selected_target = (selected_target - 1 + num_enemies) % num_enemies;
                            END
                            wait_key_release(Controls.up);
                        END
                        IF (KEY(Controls.down))
                            selected_target = (selected_target + 1) % num_enemies;
                            WHILE (Enemies[selected_target].alive == 0)
                                selected_target = (selected_target + 1) % num_enemies;
                            END
                            wait_key_release(Controls.down);
                        END
                        IF (KEY(Controls.talk))
                            // Confirm attack or spell
                            selecting_target = 0;
                            wait_key_release(Controls.talk);
                            // Clear enemy texts
                            FROM i=0 TO 2;
                                IF (EnemyText[i].text_id != 0)
                                    delete_text(EnemyText[i].text_id);
                                    EnemyText[i].text_id = 0;
                                END
                            END
                            IF (casting_spell == -1)
                                // Physical attack
                                damage = PlayerStats.attack - MonsterList[Enemies[selected_target].monster_id].defense;
                                IF (damage < 1)
                                    damage = 1;
                                END
                                Enemies[selected_target].current_hp = Enemies[selected_target].current_hp - damage;
                                IF (Enemies[selected_target].current_hp <= 0)
                                    Enemies[selected_target].current_hp = 0;
                                    Enemies[selected_target].dying = 1;
                                    Enemies[selected_target].dying_timer = seconds_to_frames(1);
                                    battle_msg = PlayerStats.name + " attacks! " + MonsterList[Enemies[selected_target].monster_id].name + " defeated!";
                                ELSE
                                    battle_msg = PlayerStats.name + " attacks!";
                                END
                            ELSE
                                // Spell attack
                                IF (casting_spell == 0) // White Nova
                                    damage = HeroList[0].mag * 2 - MonsterList[Enemies[selected_target].monster_id].defense;
                                ELSE // Ruination Flame
                                    damage = HeroList[0].mag * 4 - MonsterList[Enemies[selected_target].monster_id].defense;
                                END
                                IF (damage < 1)
                                    damage = 1;
                                END
                                Enemies[selected_target].current_hp = Enemies[selected_target].current_hp - damage;
                                IF (Enemies[selected_target].current_hp <= 0)
                                    Enemies[selected_target].current_hp = 0;
                                    Enemies[selected_target].dying = 1;
                                    Enemies[selected_target].dying_timer = seconds_to_frames(1);
                                    battle_msg = PlayerStats.name + " casts " + HeroList[0].spells[casting_spell].name + "! " + MonsterList[Enemies[selected_target].monster_id].name + " defeated!";
                                ELSE
                                    battle_msg = PlayerStats.name + " casts " + HeroList[0].spells[casting_spell].name + "!";
                                END
                                casting_spell = -1;
                            END
                            IF (msg_id != 0)
                                delete_text(msg_id);
                            END
                            msg_id = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);
                            msg_timer = seconds_to_frames(2);
                            player_turn = 0;
                            input_timer = 10;
                            // Wait for message to finish
                            WHILE (msg_timer > 0)
                                // Draw enemies during wait
                                j = 0;
                                WHILE (j < num_enemies)
                                    IF (Enemies[j].alive == 1)
                                        xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                                    END
                                    j++;
                                END
                                FRAME;
                                msg_timer--;
                            END
                        END
                    END
                    IF (selecting_magic == 1)
                        // Magic selection - show magic menu
                        msg_id = write(0, ScreenConfig.width / 2, 155, 4, "Choose magic:");
                        i = 0;
                        WHILE (i < HeroList[0].spell_count)
                            IF (selected_magic == i)
                                ActionText[i].text = "> " + HeroList[0].spells[i].name;
                            ELSE
                                ActionText[i].text = "  " + HeroList[0].spells[i].name;
                            END
                            ActionText[i].text_id = write(0, ScreenConfig.width / 2, 165 + i * 10, 4, ActionText[i].text);
                            i++;
                        END
                        IF (selected_magic == HeroList[0].spell_count)
                            ActionText[HeroList[0].spell_count].text = "> Back";
                        ELSE
                            ActionText[HeroList[0].spell_count].text = "  Back";
                        END
                        ActionText[HeroList[0].spell_count].text_id = write(0, ScreenConfig.width / 2, 165 + HeroList[0].spell_count * 10, 4, ActionText[HeroList[0].spell_count].text);
                        // Navigation
                        IF (KEY(Controls.up))
                            selected_magic = (selected_magic - 1 + HeroList[0].spell_count + 1) % (HeroList[0].spell_count + 1);
                            wait_key_release(Controls.up);
                        END
                        IF (KEY(Controls.down))
                            selected_magic = (selected_magic + 1) % (HeroList[0].spell_count + 1);
                            wait_key_release(Controls.down);
                        END
                        IF (KEY(Controls.talk))
                            IF (selected_magic < HeroList[0].spell_count)
                                // Cast spell
                                selecting_magic = 0;
                                wait_key_release(Controls.talk);
                                // Clear texts
                                IF (msg_id != 0)
                                    delete_text(msg_id);
                                END
                                i = 0;
                                WHILE (i <= HeroList[0].spell_count)
                                    IF (ActionText[i].text_id != 0)
                                        delete_text(ActionText[i].text_id);
                                        ActionText[i].text_id = 0;
                                    END
                                    i++;
                                END
                                // Check MP and cast
                                mp_cost = 20 + selected_magic * 10; // 20, 30, 40
                                IF (PlayerStats.current_mp >= mp_cost)
                                    PlayerStats.current_mp = PlayerStats.current_mp - mp_cost;
                                IF (selected_magic == 0) // White Nova - single target high damage
                                        casting_spell = 0;
                                        selecting_target = 1;
                                        selected_target = 0;
                                        // Find first alive
                                        i = 0;
                                        WHILE (i < num_enemies)
                                            IF (Enemies[i].alive == 1)
                                                selected_target = i;
                                                BREAK;
                                            END
                                            i++;
                                        END
                                        // Will handle in selecting_target
                                    ELSE
                                        IF (selected_magic == 1) // Apocalypse Abyss - all targets
                                            i = 0;
                                            WHILE (i < num_enemies)
                                                IF (Enemies[i].alive == 1)
                                                    damage = PlayerStats.attack * 3 - MonsterList[Enemies[i].monster_id].defense;
                                                    IF (damage < 1)
                                                        damage = 1;
                                                    END
                                                    Enemies[i].current_hp = Enemies[i].current_hp - damage;
                                                    IF (Enemies[i].current_hp <= 0)
                                                        Enemies[i].current_hp = 0;
                                                        Enemies[i].dying = 1;
                                                        Enemies[i].dying_timer = seconds_to_frames(1);
                                                    END
                                                END
                                                i++;
                                            END
                                            battle_msg = PlayerStats.name + " casts " + HeroList[0].spells[selected_magic].name + "!";
                                            msg_id = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);
                                            msg_timer = seconds_to_frames(2);
                                            player_turn = 0;
                                            input_timer = 10;
                                        ELSE // Ruination Flame - single target very high damage
                                            casting_spell = 2;
                                            selecting_target = 1;
                                            selected_target = 0;
                                            // Find first alive
                                            i = 0;
                                            WHILE (i < num_enemies)
                                                IF (Enemies[i].alive == 1)
                                                    selected_target = i;
                                                    BREAK;
                                                END
                                                i++;
                                            END
                                            // Will handle in selecting_target
                                        END
                                    END
                                ELSE
                                    battle_msg = "Not enough MP!";
                                    msg_id = write(0, ScreenConfig.width / 2, 175, 4, battle_msg);
                                    msg_timer = seconds_to_frames(2);
                                    input_timer = 10;
                                    // Wait for message to finish
                                    WHILE (msg_timer > 0)
                                        // Draw enemies during wait
                                        j = 0;
                                        WHILE (j < num_enemies)
                                            IF (Enemies[j].alive == 1)
                                                xput(monsters_fpg_id, MonsterList[Enemies[j].monster_id].sprite_graph_id, 80 + j * 80, 60, 0, 100, 0, 0);
                                            END
                                            j++;
                                        END
                                        FRAME;
                                        msg_timer--;
                                    END
                                    // Clear texts
                                    FROM i=0 TO 1;
                                        IF (ActionText[i].text_id != 0)
                                            delete_text(ActionText[i].text_id);
                                            ActionText[i].text_id = 0;
                                        END
                                    END
                                END
                            ELSE
                                // Back
                                selecting_magic = 0;
                                wait_key_release(Controls.talk);
                                // Clear texts
                                IF (msg_id != 0)
                                    delete_text(msg_id);
                                END
                                i = 0;
                                WHILE (i <= HeroList[0].spell_count)
                                    IF (ActionText[i].text_id != 0)
                                        delete_text(ActionText[i].text_id);
                                        ActionText[i].text_id = 0;
                                    END
                                    i++;
                                END
                                input_timer = 10;
                            END
                        END
                    END
                END
            END
        END

        handle_turns(num_enemies, OFFSET(player_turn), OFFSET(battle_active), OFFSET(message_text_id), OFFSET(msg_timer), battle_msg, OFFSET(input_timer));

        // Display player HP/MP
        IF (hp_mp_id != 0)
            delete_text(hp_mp_id);
        END
        hp_mp_msg = "HP:";
        hp_mp_msg = hp_mp_msg + itoa(PlayerStats.current_hp);
        hp_mp_msg = hp_mp_msg + "/";
        hp_mp_msg = hp_mp_msg + itoa(PlayerStats.max_hp);
        hp_mp_msg = hp_mp_msg + " MP:";
        hp_mp_msg = hp_mp_msg + itoa(PlayerStats.current_mp);
        hp_mp_msg = hp_mp_msg + "/";
        hp_mp_msg = hp_mp_msg + itoa(PlayerStats.max_mp);
        hp_mp_id = write(0, 100, 10, 0, hp_mp_msg);

        // Check if battle is over
        IF (battle_active == 0 AND msg_timer == 0)
            // Clean up
            IF (msg_id != 0)
                delete_text(msg_id);
            END
            IF (hp_mp_id != 0)
                delete_text(hp_mp_id);
            END
            i = 0;
            FROM i=0 TO 2;
                IF (ActionText[i].text_id != 0)
                    delete_text(ActionText[i].text_id);
                END
                IF (EnemyText[i].text_id != 0)
                    delete_text(EnemyText[i].text_id);
                END
            END

            // Clean up battle message
            IF (battle_msg_id != 0)
                delete_text(battle_msg_id);
            END

            // Reset battle flags and force map redraw
            in_battle = 0;
            battle_process_id = 0;
            show_battle_box = 0;
            force_redraw = 1;
            ChangeSong(MapData[current_map].map_song);
            RETURN;
        END

        FRAME;
    END
END

// Generic function to handle menu navigation
FUNCTION navigate_menu(INT selected_offset, INT menu_count, INT input_timer_offset)
BEGIN
    IF (KEY(Controls.up))
        *selected_offset = (*selected_offset - 1 + menu_count) % menu_count;
        wait_key_release(Controls.up);
    END
    IF (KEY(Controls.down))
        *selected_offset = (*selected_offset + 1) % menu_count;
        wait_key_release(Controls.down);
    END
END

// Generic function to render menu options
FUNCTION render_menu(INT count, INT start_x, INT start_y, INT spacing)
PRIVATE
    i;
BEGIN
    i = 0;
    WHILE (i < count)
        MenuOption[i].text_id = write(0, start_x, start_y + i * spacing, 4, MenuOption[i].text);
        i++;
    END
END

// Generic function to clear menu text
FUNCTION clear_menu(INT count)
PRIVATE
    i;
BEGIN
    i = 0;
    WHILE (i < count)
        IF (MenuOption[i].text_id != 0)
            delete_text(MenuOption[i].text_id);
            MenuOption[i].text_id = 0;
        END
        IF (MenuOption[i].desc_id != 0)
            delete_text(MenuOption[i].desc_id);
            MenuOption[i].desc_id = 0;
        END
        i++;
    END
END
