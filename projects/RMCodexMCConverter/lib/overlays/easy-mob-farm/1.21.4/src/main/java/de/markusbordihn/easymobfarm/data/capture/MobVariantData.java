package de.markusbordihn.easymobfarm.data.capture;

import de.markusbordihn.easymobfarm.compat.CompatConstants;
import java.util.Locale;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.animal.feline.Cat;
import net.minecraft.world.entity.animal.feline.CatVariants;
import net.minecraft.world.entity.animal.frog.Frog;
import net.minecraft.world.entity.animal.frog.FrogVariants;
import net.minecraft.world.entity.monster.cubemob.MagmaCube;
import net.minecraft.world.entity.monster.cubemob.Slime;
import net.minecraft.world.entity.npc.villager.Villager;

public class MobVariantData {
   public static final String VARIANT_TAG = "Variant";
   public static final String LARGE_VARIANT = "large";
   public static final String MEDIUM_VARIANT = "medium";
   public static final String SMALL_VARIANT = "small";
   public static final String TINY_VARIANT = "tiny";

   private MobVariantData() {
   }

   public static String getVariant(EntityType<?> entityType) {
      return "";
   }

   public static String getVariant(LivingEntity livingEntity) {
      if (livingEntity instanceof Cat cat) {
         return cat.getVariant().unwrapKey().orElse(CatVariants.BLACK).identifier().toString().replace("minecraft:", "");
      } else if (livingEntity instanceof Villager villager) {
         return villager.getVillagerData().profession().unwrapKey().map(k -> k.identifier().getPath()).orElse("");
      } else if (livingEntity instanceof MagmaCube magmaCube) {
         return getSizeVariant(magmaCube.getSize());
      } else if (livingEntity instanceof Slime slime) {
         return getSizeVariant(slime.getSize());
      } else if (livingEntity instanceof Frog frog) {
         String frogVariant = frog.getVariant().unwrapKey().orElse(FrogVariants.TEMPERATE).identifier().toString().replace("minecraft:", "");
         if (CompatConstants.MOD_SWAMPIER_SWAMPS_LOADED) {
            frogVariant = frogVariant.replace("swampier_swamps:", "").replace("frog_", "").replace("_variant", "");
         }

         return frogVariant;
      } else {
         return "";
      }
   }

   public static String getVariant(CompoundTag compoundTag) {
      if (compoundTag == null) {
         return "";
      } else if (compoundTag.contains("Variant")) {
         return compoundTag.getStringOr("Variant", "");
      } else {
         return compoundTag.contains("Variant".toLowerCase(Locale.ROOT))
            ? compoundTag.getStringOr("Variant".toLowerCase(Locale.ROOT), "")
            : "";
      }
   }

   public static String getSizeVariant(float size) {
      if (size <= 1.0F) {
         return "tiny";
      } else if (size <= 2.0F) {
         return "small";
      } else if (size < 4.0F) {
         return "medium";
      } else {
         return size >= 4.0F ? "large" : "";
      }
   }
}
