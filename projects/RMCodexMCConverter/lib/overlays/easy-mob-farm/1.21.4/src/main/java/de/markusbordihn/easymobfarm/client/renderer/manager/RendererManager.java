package de.markusbordihn.easymobfarm.client.renderer.manager;

import de.markusbordihn.easymobfarm.block.entity.MobFarmBlockEntity;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureData;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntitySpawnReason;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.PathfinderMob;
import net.minecraft.world.entity.animal.fish.AbstractFish;
import net.minecraft.world.entity.animal.sheep.Sheep;
import net.minecraft.world.phys.Vec3;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class RendererManager {
   private static final Logger log = LogManager.getLogger("Easy Mob Farm");
   private static final Map<BlockPos, Entity> entityMap = new HashMap<>();
   private static final AtomicInteger NEXT_PREVIEW_ENTITY_ID = new AtomicInteger(-1);
   private static int validationCounter = 0;

   private RendererManager() {
   }

   public static Entity getOrCreateEntity(MobFarmBlockEntity mobFarmBlockEntity) {
      if (mobFarmBlockEntity == null) {
         return null;
      }

      BlockPos blockPos = mobFarmBlockEntity.getBlockPos();
      if (!mobFarmBlockEntity.hasCapturedMob()) {
         entityMap.remove(blockPos);
         return null;
      }

      Entity cachedEntity = entityMap.get(blockPos);
      if (cachedEntity != null) {
         if (++validationCounter >= 100) {
            validationCounter = 0;
            MobCaptureData mobCaptureData = mobFarmBlockEntity.getMobCaptureData();
            if (mobCaptureData != null && cachedEntity.getType() != mobCaptureData.entityType()) {
               entityMap.remove(blockPos);
               cachedEntity = null;
            }
         }

         if (cachedEntity != null) {
            return cachedEntity;
         }
      }

      Entity entity = createEntity(mobFarmBlockEntity);
      if (entity != null) {
         entityMap.put(blockPos, entity);
      }

      return entity;
   }

   public static Entity getEntity(BlockPos blockPos) {
      return entityMap.get(blockPos);
   }

   public static void removeEntity(MobFarmBlockEntity mobFarmBlockEntity) {
      removeEntity(mobFarmBlockEntity.getBlockPos());
   }

   public static void removeEntity(BlockPos blockPos) {
      entityMap.remove(blockPos);
   }

   private static Entity createEntity(MobFarmBlockEntity mobFarmBlockEntity) {
      if (mobFarmBlockEntity != null && mobFarmBlockEntity.getLevel() != null) {
         MobCaptureData mobCaptureData = mobFarmBlockEntity.getMobCaptureData();
         if (mobCaptureData == null) {
            log.error("Unable to get Mob Capture data from Mob Farm Block Entity {}", mobFarmBlockEntity);
            return null;
         }

         EntityType<?> entityType = mobCaptureData.entityType();
         if (entityType == null) {
            log.error("Unable to get entity type from Mob Capture data {}", mobCaptureData);
            return null;
         }

         Entity entity = entityType.create(mobFarmBlockEntity.getLevel(), EntitySpawnReason.EVENT);
         if (entity == null) {
            log.error("Unable to create entity for entity type {}", entityType);
            return null;
         }

         // 26.2: Entity.getId() throws if still INVALID_ENTITY_ID (0). GUI preview
         // entities are never added to the level, so assign a unique negative id.
         entity.setId(NEXT_PREVIEW_ENTITY_ID.getAndDecrement());
         entity.tick();
         entity.setPos(0.0, 0.0, 0.0);
         entity.setDeltaMovement(Vec3.ZERO);
         entity.xOld = 0.0;
         entity.yOld = 0.0;
         entity.zOld = 0.0;
         entity.setOnGround(true);
         entity.flyDist = 0.0F;
         entity.tick();
         entity.setYHeadRot(mobFarmBlockEntity.getLevel().getRandom().nextFloat() * 60.0F);
         entity.setYBodyRot(mobFarmBlockEntity.getLevel().getRandom().nextFloat() * 10.0F);
         entity.xRotO = entity.getXRot();
         entity.yRotO = entity.getYRot();
         entity.load(net.minecraft.world.level.storage.TagValueInput.create(net.minecraft.util.ProblemReporter.DISCARDING, mobFarmBlockEntity.getLevel().registryAccess(), mobCaptureData.data()));
         entity.tick();
         if (entity instanceof AbstractFish fishEntity) {
            fishEntity.setNoGravity(true);
            fishEntity.setSwimming(true);
         }

         if (entity instanceof Sheep sheepEntity) {
            sheepEntity.setSheared(false);
            if (mobCaptureData.hasColor()) {
               sheepEntity.setColor(mobCaptureData.color().getDyeColor());
            }
         }

         if (entity instanceof PathfinderMob newPathfinderMob) {
            newPathfinderMob.setNoAi(true);
            newPathfinderMob.setSilent(true);
            newPathfinderMob.noPhysics = true;
         }

         entity.noPhysics = true;
         return entity;
      } else {
         log.error("Unable to create entity for Mob Farm Block Entity {}", mobFarmBlockEntity);
         return null;
      }
   }
}
