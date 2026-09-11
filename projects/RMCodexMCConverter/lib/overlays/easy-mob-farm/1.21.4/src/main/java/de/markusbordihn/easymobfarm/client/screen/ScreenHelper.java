package de.markusbordihn.easymobfarm.client.screen;

import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;

/**
 * 26.2: legacy MultiBufferSource inventory entity preview is gone.
 * Delegate LivingEntity draws to InventoryScreen.extractEntityInInventoryFollowsMouse.
 */
public class ScreenHelper {
   private ScreenHelper() {
   }

   public static void renderEntity(GuiGraphicsExtractor guiGraphics, int x, int y, float yRot, float xRot, float scale, Entity entity) {
      if (entity instanceof LivingEntity livingEntity) {
         renderEntity(guiGraphics, x, y, yRot, xRot, scale, livingEntity);
      }
   }

   public static void renderEntity(GuiGraphicsExtractor guiGraphics, int x, int y, float yRot, float xRot, float scale, LivingEntity livingEntity) {
      int size = Math.max(1, Math.round(scale));
      int x0 = x - size;
      int y0 = y - size;
      int x1 = x + size;
      int y1 = y + size;
      try {
         // mouseX/mouseY emulate the old yRot/xRot look-at offsets.
         InventoryScreen.extractEntityInInventoryFollowsMouse(
            guiGraphics, x0, y0, x1, y1, size, 0.0625F, x + yRot, y + xRot, livingEntity
         );
      } catch (RuntimeException ex) {
         // Never let a preview entity take down the whole screen.
      }
   }
}
