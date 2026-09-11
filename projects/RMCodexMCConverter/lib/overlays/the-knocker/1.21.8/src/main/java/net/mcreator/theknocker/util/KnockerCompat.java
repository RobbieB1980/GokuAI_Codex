package net.mcreator.theknocker.util;

import net.minecraft.commands.CommandSource;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.server.permissions.LevelBasedPermissionSet;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.Vec2;
import net.minecraft.world.phys.Vec3;
import org.jspecify.annotations.Nullable;

/**
 * Small 26.2 API helpers for MCreator-generated code.
 */
public final class KnockerCompat {
   private KnockerCompat() {}

   public static BlockPos playerSpawnPos(ServerPlayer player) {
      ServerPlayer.RespawnConfig config = player.getRespawnConfig();
      if (config != null && config.respawnData().dimension().equals(player.level().dimension())) {
         return config.respawnData().pos();
      }
      return player.level().getLevelData().getRespawnData().pos();
   }

   public static @Nullable MinecraftServer serverOf(Entity entity) {
      return entity.level().getServer();
   }

   public static void runAs(Entity entity, String command) {
      MinecraftServer server = serverOf(entity);
      if (entity.level().isClientSide() || server == null) {
         return;
      }
      ServerLevel level = entity.level() instanceof ServerLevel sl ? sl : null;
      if (level == null) {
         return;
      }
      server.getCommands()
         .performPrefixedCommand(
            new CommandSourceStack(
               CommandSource.NULL,
               entity.position(),
               entity.getRotationVector(),
               level,
               LevelBasedPermissionSet.OWNER,
               entity.getName().getString(),
               entity.getDisplayName(),
               server,
               entity
            ),
            command
         );
   }

   public static void runAs(ServerLevel level, double x, double y, double z, String command) {
      level.getServer()
         .getCommands()
         .performPrefixedCommand(
            new CommandSourceStack(
                  CommandSource.NULL,
                  new Vec3(x, y, z),
                  Vec2.ZERO,
                  level,
                  LevelBasedPermissionSet.OWNER,
                  "",
                  Component.literal(""),
                  level.getServer(),
                  null
               )
               .withSuppressedOutput(),
            command
         );
   }
}
