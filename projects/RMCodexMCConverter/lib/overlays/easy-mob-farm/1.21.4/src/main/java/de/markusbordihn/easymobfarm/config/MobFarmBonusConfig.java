package de.markusbordihn.easymobfarm.config;

import de.markusbordihn.easymobfarm.data.mobfarm.MobFarmType;
import java.io.File;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.util.Random;
import java.util.Map.Entry;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.Identifier;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.ItemLike;

public class MobFarmBonusConfig extends Config {
   public static final String CONFIG_FILE_NAME = "mob_farm_bonus.cfg";
   public static final String CONFIG_FILE_HEADER = " Mob Farm Bonus Configuration\n\n This configuration file allows you to define the bonus drops for the Mob Farms.\n\n Configuration Format:\n --------------------\n <mob_farm_name>::<tier_level>::<entity_type> = <item_name>::<amount>::<chance 1 of x>\n\n Available Mob Farm Types:\n ------------------------\n - animal_plains_farm: For animals like cows, sheep, chickens, pigs\n - bee_hive_farm: For bees and honey production\n - desert_farm: For desert mobs like husks, rabbits, camels\n - iron_golem_farm: For iron golems and poppy drops\n - jungle_farm: For jungle mobs like parrots, pandas, ocelots\n - monster_plains_cave_farm: For common monsters like zombies, skeletons, spiders\n - nether_fortress_farm: For nether mobs like blazes, magma cubes, wither skeletons\n - ocean_farm: For ocean mobs like cod, salmon, squid, guardians\n - swamp_farm: For swamp mobs like frogs, slimes, witches\n\n Tier Levels (better farms = better bonus chances):\n -------------------------------------------------\n - 0: Basic tier (lowest bonus chance)\n - 1: Improved tier (better bonus chance)\n - 2: Advanced tier (good bonus chance)\n - 3: Elite tier (highest bonus chance)\n\n Configuration Examples:\n ----------------------\n Basic bee farm with 1 in 20 chance for honeycomb:\n   bee_hive_farm::0::minecraft:bee = minecraft:honeycomb::1::20\n\n Elite bee farm with 1 in 5 chance for honeycomb:\n   bee_hive_farm::3::minecraft:bee = minecraft:honeycomb::1::5\n\n Iron golem farm with bonus iron ingots:\n   iron_golem_farm::2::minecraft:iron_golem = minecraft:iron_ingot::2::8\n\n Multiple bonus items for the same mob (different lines):\n   ocean_farm::1::minecraft:cod = minecraft:cod::1::10\n   ocean_farm::1::minecraft:cod = minecraft:bone_meal::1::25\n\n Important Notes:\n ---------------\n - Lower chance numbers = higher drop probability (1 = always, 100 = 1% chance)\n - To disable a bonus drop, set the amount to 0\n - Each mob farm type targets specific biome-appropriate mobs\n - Higher tier farms have better default bonus chances\n\n";
   public static final String LOG_PREFIX = "[MobFarmBonusConfig]";
   private static final Random random = new Random();
   private static final HashMap<String, HashMap<Integer, ItemStack>> mobFarmBonusMap = new HashMap<>();
   private static final HashMap<String, HashMap<Integer, String>> defaultMobFarmBonusMap = new HashMap<>();
   private static boolean registered = false;

   public static synchronized void ensureRegistered() {
      if (!registered) {
         registerConfig();
      }
   }

