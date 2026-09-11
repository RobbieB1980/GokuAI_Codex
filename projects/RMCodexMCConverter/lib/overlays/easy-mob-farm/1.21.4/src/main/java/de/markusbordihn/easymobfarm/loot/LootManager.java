package de.markusbordihn.easymobfarm.loot;

import de.markusbordihn.easymobfarm.compat.CompatConstants;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureData;
import de.markusbordihn.easymobfarm.data.capture.MobVariantData;
import de.markusbordihn.easymobfarm.data.enhancement.FrogCatalystType;
import de.markusbordihn.easymobfarm.experience.ExperienceManager;
import de.markusbordihn.easymobfarm.item.upgrade.EnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.EggCollectorEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.ExperienceEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.FrogCatalystEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.HoneyExtractorEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.HoneyHarvesterFrameEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.KnifeEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.LootEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.LuckEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.MilkExtractorEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.PollenTrapEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.SheepEnhancementItem;
import de.markusbordihn.easymobfarm.item.upgrade.enhancement.SwordEnhancementItem;
import de.markusbordihn.easymobfarm.server.player.FakePlayer;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import net.minecraft.core.BlockPos;
import net.minecraft.core.NonNullList;
import net.minecraft.core.Holder.Reference;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntitySpawnReason;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.animal.bee.Bee;
import net.minecraft.world.entity.animal.chicken.Chicken;
import net.minecraft.world.entity.animal.cow.Cow;
import net.minecraft.world.entity.animal.sheep.Sheep;
import net.minecraft.world.entity.animal.frog.Frog;
import net.minecraft.world.entity.boss.wither.WitherBoss;
import net.minecraft.world.entity.monster.cubemob.MagmaCube;
import net.minecraft.world.item.DyeColor;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.ItemLike;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.storage.loot.LootParams;
import net.minecraft.world.level.storage.loot.LootTable;
import net.minecraft.world.level.storage.loot.LootParams.Builder;
import net.minecraft.world.level.storage.loot.parameters.LootContextParamSets;
import net.minecraft.world.level.storage.loot.parameters.LootContextParams;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class LootManager {
   private static final Logger log = LogManager.getLogger("Easy Mob Farm");
   private static final Random random = new Random();
   private static final Map<String, Identifier> FROG_CATALYST_RESOURCES = Map.ofEntries(
      Map.entry("cold", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_COLD)),
      Map.entry("temperate", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_TEMPERATE)),
      Map.entry("warm", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_WARM)),
      Map.entry("white", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_WHITE)),
      Map.entry("orange", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_ORANGE)),
      Map.entry("magenta", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_MAGENTA)),
      Map.entry("light_blue", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_LIGHT_BLUE)),
      Map.entry("yellow", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_YELLOW)),
      Map.entry("lime", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_LIME)),
      Map.entry("pink", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_PINK)),
      Map.entry("gray", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_GRAY)),
      Map.entry("light_gray", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_LIGHT_GRAY)),
      Map.entry("cyan", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_CYAN)),
      Map.entry("purple", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_PURPLE)),
      Map.entry("blue", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_BLUE)),
      Map.entry("brown", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_BROWN)),
      Map.entry("green", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_GREEN)),
      Map.entry("red", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_RED)),
      Map.entry("black", Identifier.fromNamespaceAndPath("easy_mob_farm", FrogCatalystEnhancementItem.ID_BLACK))
   );
   private static final EnumMap<FrogCatalystType, Identifier> FROGLIGHT_MAP = new EnumMap<>(FrogCatalystType.class);
   private static FakePlayer fakePlayer;

   private LootManager() {
   }

   public static NonNullList<ItemStack> getEntityLoot(MobCaptureData mobCaptureData, List<EnhancementItem> enhancements, Level level) {
      EntityType<?> entityType = mobCaptureData.entityType();
      if (entityType == null) {
         log.error("Unable to get entity type from Mob Capture data: {}", mobCaptureData);
         return NonNullList.create();
      }

      Entity entity = entityType.create(level, EntitySpawnReason.EVENT);
      if (entity == null) {
         log.error("Unable to create entity {}!", entityType);
         return NonNullList.create();
      }

      try {
         entity.load(net.minecraft.world.level.storage.TagValueInput.create(
            net.minecraft.util.ProblemReporter.DISCARDING, level.registryAccess(), mobCaptureData.data()));
         if (entity instanceof Sheep sheepEntity) {
            sheepEntity.setSheared(false);
            if (mobCaptureData.hasColor()) {
               sheepEntity.setColor(mobCaptureData.color().getDyeColor());
            }
         }

         return getEntityLoot(entity, enhancements, level);
      } finally {
         entity.discard();
      }
   }

   public static NonNullList<ItemStack> getEntityLoot(Entity entity, List<EnhancementItem> enhancements, Level level) {
      NonNullList<ItemStack> drops = NonNullList.create();
      if (entity instanceof LivingEntity livingEntity && level instanceof ServerLevel serverLevel) {
         FakePlayer fakePlayer = getFakePlayer(serverLevel, entity.blockPosition());
         Builder lootContextBuilder = createLootContextBuilder(serverLevel, livingEntity);
         float additionalLuck = 0.0F;
         int additionalRolls = 0;

         for (EnhancementItem enhancement : enhancements) {
            if (enhancement instanceof SwordEnhancementItem) {
               setSwordEnhancementParameters(lootContextBuilder, fakePlayer, serverLevel);
               additionalLuck += 0.5F;
            }

            if (enhancement instanceof KnifeEnhancementItem) {
               setKnifeEnhancementParameters(lootContextBuilder, fakePlayer, serverLevel);
               additionalLuck += 0.25F;
            }

            if (enhancement instanceof LootEnhancementItem) {
               additionalRolls++;
            }

            if (enhancement instanceof LuckEnhancementItem) {
               additionalLuck++;
            }
         }

         if (additionalLuck > 0.0F) {
            lootContextBuilder.withLuck(additionalLuck);
         }

         ResourceKey<LootTable> lootTableLocation = getLootTableLocation(livingEntity, enhancements);
         LootParams lootParams = lootContextBuilder.create(LootContextParamSets.ENTITY);
         if (lootTableLocation != null) {
            LootTable lootTable = serverLevel.getServer().reloadableRegistries().getLootTable(lootTableLocation);

            for (int i = 0; i <= additionalRolls; i++) {
               lootTable.getRandomItems(lootParams).stream().filter(itemStack -> !itemStack.isEmpty()).forEach(drops::add);
               handleSpecialEntityDrops(livingEntity, drops);
            }
         }

         if (drops.isEmpty()) {
            ResourceKey<LootTable> customLootTableLocation = getCustomLootTableLocation(livingEntity, enhancements);
            LootTable customLootTable = serverLevel.getServer().reloadableRegistries().getLootTable(customLootTableLocation);
            if (customLootTable != LootTable.EMPTY) {
               log.debug("No loot drops for {} trying custom loot table {}!", livingEntity, customLootTableLocation);

               for (int i = 0; i <= additionalRolls; i++) {
                  customLootTable.getRandomItems(lootParams).stream().filter(itemStack -> !itemStack.isEmpty()).forEach(drops::add);
               }
            } else {
               log.debug("No loot drops for {} and no custom loot table {}!", livingEntity, customLootTableLocation);
            }
         }

         handlePostEnhancements(enhancements, livingEntity, serverLevel, fakePlayer, drops);
         handleKnifeEnhancementLoot(enhancements, livingEntity, serverLevel, lootParams, drops);
         return drops;
      } else {
         return drops;
      }
   }

   public static NonNullList<ItemStack> getLuckyLoot(MobCaptureData mobCaptureData, BlockPos blockPos, Level Level) {
      NonNullList<ItemStack> drops = NonNullList.create();
      if (Level instanceof ServerLevel serverLevel) {
         ResourceKey lootTableLocation = ResourceKey.create(
            Registries.LOOT_TABLE, Identifier.fromNamespaceAndPath("minecraft", switch (mobCaptureData.rarity()) {
               case COMMON -> "chests/simple_dungeon";
               case UNCOMMON -> "chests/village/village_toolsmith";
               case RARE -> "chests/stronghold_library";
               case EPIC -> "chests/end_city_treasure";
               default -> throw new MatchException(null, null);
            })
         );
         FakePlayer fakePlayer = getFakePlayer(serverLevel, blockPos);
         LootTable lootTable = serverLevel.getServer().reloadableRegistries().getLootTable(lootTableLocation);
         Builder lootContextBuilder = createLootChestContextBuilder(serverLevel, fakePlayer);

         lootContextBuilder.withLuck(switch (mobCaptureData.rarity()) {
            case COMMON -> 0.0F;
            case UNCOMMON -> 0.5F;
            case RARE -> 1.0F;
            case EPIC -> 1.5F;
            default -> throw new MatchException(null, null);
         });
         LootParams lootContext = lootContextBuilder.create(LootContextParamSets.CHEST);
         lootTable.getRandomItems(lootContext).stream().filter(itemStack -> !itemStack.isEmpty()).forEach(drops::add);
         return drops;
      } else {
         return drops;
      }
   }

   private static void handleSpecialEntityDrops(LivingEntity livingEntity, NonNullList<ItemStack> drops) {
      if (livingEntity instanceof WitherBoss) {
         if (random.nextInt(2) == 0) {
            drops.add(new ItemStack(Items.NETHER_STAR));
         }

         if (random.nextInt(2) == 0) {
            drops.add(new ItemStack(Items.WITHER_ROSE));
         }
      }
   }

   private static Builder createLootContextBuilder(ServerLevel serverLevel, LivingEntity livingEntity) {
      return new Builder(serverLevel)
         .withParameter(LootContextParams.DAMAGE_SOURCE, serverLevel.damageSources().generic())
         .withParameter(LootContextParams.ORIGIN, livingEntity.position())
         .withParameter(LootContextParams.THIS_ENTITY, livingEntity);
   }

   private static Builder createLootChestContextBuilder(ServerLevel serverLevel, LivingEntity livingEntity) {
      return new Builder(serverLevel)
         .withParameter(LootContextParams.ORIGIN, livingEntity.position())
         .withParameter(LootContextParams.THIS_ENTITY, livingEntity);
   }

   private static ResourceKey<LootTable> getLootTableLocation(LivingEntity livingEntity, List<EnhancementItem> enhancements) {
      Optional<ResourceKey<LootTable>> lootTableLocation = livingEntity.getType().getDefaultLootTable();

      for (EnhancementItem enhancement : enhancements) {
         if (enhancement instanceof SheepEnhancementItem && livingEntity instanceof Sheep sheep) {
            DyeColor color = sheep.getColor();
            lootTableLocation = Optional.of(
               ResourceKey.create(Registries.LOOT_TABLE, Identifier.fromNamespaceAndPath("minecraft", "entities/sheep/" + color.getName()))
            );
         }
      }

      return lootTableLocation.orElse(null);
   }

   private static ResourceKey<LootTable> getCustomLootTableLocation(LivingEntity livingEntity, List<EnhancementItem> enhancements) {
      Identifier entityTypeResourceLocation = BuiltInRegistries.ENTITY_TYPE.getKey(livingEntity.getType());
      return ResourceKey.create(
         Registries.LOOT_TABLE,
         Identifier.fromNamespaceAndPath(
            "easy_mob_farm", "entities/" + entityTypeResourceLocation.getNamespace() + "/" + entityTypeResourceLocation.getPath()
         )
      );
   }

   private static void setSwordEnhancementParameters(Builder lootParamsBuilder, FakePlayer fakePlayer, ServerLevel serverLevel) {
      ItemStack swordItem = new ItemStack(Items.IRON_SWORD);
      fakePlayer.setItemInHand(InteractionHand.MAIN_HAND, swordItem);
      lootParamsBuilder.withParameter(LootContextParams.DAMAGE_SOURCE, serverLevel.damageSources().playerAttack(fakePlayer))
         .withParameter(LootContextParams.LAST_DAMAGE_PLAYER, fakePlayer)
         .withParameter(LootContextParams.ATTACKING_ENTITY, fakePlayer)
         .withParameter(LootContextParams.DIRECT_ATTACKING_ENTITY, fakePlayer);
   }

   private static void setKnifeEnhancementParameters(Builder lootParamsBuilder, FakePlayer fakePlayer, ServerLevel serverLevel) {
      ItemStack knifeItem = getKnifeTool();
      if (!knifeItem.isEmpty()) {
         fakePlayer.setItemInHand(InteractionHand.MAIN_HAND, knifeItem);
      }

      lootParamsBuilder.withParameter(LootContextParams.DAMAGE_SOURCE, serverLevel.damageSources().playerAttack(fakePlayer))
         .withParameter(LootContextParams.LAST_DAMAGE_PLAYER, fakePlayer)
         .withParameter(LootContextParams.ATTACKING_ENTITY, fakePlayer)
         .withParameter(LootContextParams.DIRECT_ATTACKING_ENTITY, fakePlayer);
   }

   private static ItemStack getKnifeTool() {
      if (CompatConstants.MOD_FARMERS_DELIGHT_LOADED) {
         Optional<Reference<Item>> farmersDelightKnife = BuiltInRegistries.ITEM.get(Identifier.fromNamespaceAndPath("farmersdelight", "iron_knife"));
         if (farmersDelightKnife.isPresent() && farmersDelightKnife.get().value() != Items.AIR) {
            return new ItemStack((ItemLike)farmersDelightKnife.get().value());
         }
      }

      return ItemStack.EMPTY;
   }

   private static void handlePostEnhancements(
      List<EnhancementItem> enhancements, LivingEntity livingEntity, ServerLevel serverLevel, FakePlayer fakePlayer, NonNullList<ItemStack> drops
   ) {
      for (EnhancementItem enhancement : enhancements) {
         if (enhancement instanceof ExperienceEnhancementItem experienceEnhancementItem
            && random.nextInt(experienceEnhancementItem.experienceDropChance()) == 0
            && ExperienceManager.shouldDropExperience(livingEntity)) {
            int experience = ExperienceManager.getExperienceReward(livingEntity, serverLevel);
            if (experience >= experienceEnhancementItem.minExperienceForDrop()) {
               drops.add(new ItemStack(Items.EXPERIENCE_BOTTLE));
            } else {
               log.debug(
                  "Experience drop of {} is below minimum threshold of {} for {}", experience, experienceEnhancementItem.minExperienceForDrop(), livingEntity
               );
            }
         }

         if (livingEntity instanceof Bee) {
            if (enhancement instanceof HoneyHarvesterFrameEnhancementItem && random.nextInt(4) == 0) {
               drops.add(new ItemStack(Items.HONEYCOMB));
            } else if (enhancement instanceof HoneyExtractorEnhancementItem && random.nextInt(10) == 0) {
               drops.add(new ItemStack(Items.HONEY_BOTTLE));
            } else if (enhancement instanceof PollenTrapEnhancementItem && random.nextInt(5) == 0) {
               if (random.nextFloat() < 0.3F) {
                  drops.add(getRandomFlower());
               } else {
                  drops.add(getRandomDye());
               }
            }
         } else if (livingEntity instanceof Cow) {
            if (enhancement instanceof MilkExtractorEnhancementItem && random.nextInt(2) == 0) {
               Optional<Reference<Item>> milkBottle;
               if (CompatConstants.MOD_FARMERS_DELIGHT_LOADED) {
                  milkBottle = BuiltInRegistries.ITEM.get(Identifier.fromNamespaceAndPath("farmersdelight", "milk_bottle"));
               } else {
                  milkBottle = BuiltInRegistries.ITEM.get(Identifier.fromNamespaceAndPath("easy_mob_farm", "milk_bottle"));
               }

               milkBottle.ifPresent(itemReference -> drops.add(new ItemStack(itemReference)));
            }
         } else if (livingEntity instanceof Chicken) {
            if (enhancement instanceof EggCollectorEnhancementItem && random.nextInt(2) == 0) {
               drops.add(new ItemStack(Items.EGG));
            }
         } else if (livingEntity instanceof Frog) {
            if (random.nextInt(40) == 0) {
               String frogVariant = MobVariantData.getVariant(livingEntity);
               Identifier frogCatalystResourceLocation = FROG_CATALYST_RESOURCES.get(frogVariant);
               if (frogCatalystResourceLocation != null) {
                  Optional<Reference<Item>> frogCatalystItem = BuiltInRegistries.ITEM.get(frogCatalystResourceLocation);
                  if (frogCatalystItem.isPresent() && frogCatalystItem.get().value() instanceof FrogCatalystEnhancementItem frogCatalystEnhancementItem) {
                     drops.add(new ItemStack(frogCatalystEnhancementItem));
                  } else {
                     log.warn("Frog Catalyst item {} is not an instance of FrogCatalystEnhancementItem!", frogCatalystItem);
                  }
               } else {
                  log.warn("No Frog Catalyst resource found for variant {}!", frogVariant);
               }
            }
         } else if (livingEntity instanceof MagmaCube) {
            if (random.nextInt(8) == 0) {
               drops.add(new ItemStack(Items.MAGMA_CREAM));
            }

            if (enhancement instanceof FrogCatalystEnhancementItem frogCatalystEnhancementItem && random.nextInt(2) == 0) {
               FrogCatalystType frogCatalystType = frogCatalystEnhancementItem.getFrogCatalystType();
               switch (frogCatalystType) {
                  case COLD:
                     drops.add(new ItemStack(Items.VERDANT_FROGLIGHT));
                     break;
                  case TEMPERATE:
                     drops.add(new ItemStack(Items.OCHRE_FROGLIGHT));
                     break;
                  case WARM:
                     drops.add(new ItemStack(Items.PEARLESCENT_FROGLIGHT));
                     break;
                  default:
                     if (!CompatConstants.MOD_SWAMPIER_SWAMPS_LOADED) {
                        log.error("Unknown Frog Catalyst type {}", frogCatalystType);
                     }
               }

               if (CompatConstants.MOD_SWAMPIER_SWAMPS_LOADED) {
                  Identifier frogCatalystResourceLocation = FROGLIGHT_MAP.get(frogCatalystType);
                  if (frogCatalystResourceLocation != null) {
                     Optional<Reference<Item>> frogCatalystItem = BuiltInRegistries.ITEM.get(frogCatalystResourceLocation);
                     if (frogCatalystItem.isPresent() && frogCatalystItem.get().value() != Items.AIR) {
                        drops.add(new ItemStack((ItemLike)frogCatalystItem.get().value()));
                     } else {
                        log.warn("Swampier Swamps: Frog Catalyst item {} is not available!", frogCatalystType);
                     }
                  }
               }
            }
         }
      }
   }

   private static void handleKnifeEnhancementLoot(
      List<EnhancementItem> enhancements, LivingEntity livingEntity, ServerLevel serverLevel, LootParams lootParams, NonNullList<ItemStack> drops
   ) {
      boolean hasKnifeEnhancement = false;

      for (EnhancementItem enhancement : enhancements) {
         if (enhancement instanceof KnifeEnhancementItem) {
            hasKnifeEnhancement = true;
            break;
         }
      }

      if (hasKnifeEnhancement) {
         Identifier entityTypeResourceLocation = BuiltInRegistries.ENTITY_TYPE.getKey(livingEntity.getType());
         ResourceKey<LootTable> knifeLootTableLocation = ResourceKey.create(
            Registries.LOOT_TABLE,
            Identifier.fromNamespaceAndPath(
               "easy_mob_farm", "enhancement/knife/" + entityTypeResourceLocation.getNamespace() + "/" + entityTypeResourceLocation.getPath()
            )
         );
         LootTable knifeLootTable = serverLevel.getServer().reloadableRegistries().getLootTable(knifeLootTableLocation);
         if (knifeLootTable != LootTable.EMPTY) {
            knifeLootTable.getRandomItems(lootParams).stream().filter(itemStack -> !itemStack.isEmpty()).forEach(drops::add);
         }
      }
   }

   private static FakePlayer getFakePlayer(ServerLevel level, BlockPos blockPos) {
      if (FakePlayer.isInvalidFakePlayer(fakePlayer)) {
         fakePlayer = new FakePlayer(level, blockPos);
         return fakePlayer;
      } else {
         return fakePlayer.updatePosition(level, blockPos);
      }
   }

   private static ItemStack getRandomFlower() {
      List<Item> flowers = List.of(
         Items.DANDELION,
         Items.POPPY,
         Items.BLUE_ORCHID,
         Items.ALLIUM,
         Items.AZURE_BLUET,
         Items.RED_TULIP,
         Items.ORANGE_TULIP,
         Items.WHITE_TULIP,
         Items.PINK_TULIP,
         Items.OXEYE_DAISY,
         Items.CORNFLOWER,
         Items.LILY_OF_THE_VALLEY
      );
      return new ItemStack((ItemLike)flowers.get(new Random().nextInt(flowers.size())));
   }

   private static ItemStack getRandomDye() {
      List<Item> dyes = List.of(Items.DYE.yellow(), Items.DYE.red(), Items.DYE.blue(), Items.DYE.orange(), Items.DYE.pink(), Items.DYE.white(), Items.DYE.black());
      return new ItemStack((ItemLike)dyes.get(new Random().nextInt(dyes.size())));
   }

   static {
      if (CompatConstants.MOD_SWAMPIER_SWAMPS_LOADED) {
         FROGLIGHT_MAP.put(FrogCatalystType.WHITE, Identifier.fromNamespaceAndPath("swampier_swamps", "white_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.ORANGE, Identifier.fromNamespaceAndPath("swampier_swamps", "orange_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.MAGENTA, Identifier.fromNamespaceAndPath("swampier_swamps", "magenta_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.LIGHT_BLUE, Identifier.fromNamespaceAndPath("swampier_swamps", "light_blue_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.YELLOW, Identifier.fromNamespaceAndPath("swampier_swamps", "yellow_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.LIME, Identifier.fromNamespaceAndPath("swampier_swamps", "lime_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.PINK, Identifier.fromNamespaceAndPath("swampier_swamps", "pink_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.GRAY, Identifier.fromNamespaceAndPath("swampier_swamps", "gray_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.LIGHT_GRAY, Identifier.fromNamespaceAndPath("swampier_swamps", "light_gray_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.CYAN, Identifier.fromNamespaceAndPath("swampier_swamps", "cyan_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.PURPLE, Identifier.fromNamespaceAndPath("minecraft", "pearlescent_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.BLUE, Identifier.fromNamespaceAndPath("swampier_swamps", "blue_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.BROWN, Identifier.fromNamespaceAndPath("swampier_swamps", "brown_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.GREEN, Identifier.fromNamespaceAndPath("swampier_swamps", "green_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.RED, Identifier.fromNamespaceAndPath("swampier_swamps", "red_froglight"));
         FROGLIGHT_MAP.put(FrogCatalystType.BLACK, Identifier.fromNamespaceAndPath("swampier_swamps", "black_froglight"));
      }
   }
}
