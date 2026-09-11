package de.markusbordihn.easymobfarm.item.mobcapturecard;

import de.markusbordihn.easymobfarm.capture.MobCaptureManager;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureData;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.Identifier;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Entity.RemovalReason;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class CreativeBlankMobCaptureCardItem extends BlankMobCaptureCardItem {
   public static final String ID = "creative_blank_mob_capture_card";
   private static final Logger log = LogManager.getLogger("Easy Mob Farm");

   public CreativeBlankMobCaptureCardItem() {
      super(
         new net.minecraft.world.item.Item.Properties().setId(
            ResourceKey.create(Registries.ITEM, Identifier.fromNamespaceAndPath("easy_mob_farm", "creative_blank_mob_capture_card"))
         )
      );
   }

   public CreativeBlankMobCaptureCardItem(net.minecraft.world.item.Item.Properties properties) {
      super(properties);
   }

   public InteractionResult interactLivingEntity(ItemStack itemStack, Player player, LivingEntity livingEntity, InteractionHand hand) {
      if (livingEntity != null && !(livingEntity instanceof Player) && !livingEntity.isDeadOrDying()) {
         Level level = livingEntity.level();
         if (level.isClientSide()) {
            return InteractionResult.SUCCESS;
         }

         ItemStack mobCaptureCardItemStack = MobCaptureManager.getMobCaptureCardItem(livingEntity);
         if (mobCaptureCardItemStack != null && !mobCaptureCardItemStack.isEmpty()) {
            MobCaptureData mobCaptureData = MobCaptureManager.getMobCaptureData(mobCaptureCardItemStack, level);
            if (mobCaptureData != null && mobCaptureData.entityType() != null) {
               if (player.getAbilities().instabuild) {
                  ItemStack mobCaptureCardItemStackCopy = mobCaptureCardItemStack.copy();
                  if (!player.addItem(mobCaptureCardItemStack)) {
                     log.error("Failed to add mob capture card {} to player {}", mobCaptureCardItemStack, player);
                     return InteractionResult.FAIL;
                  }

                  log.info("Added mob capture card {} to players inventory {}", mobCaptureCardItemStackCopy, player);
               } else {
                  player.setItemInHand(hand, mobCaptureCardItemStack);
                  log.info("Set mob capture card {} to players hand {}", player.getItemInHand(hand), player);
               }

               livingEntity.remove(RemovalReason.KILLED);
               return InteractionResult.CONSUME;
            } else {
               log.error("Failed to get mob capture data for entity {}", livingEntity);
               return InteractionResult.FAIL;
            }
         } else {
            log.error("Failed to capture entity {}", livingEntity);
            return InteractionResult.FAIL;
         }
      } else {
         return InteractionResult.FAIL;
      }
   }
}