   public static synchronized void registerConfig() {
      if (registered) {
         return;
      }
      registerConfigFile(
         "mob_farm_bonus.cfg",
         " Mob Farm Bonus Configuration\n\n This configuration file allows you to define the bonus drops for the Mob Farms.\n\n Configuration Format:\n --------------------\n <mob_farm_name>::<tier_level>::<entity_type> = <item_name>::<amount>::<chance 1 of x>\n\n Available Mob Farm Types:\n ------------------------\n - animal_plains_farm: For animals like cows, sheep, chickens, pigs\n - bee_hive_farm: For bees and honey production\n - desert_farm: For desert mobs like husks, rabbits, camels\n - iron_golem_farm: For iron golems and poppy drops\n - jungle_farm: For jungle mobs like parrots, pandas, ocelots\n - monster_plains_cave_farm: For common monsters like zombies, skeletons, spiders\n - nether_fortress_farm: For nether mobs like blazes, magma cubes, wither skeletons\n - ocean_farm: For ocean mobs like cod, salmon, squid, guardians\n - swamp_farm: For swamp mobs like frogs, slimes, witches\n\n Tier Levels (better farms = better bonus chances):\n -------------------------------------------------\n - 0: Basic tier (lowest bonus chance)\n - 1: Improved tier (better bonus chance)\n - 2: Advanced tier (good bonus chance)\n - 3: Elite tier (highest bonus chance)\n\n Configuration Examples:\n ----------------------\n Basic bee farm with 1 in 20 chance for honeycomb:\n   bee_hive_farm::0::minecraft:bee = minecraft:honeycomb::1::20\n\n Elite bee farm with 1 in 5 chance for honeycomb:\n   bee_hive_farm::3::minecraft:bee = minecraft:honeycomb::1::5\n\n Iron golem farm with bonus iron ingots:\n   iron_golem_farm::2::minecraft:iron_golem = minecraft:iron_ingot::2::8\n\n Multiple bonus items for the same mob (different lines):\n   ocean_farm::1::minecraft:cod = minecraft:cod::1::10\n   ocean_farm::1::minecraft:cod = minecraft:bone_meal::1::25\n\n Important Notes:\n ---------------\n - Lower chance numbers = higher drop probability (1 = always, 100 = 1% chance)\n - To disable a bonus drop, set the amount to 0\n - Each mob farm type targets specific biome-appropriate mobs\n - Higher tier farms have better default bonus chances\n\n"
      );
      parseConfigFile();
      registered = true;
   }

   public static void parseConfigFile() {
      File configFile = getConfigFile("mob_farm_bonus.cfg");
      Properties properties = readConfigFile(configFile);
      Properties unmodifiedProperties = (Properties)properties.clone();
      defaultMobFarmBonusMap.forEach((mobFarmName, bonusMap) -> {
         if (!properties.containsKey(mobFarmName)) {
            bonusMap.forEach((chance, itemCount) -> {
               String value = itemCount + "::" + chance;
               properties.setProperty(mobFarmName, value);
            });
         }
      });
      properties.forEach((key, value) -> {
         String[] keyParts = parseKey((String)key);
         if (keyParts != null) {
            String mobFarmName = keyParts[0];
            String entityType = keyParts[2];
            String[] valueParts = parseValue((String)value);
            if (valueParts != null && !valueParts[0].isEmpty()) {
               String itemName = valueParts[0];

               try {
                  int tierLevel = Integer.parseInt(keyParts[1]);
                  int amount = Integer.parseInt(valueParts[1]);
                  int chance = Integer.parseInt(valueParts[2]);
                  addBonusDropEntry(mobFarmName, tierLevel, entityType, chance, itemName, amount);
               } catch (NumberFormatException e) {
                  log.error("{} Invalid number format in config file {}: key={}, value={}", "[MobFarmBonusConfig]", "mob_farm_bonus.cfg", key, value);
               }
            }
         }
      });
      updateConfigFileIfChanged(
         configFile,
         " Mob Farm Bonus Configuration\n\n This configuration file allows you to define the bonus drops for the Mob Farms.\n\n Configuration Format:\n --------------------\n <mob_farm_name>::<tier_level>::<entity_type> = <item_name>::<amount>::<chance 1 of x>\n\n Available Mob Farm Types:\n ------------------------\n - animal_plains_farm: For animals like cows, sheep, chickens, pigs\n - bee_hive_farm: For bees and honey production\n - desert_farm: For desert mobs like husks, rabbits, camels\n - iron_golem_farm: For iron golems and poppy drops\n - jungle_farm: For jungle mobs like parrots, pandas, ocelots\n - monster_plains_cave_farm: For common monsters like zombies, skeletons, spiders\n - nether_fortress_farm: For nether mobs like blazes, magma cubes, wither skeletons\n - ocean_farm: For ocean mobs like cod, salmon, squid, guardians\n - swamp_farm: For swamp mobs like frogs, slimes, witches\n\n Tier Levels (better farms = better bonus chances):\n -------------------------------------------------\n - 0: Basic tier (lowest bonus chance)\n - 1: Improved tier (better bonus chance)\n - 2: Advanced tier (good bonus chance)\n - 3: Elite tier (highest bonus chance)\n\n Configuration Examples:\n ----------------------\n Basic bee farm with 1 in 20 chance for honeycomb:\n   bee_hive_farm::0::minecraft:bee = minecraft:honeycomb::1::20\n\n Elite bee farm with 1 in 5 chance for honeycomb:\n   bee_hive_farm::3::minecraft:bee = minecraft:honeycomb::1::5\n\n Iron golem farm with bonus iron ingots:\n   iron_golem_farm::2::minecraft:iron_golem = minecraft:iron_ingot::2::8\n\n Multiple bonus items for the same mob (different lines):\n   ocean_farm::1::minecraft:cod = minecraft:cod::1::10\n   ocean_farm::1::minecraft:cod = minecraft:bone_meal::1::25\n\n Important Notes:\n ---------------\n - Lower chance numbers = higher drop probability (1 = always, 100 = 1% chance)\n - To disable a bonus drop, set the amount to 0\n - Each mob farm type targets specific biome-appropriate mobs\n - Higher tier farms have better default bonus chances\n\n",
         properties,
         unmodifiedProperties
      );
   }

