package de.markusbordihn.easymobfarm.client.screen;

import de.markusbordihn.easymobfarm.block.entity.MobFarmBlockEntity;
import de.markusbordihn.easymobfarm.client.renderer.manager.EntityScalingManager;
import de.markusbordihn.easymobfarm.client.renderer.manager.RendererManager;
import de.markusbordihn.easymobfarm.client.screen.components.Graphics;
import de.markusbordihn.easymobfarm.config.MobFarmBonusConfig;
import de.markusbordihn.easymobfarm.config.MobFarmConfig;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureCardDefinition;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureCardDefinitionManager;
import de.markusbordihn.easymobfarm.data.mobfarm.MobFarmType;
import de.markusbordihn.easymobfarm.menu.MobFarmMenu;
import de.markusbordihn.easymobfarm.menu.MobFarmSlot;
import de.markusbordihn.easymobfarm.menu.slots.OutputSlot;
import de.markusbordihn.easymobfarm.network.components.TextComponent;
import java.util.ArrayList;
import java.util.List;
import net.minecraft.ChatFormatting;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.MutableComponent;
import net.minecraft.resources.Identifier;
import net.minecraft.util.FormattedCharSequence;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.ItemStack;

public class MobFarmScreen<T extends MobFarmMenu> extends ContainerScreen<T> {
   private static final Identifier TEXTURE_UI = Identifier.fromNamespaceAndPath("easy_mob_farm", "textures/gui/mob_farm.png");
   private static final Identifier TEXTURE_UI_IDLE = Identifier.fromNamespaceAndPath("easy_mob_farm", "textures/gui/mob_farm_idle.png");
   private static final Identifier TEXTURE_ELEMENTS = Identifier.fromNamespaceAndPath("easy_mob_farm", "textures/gui/mob_farm_elements.png");
   protected float xMouse;
   protected float yMouse;
   protected Entity entity;
   protected int entityExperience;

   public MobFarmScreen(T menu, Inventory inventory, Component component) {
      super(menu, inventory, component);
   }

   public static MutableComponent getLocalizedRemainingTimeComponent(int totalTicks, int currentProgress, int speed, int bonus) {
      int remainingTicks = Math.max(0, totalTicks - currentProgress);
      float ticksPerSecond = Math.max(1.0F, speed + bonus);
      float secondsRemaining = remainingTicks / ticksPerSecond;
      int totalSeconds = Math.round(secondsRemaining);
      if (totalSeconds < 60) {
         return TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.next_drop.seconds", totalSeconds);
      }

      int minutes = totalSeconds / 60;
      int seconds = totalSeconds % 60;
      return TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.next_drop.full", new Object[]{minutes, seconds});
   }

   @Override
   protected void renderDefaultScreenBg(GuiGraphicsExtractor guiGraphics, int leftPos, int topPos) {
      Graphics.blit(guiGraphics, this.menu.getMobFarmStatus() == 0 ? TEXTURE_UI_IDLE : TEXTURE_UI, leftPos, topPos, 0, 0, 256, 243);
   }

   public void extractRenderState(GuiGraphicsExtractor guiGraphics, int x, int y, float partialTicks) {
      this.xMouse = x;
      this.yMouse = y;
      this.extractBackground(guiGraphics, x, y, partialTicks);
      super.extractRenderState(guiGraphics, x, y, partialTicks);
      this.renderLockedSlot(guiGraphics, x, y);
      this.renderEntityType(guiGraphics, x, y);
      this.renderMobFarmProgress(guiGraphics, x, y);
      this.extractTooltip(guiGraphics, x, y);
   }

   protected void extractLabels(GuiGraphicsExtractor guiGraphics, int x, int y) {
   }

   private void renderMobFarmProgress(GuiGraphicsExtractor guiGraphics, int x, int y) {
      int mobFarmProgress = ((MobFarmMenu)this.getMenu()).getMobFarmProgress();
      int currentWidth = mobFarmProgress * 32 / MobFarmConfig.farmProgressingTime;
      Graphics.blit(guiGraphics, TEXTURE_ELEMENTS, this.leftPos + 113, this.topPos + 78, 0, 36, currentWidth, 16);
   }

