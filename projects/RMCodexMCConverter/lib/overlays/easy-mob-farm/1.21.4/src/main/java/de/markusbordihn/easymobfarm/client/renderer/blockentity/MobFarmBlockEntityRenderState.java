package de.markusbordihn.easymobfarm.client.renderer.blockentity;

import de.markusbordihn.easymobfarm.data.mobfarm.MobFarmType;
import net.minecraft.client.renderer.blockentity.state.BlockEntityRenderState;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.Entity;

public class MobFarmBlockEntityRenderState extends BlockEntityRenderState {
   public Entity entity;
   public MobFarmType farmType = MobFarmType.LUCKY_DROP_FARM;
   public Direction facing = Direction.NORTH;
}