   public static String getMobFarmKey(String mobFarmName, int tierLevel, String entityType) {
      return mobFarmName + "::" + tierLevel + "::" + entityType;
   }

   public static void addBonusDropEntry(String mobFarmName, int tierLevel, String entityType, int chance, String itemName, int amount) {
      Optional<Item> item = BuiltInRegistries.ITEM.getOptional(Identifier.tryParse(itemName));
      if (!item.isEmpty() && item.get() != Items.AIR) {
         try {
            MobFarmType mobFarmType = MobFarmType.valueOf(mobFarmName.toUpperCase(Locale.ROOT));
            addBonusDropEntry(mobFarmType, tierLevel, entityType, chance, new ItemStack((ItemLike)item.get(), amount));
         } catch (IllegalArgumentException e) {
            log.error("{} Invalid mob farm name {} in config file {}", "[MobFarmBonusConfig]", mobFarmName, "mob_farm_bonus.cfg");
         }
      } else {
         log.error("{} Invalid item name {} in config file {}", "[MobFarmBonusConfig]", itemName, "mob_farm_bonus.cfg");
      }
   }

   public static void addBonusDropEntry(MobFarmType mobFarmType, int tierLevel, String entityType, int chance, ItemStack itemStack) {
      String mobFarmKey = getMobFarmKey(mobFarmType.getId(), tierLevel, entityType);
      if (itemStack.isEmpty()) {
         log.error("{} Invalid item stack {} in config file {}", "[MobFarmBonusConfig]", itemStack, "mob_farm_bonus.cfg");
      } else if (BuiltInRegistries.ENTITY_TYPE.getOptional(Identifier.tryParse(entityType)).isEmpty()) {
         log.error("{} Invalid entity type {} in config file {}", "[MobFarmBonusConfig]", entityType, "mob_farm_bonus.cfg");
      } else {
         log.info("{} Add {} with a chance of 1 of {} for {}.", "[MobFarmBonusConfig]", mobFarmKey, chance, itemStack);
         mobFarmBonusMap.computeIfAbsent(mobFarmKey, k -> new HashMap<>()).put(chance, itemStack);
      }
   }

   public static ItemStack getBonusDropEntry(MobFarmType mobFarmType, int tierLevel, EntityType<?> entityType) {
      return getBonusDropEntry(mobFarmType.getId(), tierLevel, String.valueOf(BuiltInRegistries.ENTITY_TYPE.getKey(entityType)));
   }

   public static ItemStack getBonusDropEntry(String mobFarmName, int tierLevel, String entityType) {
      ensureRegistered();
      return !hasBonusDrop(mobFarmName, tierLevel, entityType)
         ? ItemStack.EMPTY
         : mobFarmBonusMap.get(getMobFarmKey(mobFarmName, tierLevel, entityType)).entrySet().stream().map(Entry::getValue).findFirst().orElse(ItemStack.EMPTY);
   }

   public static ItemStack getBonusDrop(MobFarmType mobFarmType, int tierLevel, EntityType<?> entityType) {
      return getBonusDrop(mobFarmType.getId(), tierLevel, String.valueOf(BuiltInRegistries.ENTITY_TYPE.getKey(entityType)));
   }

   public static ItemStack getBonusDrop(String mobFarmName, int tierLevel, String entityType) {
      ensureRegistered();
      return !hasBonusDrop(mobFarmName, tierLevel, entityType)
         ? ItemStack.EMPTY
         : mobFarmBonusMap.get(getMobFarmKey(mobFarmName, tierLevel, entityType))
            .entrySet()
            .stream()
            .filter(entry -> random.nextInt(entry.getKey()) == 0)
            .map(Entry::getValue)
            .findFirst()
            .orElse(ItemStack.EMPTY);
   }

   public static boolean hasBonusDrop(String mobFarmName, int tierLevel, EntityType<?> entityType) {
      return hasBonusDrop(mobFarmName, tierLevel, String.valueOf(BuiltInRegistries.ENTITY_TYPE.getKey(entityType)));
   }

