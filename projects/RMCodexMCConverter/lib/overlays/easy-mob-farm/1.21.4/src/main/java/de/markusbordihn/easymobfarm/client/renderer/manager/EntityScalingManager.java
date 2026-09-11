package de.markusbordihn.easymobfarm.client.renderer.manager;

import de.markusbordihn.easymobfarm.data.capture.MobCaptureCardDefinition;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureCardDefinitionManager;
import java.util.HashMap;
import java.util.Map;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.animal.bee.Bee;
import net.minecraft.world.entity.animal.happyghast.HappyGhast;
import net.minecraft.world.entity.monster.ElderGuardian;
import net.minecraft.world.entity.monster.Ghast;
import net.minecraft.world.entity.monster.Phantom;

public class EntityScalingManager {
   private static final float MAX_BLOCK_SCALE = 0.8F;
   private static final float DEFAULT_SCALE_BLOCK = 0.3F;
   private static final Map<Class<? extends Entity>, Float> entityScaleCache = new HashMap<>();

   private EntityScalingManager() {
   }

   private static boolean isAirMover(Entity entity) {
      // 26.2: FlyingMob / FlyingAnimal removed (primer 1.21.6 / 26.2).
      return entity instanceof Ghast
         || entity instanceof HappyGhast
         || entity instanceof Phantom
         || entity instanceof Bee bee && bee.isFlying();
   }

   public static float getEntityScale(Entity entity) {
      return entityScaleCache.computeIfAbsent(
         (Class<? extends Entity>)entity.getClass(),
         cls -> {
            float entityWidth;
            float entityHeight;
            if (entity.getBoundingBox().getXsize() > 0.0 && entity.getBoundingBox().getYsize() > 0.0) {
               entityWidth = (float)entity.getBoundingBox().getXsize();
               entityHeight = (float)entity.getBoundingBox().getYsize();
            } else {
               entityWidth = entity.getDimensions(entity.getPose()).width();
               entityHeight = entity.getDimensions(entity.getPose()).height();
            }

            MobCaptureCardDefinition mobCaptureCardDefinition = MobCaptureCardDefinitionManager.get(entity.getType());
            if (mobCaptureCardDefinition != null && mobCaptureCardDefinition.scale() > 0.0F && mobCaptureCardDefinition.scale() != 1.0F) {
               entityWidth *= mobCaptureCardDefinition.scale();
               entityHeight *= mobCaptureCardDefinition.scale();
            }

            if (entityWidth != 0.0F && entityHeight != 0.0F) {
               if (entity instanceof ElderGuardian) {
                  entityWidth *= 1.8F;
               }

               if ((!(entityWidth < 0.8F) || !(entityHeight < 0.8F)) && (!(entityWidth * 0.3F < 0.8F) || !(entityHeight * 0.3F < 0.8F))) {
                  float scaleFactor = Math.max(entityWidth, entityHeight) / 0.8F;
                  if (!(scaleFactor > 1.0F)) {
                     return 0.8F;
                  } else {
                     return !isAirMover(entity) ? 0.8F / scaleFactor : 0.8F / scaleFactor * 0.6F;
                  }
               } else {
                  return 0.3F;
               }
            } else {
               return 0.3F;
            }
         }
      );
   }

   public static float getUIScale(Entity entity) {
      float entityScale = getEntityScale(entity);
      return entityScale * 45.0F;
   }
}