   private void renderEntityType(GuiGraphicsExtractor guiGraphics, int x, int y) {
      BlockPos blockPos = ((MobFarmMenu)this.getMenu()).getMobFarmBlockPos();
      if (blockPos != null && !blockPos.equals(BlockPos.ZERO)) {
         int mobFarmStatus = ((MobFarmMenu)this.getMenu()).getMobFarmStatus();
         if (mobFarmStatus != 0) {
            this.entity = RendererManager.getEntity(blockPos);
            if (this.entity != null) {
               ScreenHelper.renderEntity(
                  guiGraphics,
                  this.leftPos + 72,
                  this.topPos + 80,
                  this.leftPos + 70 - this.xMouse,
                  this.topPos + 40 - this.yMouse,
                  EntityScalingManager.getUIScale(this.entity),
                  this.entity
               );
            } else if (this.entityExperience > 0) {
               this.entityExperience = 0;
            }
         }
      }
   }

   private void renderLockedSlot(GuiGraphicsExtractor guiGraphics, int x, int y) {
      for (Slot slot : this.menu.slots) {
         if (slot instanceof OutputSlot outputSlot && !outputSlot.isActive()) {
            Graphics.blit(guiGraphics, TEXTURE_ELEMENTS, this.leftPos + slot.x - 1, this.topPos + slot.y - 1, 0, 18, 18, 18);
         }
      }
   }