   public static boolean hasBonusDrop(String mobFarmName, int tierLevel, String entityType) {
      ensureRegistered();
      return mobFarmBonusMap.containsKey(getMobFarmKey(mobFarmName, tierLevel, entityType));
   }

   private static String[] parseKey(String key) {
      String[] keyParts = key.split("::");
      if (keyParts.length != 3) {
         log.error("Invalid key format in config file: {}", key);
         return null;
      } else {
         return keyParts;
      }
   }

   private static String[] parseValue(String value) {
      String[] valueParts = value.split("::");
      if (valueParts.length != 3) {
         log.error("Invalid value format in config file: {}", value);
         return null;
      } else {
         return valueParts;
      }
   }

   static {
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::0::minecraft:cow", new HashMap<>(Map.of(20, "minecraft:leather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::1::minecraft:cow", new HashMap<>(Map.of(15, "minecraft:leather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::2::minecraft:cow", new HashMap<>(Map.of(10, "minecraft:leather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::3::minecraft:cow", new HashMap<>(Map.of(5, "minecraft:leather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::0::minecraft:sheep", new HashMap<>(Map.of(20, "minecraft:white_wool::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::1::minecraft:sheep", new HashMap<>(Map.of(15, "minecraft:white_wool::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::2::minecraft:sheep", new HashMap<>(Map.of(10, "minecraft:white_wool::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::3::minecraft:sheep", new HashMap<>(Map.of(5, "minecraft:white_wool::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::0::minecraft:chicken", new HashMap<>(Map.of(20, "minecraft:egg::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::1::minecraft:chicken", new HashMap<>(Map.of(15, "minecraft:egg::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::2::minecraft:chicken", new HashMap<>(Map.of(10, "minecraft:egg::1")));
      defaultMobFarmBonusMap.put(MobFarmType.ANIMAL_PLAINS_FARM.getId() + "::3::minecraft:chicken", new HashMap<>(Map.of(5, "minecraft:egg::1")));
      defaultMobFarmBonusMap.put(MobFarmType.BEE_HIVE_FARM.getId() + "::0::minecraft:bee", new HashMap<>(Map.of(20, "minecraft:honeycomb::1")));
      defaultMobFarmBonusMap.put(MobFarmType.BEE_HIVE_FARM.getId() + "::1::minecraft:bee", new HashMap<>(Map.of(15, "minecraft:honeycomb::1")));
      defaultMobFarmBonusMap.put(MobFarmType.BEE_HIVE_FARM.getId() + "::2::minecraft:bee", new HashMap<>(Map.of(10, "minecraft:honeycomb::1")));
      defaultMobFarmBonusMap.put(MobFarmType.BEE_HIVE_FARM.getId() + "::3::minecraft:bee", new HashMap<>(Map.of(5, "minecraft:honeycomb::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::0::minecraft:husk", new HashMap<>(Map.of(20, "minecraft:sand::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::1::minecraft:husk", new HashMap<>(Map.of(15, "minecraft:sand::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::2::minecraft:husk", new HashMap<>(Map.of(10, "minecraft:sand::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::3::minecraft:husk", new HashMap<>(Map.of(5, "minecraft:sand::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::0::minecraft:rabbit", new HashMap<>(Map.of(20, "minecraft:rabbit_hide::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::1::minecraft:rabbit", new HashMap<>(Map.of(15, "minecraft:rabbit_hide::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::2::minecraft:rabbit", new HashMap<>(Map.of(10, "minecraft:rabbit_hide::1")));
      defaultMobFarmBonusMap.put(MobFarmType.DESERT_FARM.getId() + "::3::minecraft:rabbit", new HashMap<>(Map.of(5, "minecraft:rabbit_hide::1")));
      defaultMobFarmBonusMap.put(
         MobFarmType.IRON_GOLEM_FARM.getId() + "::0::minecraft:iron_golem", new HashMap<>(Map.of(20, "minecraft:iron_ingot::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.IRON_GOLEM_FARM.getId() + "::1::minecraft:iron_golem", new HashMap<>(Map.of(15, "minecraft:iron_ingot::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.IRON_GOLEM_FARM.getId() + "::2::minecraft:iron_golem", new HashMap<>(Map.of(10, "minecraft:iron_ingot::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.IRON_GOLEM_FARM.getId() + "::3::minecraft:iron_golem", new HashMap<>(Map.of(5, "minecraft:iron_ingot::1"))
      );
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::0::minecraft:parrot", new HashMap<>(Map.of(20, "minecraft:feather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::1::minecraft:parrot", new HashMap<>(Map.of(15, "minecraft:feather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::2::minecraft:parrot", new HashMap<>(Map.of(10, "minecraft:feather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::3::minecraft:parrot", new HashMap<>(Map.of(5, "minecraft:feather::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::0::minecraft:panda", new HashMap<>(Map.of(20, "minecraft:bamboo::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::1::minecraft:panda", new HashMap<>(Map.of(15, "minecraft:bamboo::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::2::minecraft:panda", new HashMap<>(Map.of(10, "minecraft:bamboo::1")));
      defaultMobFarmBonusMap.put(MobFarmType.JUNGLE_FARM.getId() + "::3::minecraft:panda", new HashMap<>(Map.of(5, "minecraft:bamboo::1")));
      defaultMobFarmBonusMap.put(
         MobFarmType.MONSTER_PLAINS_CAVE_FARM.getId() + "::0::minecraft:zombie", new HashMap<>(Map.of(20, "minecraft:rotten_flesh::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.MONSTER_PLAINS_CAVE_FARM.getId() + "::1::minecraft:zombie", new HashMap<>(Map.of(15, "minecraft:rotten_flesh::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.MONSTER_PLAINS_CAVE_FARM.getId() + "::2::minecraft:zombie", new HashMap<>(Map.of(10, "minecraft:rotten_flesh::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.MONSTER_PLAINS_CAVE_FARM.getId() + "::3::minecraft:zombie", new HashMap<>(Map.of(5, "minecraft:rotten_flesh::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::0::minecraft:blaze", new HashMap<>(Map.of(20, "minecraft:blaze_rod::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::1::minecraft:blaze", new HashMap<>(Map.of(15, "minecraft:blaze_rod::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::2::minecraft:blaze", new HashMap<>(Map.of(10, "minecraft:blaze_rod::1"))
      );
      defaultMobFarmBonusMap.put(MobFarmType.NETHER_FORTRESS_FARM.getId() + "::3::minecraft:blaze", new HashMap<>(Map.of(5, "minecraft:blaze_rod::1")));
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::0::minecraft:magma_cube", new HashMap<>(Map.of(20, "minecraft:magma_cream::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::1::minecraft:magma_cube", new HashMap<>(Map.of(15, "minecraft:magma_cream::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::2::minecraft:magma_cube", new HashMap<>(Map.of(10, "minecraft:magma_cream::1"))
      );
      defaultMobFarmBonusMap.put(
         MobFarmType.NETHER_FORTRESS_FARM.getId() + "::3::minecraft:magma_cube", new HashMap<>(Map.of(5, "minecraft:magma_cream::1"))
      );
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::0::minecraft:cod", new HashMap<>(Map.of(20, "minecraft:cod::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::1::minecraft:cod", new HashMap<>(Map.of(15, "minecraft:cod::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::2::minecraft:cod", new HashMap<>(Map.of(10, "minecraft:cod::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::3::minecraft:cod", new HashMap<>(Map.of(5, "minecraft:cod::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::0::minecraft:squid", new HashMap<>(Map.of(20, "minecraft:ink_sac::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::1::minecraft:squid", new HashMap<>(Map.of(15, "minecraft:ink_sac::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::2::minecraft:squid", new HashMap<>(Map.of(10, "minecraft:ink_sac::1")));
      defaultMobFarmBonusMap.put(MobFarmType.OCEAN_FARM.getId() + "::3::minecraft:squid", new HashMap<>(Map.of(5, "minecraft:ink_sac::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::0::minecraft:frog", new HashMap<>(Map.of(20, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::1::minecraft:frog", new HashMap<>(Map.of(15, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::2::minecraft:frog", new HashMap<>(Map.of(10, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::3::minecraft:frog", new HashMap<>(Map.of(5, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::0::minecraft:slime", new HashMap<>(Map.of(20, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::1::minecraft:slime", new HashMap<>(Map.of(15, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::2::minecraft:slime", new HashMap<>(Map.of(10, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::3::minecraft:slime", new HashMap<>(Map.of(5, "minecraft:slime_ball::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::0::minecraft:witch", new HashMap<>(Map.of(20, "minecraft:redstone::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::1::minecraft:witch", new HashMap<>(Map.of(15, "minecraft:redstone::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::2::minecraft:witch", new HashMap<>(Map.of(10, "minecraft:redstone::1")));
      defaultMobFarmBonusMap.put(MobFarmType.SWAMP_FARM.getId() + "::3::minecraft:witch", new HashMap<>(Map.of(5, "minecraft:redstone::1")));
   }
}
