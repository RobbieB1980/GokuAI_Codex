package de.markusbordihn.easymobfarm.client.renderer.blockentity;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import de.markusbordihn.easymobfarm.block.MobFarmBlock;
import de.markusbordihn.easymobfarm.block.entity.MobFarmBlockEntity;
import de.markusbordihn.easymobfarm.client.renderer.manager.EntityScalingManager;
import de.markusbordihn.easymobfarm.client.renderer.manager.RendererManager;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureCardDefinition;
import de.markusbordihn.easymobfarm.data.capture.MobCaptureCardDefinitionManager;
import de.markusbordihn.easymobfarm.data.mobfarm.MobFarmType;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider.Context;
import net.minecraft.client.renderer.entity.EntityRenderDispatcher;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.feature.ModelFeatureRenderer;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.animal.bee.Bee;
import net.minecraft.world.entity.animal.fish.AbstractSchoolingFish;
import net.minecraft.world.entity.animal.happyghast.HappyGhast;
import net.minecraft.world.entity.animal.squid.Squid;
import net.minecraft.world.entity.boss.enderdragon.EnderDragon;
import net.minecraft.world.entity.monster.Ghast;
import net.minecraft.world.entity.monster.Guardian;
import net.minecraft.world.entity.monster.Phantom;
import net.minecraft.world.phys.Vec3;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class MobFarmBlockEntityRenderer<T extends MobFarmBlockEntity>
   implements BlockEntityRenderer<T, MobFarmBlockEntityRenderState> {
   private static final Logger log = LogManager.getLogger("Easy Mob Farm");

   public MobFarmBlockEntityRenderer(Context context) {
   }

   @Override
   public MobFarmBlockEntityRenderState createRenderState() {
      return new MobFarmBlockEntityRenderState();
   }

   @Override
   public void extractRenderState(
      T blockEntity,
      MobFarmBlockEntityRenderState state,
      float partialTicks,
      Vec3 cameraPos,
      ModelFeatureRenderer.CrumblingOverlay breakProgress
   ) {
      BlockEntityRenderStateBase.extract(blockEntity, state, breakProgress);
      state.farmType = blockEntity.getFarmType();
      state.facing = blockEntity.getBlockState().getValue(MobFarmBlock.FACING);
      if (!blockEntity.hasCapturedMob()) {
         RendererManager.removeEntity(blockEntity);
         state.entity = null;
      } else {
         state.entity = RendererManager.getOrCreateEntity(blockEntity);
      }
   }

   @Override
   public void submit(
      MobFarmBlockEntityRenderState state,
      PoseStack poseStack,
      SubmitNodeCollector buffer,
      CameraRenderState camera
   ) {
      Entity entity = state.entity;
      if (entity == null) {
         return;
      }

      try {
         if (entity instanceof LivingEntity livingEntity) {
            this.submitLivingEntity(state, livingEntity, poseStack, buffer, camera);
         } else {
            this.submitGenericEntity(state, entity, poseStack, buffer, camera);
         }
      } catch (Exception livingException) {
         try {
            this.submitGenericEntity(state, entity, poseStack, buffer, camera);
         } catch (Exception genericException) {
            log.error(
               "Failed to render entity {} for block entity {} with exception: {}",
               entity.getType(),
               state.blockPos,
               genericException.getMessage()
            );
         }
      }
   }

   private void submitLivingEntity(
      MobFarmBlockEntityRenderState state,
      LivingEntity entity,
      PoseStack poseStack,
      SubmitNodeCollector buffer,
      CameraRenderState camera
   ) {
      EntityRenderDispatcher dispatcher = Minecraft.getInstance().getEntityRenderDispatcher();
      EntityRenderState renderState = dispatcher.getRenderer(entity).createRenderState(entity, 0.0F);
      entity.tickCount = (int)(Minecraft.getInstance().level != null ? Minecraft.getInstance().level.getGameTime() : 0L);
      MobCaptureCardDefinition mobCaptureCardDefinition = MobCaptureCardDefinitionManager.get(entity.getType());
      if (mobCaptureCardDefinition != null && mobCaptureCardDefinition.requiresAnimationTick() && entity.tickCount % 2 == 0) {
         entity.tick();
      }

      poseStack.pushPose();
      this.prepareEntityPose(state, entity, poseStack);
      dispatcher.submit(renderState, camera, 0.0, 0.0, 0.0, poseStack, buffer);
      poseStack.popPose();
   }

   private void submitGenericEntity(
      MobFarmBlockEntityRenderState state,
      Entity entity,
      PoseStack poseStack,
      SubmitNodeCollector buffer,
      CameraRenderState camera
   ) {
      EntityRenderDispatcher dispatcher = Minecraft.getInstance().getEntityRenderDispatcher();
      EntityRenderState renderState = dispatcher.getRenderer(entity).createRenderState(entity, 0.0F);
      entity.tickCount = (int)(Minecraft.getInstance().level != null ? Minecraft.getInstance().level.getGameTime() : 0L);
      poseStack.pushPose();
      this.prepareEntityPose(state, entity, poseStack);
      dispatcher.submit(renderState, camera, 0.0, 0.0, 0.0, poseStack, buffer);
      poseStack.popPose();
   }

   private void prepareEntityPose(MobFarmBlockEntityRenderState state, Entity entity, PoseStack poseStack) {
      MobFarmType mobFarmType = state.farmType;
      if (mobFarmType == MobFarmType.LUCKY_DROP_FARM) {
         poseStack.translate(0.5, 0.19, 0.5);
      } else {
         poseStack.translate(0.5, 0.08, 0.5);
      }

      float entityScaling = EntityScalingManager.getEntityScale(entity);
      if (mobFarmType == MobFarmType.LUCKY_DROP_FARM) {
         entityScaling *= 0.75F;
      }

      poseStack.scale(entityScaling, entityScaling, entityScaling);

      float rotationDegrees = switch (state.facing != null ? state.facing : Direction.NORTH) {
         case NORTH -> 180.0F;
         case SOUTH -> 0.0F;
         case WEST -> -90.0F;
         case EAST -> 90.0F;
         default -> 0.0F;
      };
      poseStack.mulPose(Axis.YP.rotationDegrees(rotationDegrees));
      if (entity instanceof AbstractSchoolingFish) {
         poseStack.translate(-0.1, 0.5, 0.1);
         poseStack.mulPose(Axis.XP.rotationDegrees(2.0F));
         poseStack.mulPose(Axis.YP.rotationDegrees(15.0F));
         poseStack.mulPose(Axis.ZP.rotationDegrees(-90.0F));
      } else if (entity instanceof Bee) {
         poseStack.translate(0.0, 0.5, 0.0);
      } else if (entity instanceof Squid) {
         poseStack.translate(0.0, 1.3, 0.0);
      } else if (entity instanceof Phantom) {
         poseStack.translate(0.0, 0.5, 0.0);
      } else if (entity instanceof Ghast || entity instanceof HappyGhast || entity instanceof Guardian
         || (entity instanceof Bee bee && bee.isFlying())) {
         poseStack.translate(0.0, 0.3 / entityScaling, 0.0);
      } else if (entity instanceof EnderDragon) {
         poseStack.mulPose(Axis.XP.rotationDegrees(0.0F));
         poseStack.mulPose(Axis.YP.rotationDegrees(180.0F));
         poseStack.mulPose(Axis.ZP.rotationDegrees(0.0F));
      }
   }

   /** Local alias so extractBase stays readable without a long FQN at call sites. */
   private static final class BlockEntityRenderStateBase {
      private BlockEntityRenderStateBase() {
      }

      static void extract(
         MobFarmBlockEntity blockEntity,
         MobFarmBlockEntityRenderState state,
         ModelFeatureRenderer.CrumblingOverlay breakProgress
      ) {
         net.minecraft.client.renderer.blockentity.state.BlockEntityRenderState.extractBase(blockEntity, state, breakProgress);
      }
   }
}