   public void renderTooltip(GuiGraphicsExtractor guiGraphics, int mouseX, int mouseY) {
      super.extractTooltip(guiGraphics, mouseX, mouseY);
      MobFarmType mobFarmType = ((MobFarmMenu)this.getMenu()).getMobFarmType();
      boolean isAdvanced = Minecraft.getInstance().options.advancedItemTooltips;

      for (Slot slot : this.menu.slots) {
         if (slot instanceof MobFarmSlot mobFarmSlot
            && mobFarmSlot.getTooltip() != null
            && this.isHovering(slot.x, slot.y, 16, 16, mouseX, mouseY)
            && !slot.hasItem()) {
            this.renderSlotTooltip(guiGraphics, mobFarmSlot, mouseX, mouseY);
         }
      }

      if (this.isHovering(24, 17, 10, 13, mouseX, mouseY)) {
         List<Component> infoText = new ArrayList<>(List.of());
         if (mobFarmType != null) {
            infoText.add(
               TextComponent.getTranslatedTextRaw(
                     "tooltip.easy_mob_farm.farm." + mobFarmType.getId(), String.valueOf(((MobFarmMenu)this.getMenu()).getMobFarmTierLevel())
                  )
                  .withStyle(switch (((MobFarmMenu)this.getMenu()).getMobFarmTierLevel()) {
                     case 1 -> ChatFormatting.GREEN;
                     case 2 -> ChatFormatting.YELLOW;
                     case 3 -> ChatFormatting.RED;
                     default -> ChatFormatting.WHITE;
                  })
            );
         }

         infoText.add(TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.tier", new Object[]{((MobFarmMenu)this.getMenu()).getMobFarmTierLevel()}));
         infoText.add(
            TextComponent.getTranslatedTextRaw(
               "tooltip.easy_mob_farm.farm.status",
               TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.status_" + ((MobFarmMenu)this.getMenu()).getMobFarmStatus())
            )
         );
         if (((MobFarmMenu)this.getMenu()).getMobFarmStatus() == 200) {
            infoText.add(
               getLocalizedRemainingTimeComponent(
                  MobFarmConfig.farmProgressingTime,
                  ((MobFarmMenu)this.getMenu()).getMobFarmProgress(),
                  ((MobFarmMenu)this.getMenu()).getMobFarmProgressionSpeed(),
                  ((MobFarmMenu)this.getMenu()).getMobFarmProgressionSpeedBonus()
               )
            );
         }

         if (isAdvanced) {
            infoText.add(
               TextComponent.getTranslatedTextRaw(
                  "tooltip.easy_mob_farm.farm.progress", new Object[]{((MobFarmMenu)this.getMenu()).getMobFarmProgress(), MobFarmConfig.farmProgressingTime}
               )
            );
         }

         infoText.add(
            TextComponent.getTranslatedText(
               "tier_level_processing_speed",
               MobFarmBlockEntity.getProcessingSpeed(
                  ((MobFarmMenu)this.getMenu()).getMobFarmTierLevel(), ((MobFarmMenu)this.getMenu()).getMobFarmProgressionSpeedBonus()
               )
            )
         );
         if (isAdvanced) {
            infoText.add(
               TextComponent.getTranslatedTextRaw(
                  "tooltip.easy_mob_farm.farm.progression_speed",
                  new Object[]{((MobFarmMenu)this.getMenu()).getMobFarmProgressionSpeed(), ((MobFarmMenu)this.getMenu()).getMobFarmProgressionSpeedBonus()}
               )
            );
         }

         infoText.add(
            TextComponent.getTranslatedTextRaw(
               "tooltip.easy_mob_farm.farm.output_slots", new Object[]{((MobFarmMenu)this.getMenu()).getMobFarmNumberOfOutputSlots()}
            )
         );
         if (mobFarmType == MobFarmType.LUCKY_DROP_FARM) {
            infoText.add(
               TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.lucky_drop_percentage", new Object[]{MobFarmConfig.luckyDropFarmLuckPercentage})
            );
            if (MobFarmConfig.luckyDropFarmLuckPercentage < 100) {
               infoText.add(TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.lucky_drop_warn").withStyle(ChatFormatting.RED));
            }
         }

         if (this.entity != null && ((MobFarmMenu)this.getMenu()).getMobFarmStatus() != 0) {
            infoText.add(TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.entity_type", new Object[]{this.entity.getType().toString()}));
            MobCaptureCardDefinition mobCaptureCardDefinition = MobCaptureCardDefinitionManager.get(this.entity.getType());
            if (mobCaptureCardDefinition != null && mobCaptureCardDefinition.requiresKilledByPlayer()) {
               infoText.add(TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.killed_by_player").withStyle(ChatFormatting.RED));
            }

            int capturedMobExperience = ((MobFarmMenu)this.getMenu()).getCapturedMobExperience();
            if (capturedMobExperience >= 3) {
               infoText.add(
                  TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.experience", new Object[]{capturedMobExperience})
                     .withStyle(ChatFormatting.GREEN)
               );
            } else if (capturedMobExperience > 0) {
               infoText.add(
                  TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.low_experience", new Object[]{capturedMobExperience})
                     .withStyle(ChatFormatting.YELLOW)
               );
            } else if (capturedMobExperience == 0) {
               infoText.add(TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.no_experience").withStyle(ChatFormatting.RED));
            }

            ItemStack bonusLootDrop = MobFarmBonusConfig.getBonusDropEntry(
               ((MobFarmMenu)this.getMenu()).getMobFarmType(), ((MobFarmMenu)this.getMenu()).getMobFarmTierLevel(), this.entity.getType()
            );
            if (!bonusLootDrop.isEmpty()) {
               infoText.add(
                  TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.bonus_drop", new Object[]{bonusLootDrop.getDisplayName()})
                     .withStyle(ChatFormatting.GREEN)
               );
            } else {
               infoText.add(TextComponent.getTranslatedTextRaw("tooltip.easy_mob_farm.farm.no_bonus_drop").withStyle(ChatFormatting.GRAY));
            }
         }

         guiGraphics.setComponentTooltipForNextFrame(this.font, infoText, mouseX, mouseY);
      }
   }

   private void renderSlotTooltip(GuiGraphicsExtractor guiGraphics, MobFarmSlot mobFarmSlot, int mouseX, int mouseY) {
      Component component = mobFarmSlot.getTooltip();
      if (component != null) {
         List<FormattedCharSequence> wrappedText = this.font.split(component, 150);
         guiGraphics.setTooltipForNextFrame(this.font, wrappedText, mouseX, mouseY);
      }
   }
}
